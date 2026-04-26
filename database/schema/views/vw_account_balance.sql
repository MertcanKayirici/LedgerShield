-- =============================================
-- INDEXED VIEW CREATION: ACCOUNT BALANCE (MATERIALIZED AGGREGATION)
-- =============================================

-- Informational log indicating indexed view creation start
PRINT 'Creating Indexed View: vw_account_balance';

--------------------------------------------------
-- REQUIRED SESSION SETTINGS
--------------------------------------------------
-- Required for indexed views to ensure deterministic behavior
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

--------------------------------------------------
-- DROP VIEW (IF EXISTS)
--------------------------------------------------
-- Ensures clean recreation of the view
IF OBJECT_ID('dbo.vw_account_balance', 'V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_account_balance;
END
GO

--------------------------------------------------
-- CREATE VIEW WITH SCHEMABINDING
--------------------------------------------------
-- SCHEMABINDING prevents underlying table changes that would break the view
-- Required for indexed (materialized) views
CREATE VIEW dbo.vw_account_balance
WITH SCHEMABINDING
AS
SELECT
    account, -- Grouping key
    SUM(CONVERT(DECIMAL(18,2), debit - credit)) AS balance, -- Net balance aggregation
    COUNT_BIG(*) AS record_count -- Required for indexed view (COUNT_BIG instead of COUNT)
FROM dbo.ledger_entries
WHERE is_deleted = 0 -- Exclude soft-deleted records
GROUP BY account;
GO

--------------------------------------------------
-- DROP EXISTING INDEX (IF EXISTS)
--------------------------------------------------
-- Ensures index can be recreated safely
IF EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_vw_account_balance'
)
BEGIN
    DROP INDEX IX_vw_account_balance ON dbo.vw_account_balance;
END
GO

--------------------------------------------------
-- CREATE UNIQUE CLUSTERED INDEX
--------------------------------------------------
-- Materializes the view and enforces one row per account
-- Enables fast aggregation queries on account balances
CREATE UNIQUE CLUSTERED INDEX IX_vw_account_balance
ON dbo.vw_account_balance(account);
GO

-- Informational log indicating successful creation
PRINT 'Indexed View created successfully';