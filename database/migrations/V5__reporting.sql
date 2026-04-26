-- =============================================
-- V5 MIGRATION: REPORTING VIEW (ACCOUNT BALANCE)
-- =============================================

-- Informational log indicating migration start
PRINT 'Running V5__reporting';

-- Ensure migration is executed only once
IF NOT EXISTS (
    SELECT 1 FROM migration_history 
    WHERE script_name = 'V5__reporting.sql'
)
BEGIN
    BEGIN TRY
        -- Start transaction for atomic operation
        BEGIN TRANSACTION;

        --------------------------------------------------
        -- ACCOUNT BALANCE VIEW
        --------------------------------------------------
        -- Recreate view to ensure latest definition is applied
        IF OBJECT_ID('vw_account_balance', 'V') IS NOT NULL
            DROP VIEW vw_account_balance;

        -- Dynamic SQL used to safely create the view within batch
        EXEC('
        CREATE VIEW vw_account_balance AS
        SELECT 
            account, -- Account identifier
            SUM(debit) AS total_debit, -- Total debits per account
            SUM(credit) AS total_credit, -- Total credits per account
            SUM(debit - credit) AS balance -- Net balance calculation
        FROM ledger_entries
        WHERE is_deleted = 0 -- Exclude soft-deleted records
        GROUP BY account
        ');

        --------------------------------------------------
        -- RECORD MIGRATION HISTORY
        --------------------------------------------------
        -- Logs execution to prevent duplicate application
        INSERT INTO migration_history (script_name)
        VALUES ('V5__reporting.sql');

        -- Commit transaction after successful execution
        COMMIT;

        -- Success log
        PRINT 'V5 applied';

    END TRY
    BEGIN CATCH
        -- Rollback all changes on failure
        ROLLBACK;

        -- Propagate error for upstream handling
        THROW;
    END CATCH
END

-- Batch separator required by SQL Server
GO