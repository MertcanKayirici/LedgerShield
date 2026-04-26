-- =============================================
-- V3 MIGRATION: PAYMENT AUDIT & STATUS TRACKING
-- =============================================

-- Informational log indicating migration start
PRINT 'Running V3__payment_audit';

-- Ensure migration is only applied once
IF NOT EXISTS (
    SELECT 1 FROM migration_history 
    WHERE script_name = 'V3__payment_audit.sql'
)
BEGIN
    BEGIN TRY
        -- Start atomic transaction for consistency
        BEGIN TRANSACTION;

        --------------------------------------------------
        -- 1. ADD updated_at COLUMN (IF NOT EXISTS)
        --------------------------------------------------
        -- Stores last update timestamp for each payment intent
        IF COL_LENGTH('payment_intents', 'updated_at') IS NULL
        BEGIN
            ALTER TABLE payment_intents
            ADD updated_at DATETIME2 NULL;
        END

        --------------------------------------------------
        -- 2. ADD completed_at COLUMN (IF NOT EXISTS)
        --------------------------------------------------
        -- Stores completion timestamp when payment is finalized
        IF COL_LENGTH('payment_intents', 'completed_at') IS NULL
        BEGIN
            ALTER TABLE payment_intents
            ADD completed_at DATETIME2 NULL;
        END

        --------------------------------------------------
        -- 3. CREATE AUDIT TABLE (IF NOT EXISTS)
        --------------------------------------------------
        -- Tracks status transitions for payment intents
        IF OBJECT_ID('payment_status_history', 'U') IS NULL
        BEGIN
            CREATE TABLE payment_status_history (
                id INT IDENTITY PRIMARY KEY, -- Surrogate primary key
                payment_intent_id UNIQUEIDENTIFIER, -- Reference to payment_intents
                old_status NVARCHAR(50), -- Previous status value
                new_status NVARCHAR(50), -- Updated status value
                changed_at DATETIME2 DEFAULT GETDATE() -- Timestamp of change
            );
        END

        --------------------------------------------------
        -- 4. CREATE TRIGGER FOR STATUS CHANGE AUDIT
        --------------------------------------------------
        -- Recreate trigger to ensure latest definition is applied
        IF OBJECT_ID('trg_payment_status_audit', 'TR') IS NOT NULL
            DROP TRIGGER trg_payment_status_audit;

        -- Dynamic SQL used to ensure proper batch execution for trigger creation
        EXEC('
        CREATE TRIGGER trg_payment_status_audit
        ON payment_intents
        AFTER UPDATE
        AS
        BEGIN
            SET NOCOUNT ON;

            -- Insert audit records only when status changes
            INSERT INTO payment_status_history (
                payment_intent_id,
                old_status,
                new_status
            )
            SELECT 
                d.payment_intent_id,
                d.status,
                i.status
            FROM deleted d
            JOIN inserted i 
                ON d.payment_intent_id = i.payment_intent_id
            WHERE d.status <> i.status;
        END
        ');

        --------------------------------------------------
        -- 5. RECORD MIGRATION HISTORY
        --------------------------------------------------
        -- Prevents re-running this migration
        INSERT INTO migration_history (script_name)
        VALUES ('V3__payment_audit.sql');

        -- Commit transaction after successful execution
        COMMIT;

        -- Success log
        PRINT 'V3 applied successfully';

    END TRY
    BEGIN CATCH
        -- Rollback transaction on failure
        ROLLBACK;

        -- Failure log
        PRINT 'V3 failed';

        -- Propagate error to caller
        THROW;
    END CATCH
END

-- Batch separator required by SQL Server
GO