-- =============================================
-- BALANCE CONSISTENCY TEST: DATA VALIDATION
-- =============================================

-- Switch context to target database
USE LedgerShieldDB;
GO

-- Informational log indicating test start
PRINT '--- BALANCE CONSISTENCY TEST ---';

--------------------------------------------------
-- RAW CALCULATION (SOURCE OF TRUTH)
--------------------------------------------------
-- Aggregates balance directly from ledger_entries
-- This represents the baseline calculation
SELECT account, SUM(debit - credit) AS balance
INTO #raw
FROM dbo.ledger_entries
WHERE is_deleted = 0
GROUP BY account;

--------------------------------------------------
-- INDEXED VIEW RESULT
--------------------------------------------------
-- Retrieves pre-aggregated balances from indexed view
-- NOEXPAND hint forces usage of the indexed view instead of recalculation
SELECT account, balance
INTO #view
FROM dbo.vw_account_balance WITH (NOEXPAND);

--------------------------------------------------
-- TRIGGER-MAINTAINED TABLE RESULT
--------------------------------------------------
-- Retrieves balances maintained via trigger-based updates
SELECT account, balance
INTO #table
FROM dbo.account_balance;

--------------------------------------------------
-- COMPARISON: RAW vs INDEXED VIEW
--------------------------------------------------
-- Detects inconsistencies between raw calculation and indexed view
PRINT 'Comparing RAW vs VIEW...';

SELECT *
FROM #raw r
FULL OUTER JOIN #view v ON r.account = v.account
WHERE ISNULL(r.balance,0) <> ISNULL(v.balance,0);

--------------------------------------------------
-- COMPARISON: RAW vs TRIGGER TABLE
--------------------------------------------------
-- Detects inconsistencies between raw calculation and trigger-maintained table
PRINT 'Comparing RAW vs TABLE...';

SELECT *
FROM #raw r
FULL OUTER JOIN #table t ON r.account = t.account
WHERE ISNULL(r.balance,0) <> ISNULL(t.balance,0);

--------------------------------------------------
-- CLEANUP TEMP TABLES
--------------------------------------------------
-- Remove temporary tables to free resources
DROP TABLE #raw;
DROP TABLE #view;
DROP TABLE #table;

-- Informational log indicating test completion
PRINT '--- BALANCE CONSISTENCY TEST DONE ---';