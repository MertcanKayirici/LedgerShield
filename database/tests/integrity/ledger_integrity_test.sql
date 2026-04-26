-- =============================================
-- LEDGER INTEGRITY TEST: DOUBLE-ENTRY VALIDATION
-- =============================================

-- Switch context to target database
USE LedgerShieldDB;
GO

-- Informational log indicating test start
PRINT '--- LEDGER INTEGRITY TEST ---';

--------------------------------------------------
-- DOUBLE-ENTRY CONSISTENCY CHECK
--------------------------------------------------
-- Verifies that for each transaction:
-- total debit must equal total credit
-- Any result returned indicates a data integrity violation
SELECT 
    transaction_id,                     -- Transaction identifier
    SUM(debit) AS total_debit,         -- Total debit amount per transaction
    SUM(credit) AS total_credit        -- Total credit amount per transaction
FROM ledger_entries
GROUP BY transaction_id
HAVING SUM(debit) <> SUM(credit);      -- Filter only inconsistent transactions

--------------------------------------------------
-- EXPECTED RESULT
--------------------------------------------------
-- No rows should be returned if ledger is consistent
-- Any returned row indicates imbalance and must be investigated

-- Informational log indicating test completion
PRINT '--- LEDGER INTEGRITY TEST DONE ---';