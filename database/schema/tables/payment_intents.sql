-- =============================================
-- TABLE CREATION: PAYMENT INTENTS
-- =============================================

-- Create table only if it does not already exist
IF OBJECT_ID('payment_intents', 'U') IS NULL
BEGIN
    CREATE TABLE payment_intents (
        payment_intent_id UNIQUEIDENTIFIER PRIMARY KEY, -- Unique identifier for each payment intent

        tenant_id UNIQUEIDENTIFIER NOT NULL, -- Tenant scope identifier (multi-tenant support)

        amount DECIMAL(18,2) NOT NULL
            CONSTRAINT chk_payment_amount CHECK (amount > 0), -- Ensures amount is always positive

        currency NVARCHAR(10) NOT NULL, -- Currency code (e.g., USD, EUR)

        status NVARCHAR(50) NOT NULL
            CONSTRAINT chk_payment_status 
            CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED')), -- Restricts valid lifecycle states

        version INT NOT NULL DEFAULT 1, -- Version field for optimistic concurrency control

        idempotency_key NVARCHAR(100) NOT NULL, -- Unique key for idempotent request handling

        created_at DATETIME2 NOT NULL DEFAULT GETDATE() -- Timestamp of creation
    );

    --------------------------------------------------
    -- UNIQUE CONSTRAINT (IDEMPOTENCY)
    --------------------------------------------------
    -- Ensures each idempotency_key is unique across all payment intents
    ALTER TABLE payment_intents
    ADD CONSTRAINT uq_payment_idempotency UNIQUE (idempotency_key);

    --------------------------------------------------
    -- INDEXES (PERFORMANCE OPTIMIZATION)
    --------------------------------------------------

    -- Optimizes queries filtering by tenant_id
    CREATE INDEX idx_payment_tenant 
    ON payment_intents(tenant_id);

END
GO