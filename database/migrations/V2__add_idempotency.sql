-- =============================================
-- V2 MIGRATION: ADD IDEMPOTENCY SUPPORT
-- =============================================

-- Informational log indicating migration start
PRINT 'Running V2__add_idempotency';

-- Ensure migration is only applied once
IF NOT EXISTS (
    SELECT 1 FROM migration_history 
    WHERE script_name = 'V2__add_idempotency.sql'
)
BEGIN
    BEGIN TRY
        -- Start atomic transaction for safe migration
        BEGIN TRANSACTION;

        --------------------------------------------------
        -- ADD COLUMN (IF NOT EXISTS)
        --------------------------------------------------
        -- Adds idempotency_key column to support idempotent operations
        IF COL_LENGTH('payment_intents', 'idempotency_key') IS NULL
        BEGIN
            ALTER TABLE payment_intents
            ADD idempotency_key NVARCHAR(100) NULL;
        END

        --------------------------------------------------
        -- BACKFILL NULL VALUES
        --------------------------------------------------
        -- Populate existing rows with unique values to satisfy NOT NULL constraint
        UPDATE payment_intents
        SET idempotency_key = CAST(NEWID() AS NVARCHAR(100))
        WHERE idempotency_key IS NULL;

        --------------------------------------------------
        -- ENFORCE NOT NULL CONSTRAINT
        --------------------------------------------------
        -- Ensures column is non-nullable after backfill
        IF EXISTS (
            SELECT 1 FROM sys.columns 
            WHERE Name = 'idempotency_key' 
            AND Object_ID = Object_ID('payment_intents')
            AND is_nullable = 1
        )
        BEGIN
            ALTER TABLE payment_intents
            ALTER COLUMN idempotency_key NVARCHAR(100) NOT NULL;
        END

        --------------------------------------------------
        -- ADD UNIQUE CONSTRAINT (IF NOT EXISTS)
        --------------------------------------------------
        -- Guarantees uniqueness for idempotency enforcement
        IF NOT EXISTS (
            SELECT 1 FROM sys.indexes 
            WHERE name = 'uq_payment_idempotency'
        )
        BEGIN
            ALTER TABLE payment_intents
            ADD CONSTRAINT uq_payment_idempotency 
            UNIQUE (idempotency_key);
        END

        --------------------------------------------------
        -- RECORD MIGRATION HISTORY
        --------------------------------------------------
        -- Insert migration record to prevent re-execution
        INSERT INTO migration_history (script_name)
        VALUES ('V2__add_idempotency.sql');

        -- Commit transaction if all steps succeed
        COMMIT;

        -- Success log
        PRINT 'V2 applied successfully';

    END TRY
    BEGIN CATCH
        -- Rollback transaction on any failure
        ROLLBACK;

        -- Failure log
        PRINT 'V2 failed';

        -- Re-throw error for upstream handling
        THROW;
    END CATCH
END

-- Batch separator for SQL Server execution context
GO