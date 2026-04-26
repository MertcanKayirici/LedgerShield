-- =============================================
-- TABLE CREATION: LEDGER TRANSACTIONS
-- =============================================

-- Create table only if it does not already exist
IF OBJECT_ID('ledger_transactions', 'U') IS NULL
BEGIN
    CREATE TABLE ledger_transactions (
        transaction_id UNIQUEIDENTIFIER PRIMARY KEY, -- Unique identifier for each transaction

        payment_intent_id UNIQUEIDENTIFIER NOT NULL, -- Reference to associated payment intent

        tenant_id UNIQUEIDENTIFIER NOT NULL, -- Tenant scope identifier (multi-tenant support)

        created_at DATETIME2 NOT NULL DEFAULT GETDATE(), -- Timestamp of transaction creation

        --------------------------------------------------
        -- FOREIGN KEY CONSTRAINT (payment_intents)
        --------------------------------------------------
        -- Ensures transaction is linked to a valid payment intent
        -- NO ACTION prevents cascading deletes/updates for data integrity
        CONSTRAINT fk_ledger_tx_payment
        FOREIGN KEY (payment_intent_id)
        REFERENCES payment_intents(payment_intent_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
    );

    --------------------------------------------------
    -- INDEXES (PERFORMANCE OPTIMIZATION)
    --------------------------------------------------

    -- Optimizes queries filtering/joining by payment_intent_id
    CREATE INDEX idx_tx_payment_intent
    ON ledger_transactions(payment_intent_id);

    -- Optimizes queries filtering by tenant_id
    CREATE INDEX idx_tx_tenant
    ON ledger_transactions(tenant_id);

END
GO