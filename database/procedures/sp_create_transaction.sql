-- =============================================
-- STORED PROCEDURE: CREATE TRANSACTION (IDEMPOTENT)
-- =============================================

-- Drop existing procedure to allow clean recreation
IF OBJECT_ID('sp_create_transaction', 'P') IS NOT NULL
    DROP PROCEDURE sp_create_transaction;
GO

-- Procedure handles full payment + ledger + outbox flow atomically
CREATE PROCEDURE sp_create_transaction
    @tenant_id UNIQUEIDENTIFIER,         -- Tenant scope identifier
    @amount DECIMAL(18,2),               -- Transaction amount
    @currency NVARCHAR(10),              -- Currency code (e.g., USD, EUR)
    @idempotency_key NVARCHAR(100)       -- Idempotency key for safe retries
AS
BEGIN
    -- Prevent extra result sets from interfering with clients
    SET NOCOUNT ON;

    -- Use strict isolation to prevent race conditions (idempotency + consistency)
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRY
        -- Begin atomic operation
        BEGIN TRANSACTION;

        --------------------------------------------------
        -- IDEMPOTENCY CHECK
        --------------------------------------------------
        -- Prevent duplicate transaction creation for the same request
        IF EXISTS (
            SELECT 1 FROM payment_intents
            WHERE idempotency_key = @idempotency_key
        )
        BEGIN
            -- Exit safely if already processed
            COMMIT;
            RETURN;
        END

        -- Generate identifiers for new records
        DECLARE @payment_id UNIQUEIDENTIFIER = NEWID();
        DECLARE @tx_id UNIQUEIDENTIFIER = NEWID();

        --------------------------------------------------
        -- PAYMENT INTENT CREATION
        --------------------------------------------------
        -- Initial record representing the payment lifecycle
        INSERT INTO payment_intents (
            payment_intent_id,
            tenant_id,
            amount,
            currency,
            status,
            version,
            idempotency_key,
            created_at
        )
        VALUES (
            @payment_id,
            @tenant_id,
            @amount,
            @currency,
            'PENDING',       -- Initial state
            1,               -- Version for optimistic concurrency
            @idempotency_key,
            GETDATE()        -- Creation timestamp
        );

        --------------------------------------------------
        -- LEDGER TRANSACTION CREATION
        --------------------------------------------------
        -- Logical grouping for double-entry accounting
        INSERT INTO ledger_transactions (
            transaction_id,
            payment_intent_id,
            tenant_id,
            created_at
        )
        VALUES (
            @tx_id,
            @payment_id,
            @tenant_id,
            GETDATE()
        );

        --------------------------------------------------
        -- LEDGER ENTRIES (DOUBLE-ENTRY ACCOUNTING)
        --------------------------------------------------
        -- Ensures accounting balance: debit = credit
        INSERT INTO ledger_entries (
            entry_id, transaction_id, account, debit, credit, created_at
        )
        VALUES 
        (NEWID(), @tx_id, 'CASH', @amount, 0, GETDATE()),   -- Debit entry
        (NEWID(), @tx_id, 'BANK', 0, @amount, GETDATE());   -- Credit entry

        --------------------------------------------------
        -- OUTBOX EVENT (EVENT-DRIVEN ARCHITECTURE)
        --------------------------------------------------
        -- Stores event for asynchronous processing (e.g., messaging system)
        INSERT INTO outbox (
            event_id,
            aggregate_id,
            event_type,
            payload,
            created_at,
            processed
        )
        VALUES (
            NEWID(),
            @payment_id,
            'PaymentCreated',
            CONCAT('Amount:', @amount), -- Simple payload representation
            GETDATE(),
            0                           -- Mark as not yet processed
        );

        -- Commit transaction after all operations succeed
        COMMIT;

    END TRY
    BEGIN CATCH
        -- Rollback entire transaction on failure
        ROLLBACK;

        -- Propagate error to caller
        THROW;
    END CATCH
END;
GO

--------------------------------------------------
-- SECURITY: PREVENT DIRECT INSERTS INTO LEDGER
--------------------------------------------------
-- Enforces usage of controlled procedures for ledger integrity
DENY INSERT ON ledger_entries TO PUBLIC;
GO