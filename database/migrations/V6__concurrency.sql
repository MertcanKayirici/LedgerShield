-- =============================================
-- V6 MIGRATION: CONCURRENCY CONTROL (ROWVERSION)
-- =============================================

-- Informational log indicating migration start
PRINT 'Running V6__concurrency';

-- Ensure migration is executed only once
IF NOT EXISTS (
    SELECT 1 FROM migration_history 
    WHERE script_name = 'V6__concurrency.sql'
)
BEGIN
    BEGIN TRY
        -- Start transaction to ensure atomic schema change
        BEGIN TRANSACTION;

        --------------------------------------------------
        -- ADD ROWVERSION COLUMN (IF NOT EXISTS)
        --------------------------------------------------
        -- Enables optimistic concurrency control on payment_intents
        -- Automatically updated by SQL Server on each row modification
        IF COL_LENGTH('payment_intents', 'row_version') IS NULL
        BEGIN
            ALTER TABLE payment_intents
            ADD row_version ROWVERSION;
        END

        --------------------------------------------------
        -- RECORD MIGRATION HISTORY
        --------------------------------------------------
        -- Prevents re-execution of this migration
        INSERT INTO migration_history (script_name)
        VALUES ('V6__concurrency.sql');

        -- Commit transaction after successful execution
        COMMIT;

        -- Success log
        PRINT 'V6 applied';

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