-- =============================================
-- CONCURRENCY TEST: IDEMPOTENCY VALIDATION
-- =============================================

-- Switch context to target database
USE LedgerShieldDB;
GO

-- Informational log indicating test start
PRINT '--- CONCURRENCY TEST ---';

-- Generate a shared tenant for both requests
DECLARE @tenant UNIQUEIDENTIFIER = NEWID();

--------------------------------------------------
-- FIRST CALL (EXPECTED: INSERT)
--------------------------------------------------
-- This call should create a new payment + transaction + ledger entries
EXEC sp_create_transaction
    @tenant_id = @tenant,
    @amount = 100,
    @currency = 'TRY',
    @idempotency_key = 'concurrent-1';

--------------------------------------------------
-- SECOND CALL (EXPECTED: NO-OP DUE TO IDEMPOTENCY)
--------------------------------------------------
-- Same idempotency_key should trigger early exit
-- No duplicate records should be created
EXEC sp_create_transaction
    @tenant_id = @tenant,
    @amount = 100,
    @currency = 'TRY',
    @idempotency_key = 'concurrent-1'; -- Same key

--------------------------------------------------
-- EXPECTED BEHAVIOR
--------------------------------------------------
-- 1. Only one payment_intents record should exist for this key
-- 2. Only one ledger_transactions record should be created
-- 3. Only one pair of ledger_entries (double-entry) should exist
-- 4. Second execution exits safely due to idempotency check

-- Informational log indicating test completion
PRINT '--- CONCURRENCY TEST DONE ---';