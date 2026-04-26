-- =============================================
-- LOAD TEST: TRANSACTION THROUGHPUT VALIDATION
-- =============================================

-- Switch context to target database
USE LedgerShieldDB;
GO

-- Informational log indicating load test start
PRINT '--- LOAD TEST ---';

--------------------------------------------------
-- LOAD GENERATION LOOP (1000 TRANSACTIONS)
--------------------------------------------------
-- Simulates repeated transaction creation under moderate load
DECLARE @i INT = 1;
DECLARE @tenant UNIQUEIDENTIFIER = NEWID(); -- Single tenant scope for test

WHILE @i <= 1000
BEGIN
    --------------------------------------------------
    -- UNIQUE IDEMPOTENCY KEY PER ITERATION
    --------------------------------------------------
    -- Ensures each request is treated as a new transaction
    DECLARE @key NVARCHAR(50) = 
        'load-' + CAST(@i AS NVARCHAR(10));

    --------------------------------------------------
    -- EXECUTE TRANSACTION CREATION
    --------------------------------------------------
    -- Calls core procedure to generate payment + ledger + outbox
    EXEC dbo.sp_create_transaction
        @tenant_id = @tenant,
        @amount = 50,
        @currency = 'TRY',
        @idempotency_key = @key;

    SET @i += 1;
END

--------------------------------------------------
-- EXPECTED RESULTS
--------------------------------------------------
-- 1. 1000 payment_intents records created
-- 2. 1000 ledger_transactions records created
-- 3. 2000 ledger_entries records (double-entry per transaction)
-- 4. 1000 outbox events generated
-- 5. No duplicate key violations (unique idempotency keys)

-- Informational log indicating load test completion
PRINT '--- LOAD TEST DONE ---';