-- =============================================
-- V7 MIGRATION: ROLLBACK EXAMPLE (V5 REPORTING)
-- =============================================

-- Informational log indicating rollback script execution
PRINT 'Running V7__rollback_example';

-- Note: This is not a full rollback mechanism, only a demonstration of approach

-- Check if the target migration (V5) has been applied
IF EXISTS (
    SELECT 1 FROM migration_history 
    WHERE script_name = 'V5__reporting.sql'
)
BEGIN
    BEGIN TRY
        -- Start transaction to ensure atomic rollback behavior
        BEGIN TRANSACTION;

        --------------------------------------------------
        -- DROP VIEW (IF EXISTS)
        --------------------------------------------------
        -- Removes reporting view created in V5 migration
        IF OBJECT_ID('vw_account_balance', 'V') IS NOT NULL
            DROP VIEW vw_account_balance;

        --------------------------------------------------
        -- REMOVE MIGRATION HISTORY RECORD
        --------------------------------------------------
        -- Deletes V5 entry to allow re-application if needed
        DELETE FROM migration_history
        WHERE script_name = 'V5__reporting.sql';

        -- Commit transaction after successful rollback steps
        COMMIT;

        -- Success log
        PRINT 'Rollback V5 completed';

    END TRY
    BEGIN CATCH
        -- Rollback transaction on failure
        ROLLBACK;

        -- Propagate error for upstream handling
        THROW;
    END CATCH
END

-- Batch separator for SQL Server execution context
GO