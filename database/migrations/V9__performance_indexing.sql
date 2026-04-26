-- =============================================
-- V9 MIGRATION: INDEX TUNING & PERFORMANCE
-- =============================================

-- Informational log indicating migration start
PRINT 'Running V9__index_tuning';

-- Ensure migration is executed only once
IF NOT EXISTS (
    SELECT 1 FROM migration_history 
    WHERE script_name = 'V9__index_tuning.sql'
)
BEGIN
    BEGIN TRY
        -- Start transaction for atomic index operations
        BEGIN TRANSACTION;

        --------------------------------------------------
        -- COMPOSITE INDEX ON ledger_entries
        --------------------------------------------------
        -- Optimizes queries filtering by account and date,
        -- while covering debit and credit columns to reduce lookups
        IF NOT EXISTS (
            SELECT * FROM sys.indexes 
            WHERE name = 'idx_ledger_account_date'
        )
        BEGIN
            CREATE INDEX idx_ledger_account_date
            ON ledger_entries(account, created_at)
            INCLUDE (debit, credit);
        END

        --------------------------------------------------
        -- INDEX ON payment_intents.status
        --------------------------------------------------
        -- Improves performance for status-based filtering and queries
        IF NOT EXISTS (
            SELECT * FROM sys.indexes 
            WHERE name = 'idx_payment_status'
        )
        BEGIN
            CREATE INDEX idx_payment_status
            ON payment_intents(status);
        END

        --------------------------------------------------
        -- RECORD MIGRATION HISTORY
        --------------------------------------------------
        -- Logs execution to prevent duplicate application
        INSERT INTO migration_history (script_name)
        VALUES ('V9__index_tuning.sql');

        -- Commit transaction after successful execution
        COMMIT;

        -- Success log
        PRINT 'V9 applied';

    END TRY
    BEGIN CATCH
        -- Rollback all changes on failure
        ROLLBACK;

        -- Propagate error for upstream handling
        THROW;
    END CATCH
END

-- Batch separator for SQL Server execution context
GO