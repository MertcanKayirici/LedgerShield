-- =============================================
-- V4 MIGRATION: SOFT DELETE SUPPORT
-- =============================================

-- Informational log indicating migration start
PRINT 'Running V4__soft_delete';

-- Ensure migration is executed only once
IF NOT EXISTS (
    SELECT 1 FROM migration_history 
    WHERE script_name = 'V4__soft_delete.sql'
)
BEGIN
    BEGIN TRY
        -- Start transaction to ensure atomicity
        BEGIN TRANSACTION;

        --------------------------------------------------
        -- payment_intents TABLE
        --------------------------------------------------
        -- Adds soft delete flag to logically remove records without physical deletion
        IF COL_LENGTH('payment_intents', 'is_deleted') IS NULL
        BEGIN
            ALTER TABLE payment_intents
            ADD is_deleted BIT NOT NULL DEFAULT 0;
        END

        --------------------------------------------------
        -- ledger_transactions TABLE
        --------------------------------------------------
        -- Enables soft delete for transaction records
        IF COL_LENGTH('ledger_transactions', 'is_deleted') IS NULL
        BEGIN
            ALTER TABLE ledger_transactions
            ADD is_deleted BIT NOT NULL DEFAULT 0;
        END

        --------------------------------------------------
        -- ledger_entries TABLE
        --------------------------------------------------
        -- Typically immutable, but soft delete is added for consistency and flexibility
        IF COL_LENGTH('ledger_entries', 'is_deleted') IS NULL
        BEGIN
            ALTER TABLE ledger_entries
            ADD is_deleted BIT NOT NULL DEFAULT 0;
        END

        --------------------------------------------------
        -- RECORD MIGRATION HISTORY
        --------------------------------------------------
        -- Logs successful execution to prevent duplicate runs
        INSERT INTO migration_history (script_name)
        VALUES ('V4__soft_delete.sql');

        -- Commit transaction upon success
        COMMIT;

        -- Success log
        PRINT 'V4 applied';

    END TRY
    BEGIN CATCH
        -- Rollback all changes in case of failure
        ROLLBACK;

        -- Propagate error for upstream handling
        THROW;
    END CATCH
END

-- Batch separator for SQL Server
GO