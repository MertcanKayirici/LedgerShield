-- =============================================
-- IDEMPOTENCY TEST: DUPLICATE REQUEST HANDLING
-- =============================================

-- Switch context to target database
USE LedgerShieldDB;
GO

-- Informational log indicating test start
PRINT '--- IDEMPOTENCY TEST ---';

-- Generate a tenant for this test scenario
DECLARE @tenant UNIQUEIDENTIFIER = NEWID();

--------------------------------------------------
-- FIRST EXECUTION (EXPECTED: INSERT)
--------------------------------------------------
-- Should create payment, transaction, ledger entries, and outbox event
EXEC sp_create_transaction
    @tenant_id = @tenant,
    @amount = 300,
    @currency = 'TRY',
    @idempotency_key = 'idem-test';

--------------------------------------------------
-- SECOND EXECUTION (EXPECTED: NO-OP)
--------------------------------------------------
-- Same idempotency_key should prevent duplicate processing
-- Procedure should exit early without inserting new records
EXEC sp_create_transaction
    @tenant_id = @tenant,
    @amount = 300,
    @currency = 'TRY',
    @idempotency_key = 'idem-test';

--------------------------------------------------
-- EXPECTED RESULTS
--------------------------------------------------
-- 1. Only one row in payment_intents with idempotency_key = 'idem-test'
-- 2. Only one related ledger_transactions record
-- 3. Only one pair of ledger_entries (double-entry)
-- 4. Only one outbox event generated
-- 5. Second call safely ignored due to idempotency check

-- Optional verification queries (manual inspection):
-- SELECT * FROM payment_intents WHERE idempotency_key = 'idem-test';
-- SELECT * FROM ledger_transactions WHERE payment_intent_id IN (...);
-- SELECT * FROM ledger_entries WHERE transaction_id IN (...);

-- Informational log indicating test completion
PRINT '--- IDEMPOTENCY TEST DONE ---';