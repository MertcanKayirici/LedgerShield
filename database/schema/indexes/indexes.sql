-- =============================================
-- INDEX SETUP: PERFORMANCE OPTIMIZATION
-- =============================================

-- Informational log indicating index setup start
PRINT '--- INDEX SETUP START ---';

-- Suppress row count messages to reduce noise
SET NOCOUNT ON;

--------------------------------------------------
-- PAYMENT_INTENTS TABLE INDEXES
--------------------------------------------------

-- Index on tenant_id for multi-tenant query filtering
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'idx_payment_tenant'
      AND object_id = OBJECT_ID(N'dbo.payment_intents')
)
    CREATE INDEX idx_payment_tenant
    ON dbo.payment_intents(tenant_id);
GO

-- Unique index on idempotency_key to enforce request uniqueness
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'idx_payment_idempotency'
      AND object_id = OBJECT_ID(N'dbo.payment_intents')
)
    CREATE UNIQUE INDEX idx_payment_idempotency
    ON dbo.payment_intents(idempotency_key);
GO

--------------------------------------------------
-- LEDGER_TRANSACTIONS TABLE INDEXES
--------------------------------------------------

-- Index to optimize joins and lookups by payment_intent_id
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'idx_tx_payment_intent'
      AND object_id = OBJECT_ID(N'dbo.ledger_transactions')
)
    CREATE INDEX idx_tx_payment_intent
    ON dbo.ledger_transactions(payment_intent_id);
GO

--------------------------------------------------
-- LEDGER_ENTRIES TABLE INDEXES (LOOKUP)
--------------------------------------------------

-- Index to speed up transaction-based lookups
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'idx_entry_transaction'
      AND object_id = OBJECT_ID(N'dbo.ledger_entries')
)
    CREATE INDEX idx_entry_transaction
    ON dbo.ledger_entries(transaction_id);
GO

--------------------------------------------------
-- LEDGER_ENTRIES TABLE INDEXES (AGGREGATION PERFORMANCE)
--------------------------------------------------
-- Optimized for queries like:
-- SELECT ... WHERE is_deleted = 0 GROUP BY account
-- Covers debit and credit to avoid key lookups
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'idx_ledger_perf'
      AND object_id = OBJECT_ID(N'dbo.ledger_entries')
)
    CREATE INDEX idx_ledger_perf
    ON dbo.ledger_entries(is_deleted, account)
    INCLUDE (debit, credit);
GO

--------------------------------------------------
-- OUTBOX TABLE INDEXES
--------------------------------------------------

-- Index to efficiently fetch unprocessed events
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'idx_outbox_processed'
      AND object_id = OBJECT_ID(N'dbo.outbox')
)
    CREATE INDEX idx_outbox_processed
    ON dbo.outbox(processed);
GO

-- Informational log indicating index setup completion
PRINT '--- INDEX SETUP END ---';