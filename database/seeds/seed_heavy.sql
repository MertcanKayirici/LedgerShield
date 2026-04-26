-- =============================================
-- HEAVY DATA SEED SCRIPT: LARGE SCALE LOAD TEST
-- =============================================

-- Switch context to target database
USE LedgerShieldDB;
GO

-- Informational log indicating heavy seed start
PRINT '--- HEAVY SEED START ---';

-- Suppress row count messages for cleaner output
SET NOCOUNT ON;

BEGIN TRY
    -- Begin transaction to ensure atomic execution
    BEGIN TRAN;

    --------------------------------------------------
    -- MAIN TENANT (HIGH VOLUME: 10,000 RECORDS)
    --------------------------------------------------
    -- Simulates production-scale load for a single tenant
    DECLARE @tenant UNIQUEIDENTIFIER = NEWID();
    DECLARE @i INT = 1;

    WHILE @i <= 10000
    BEGIN
        -- Generate pseudo-random amount between 10 and 1000
        DECLARE @amount DECIMAL(18,2) =
            (ABS(CHECKSUM(NEWID())) % 990) + 10;

        -- Randomly assign currency (TRY, USD, EUR)
        DECLARE @currency NVARCHAR(10);
        DECLARE @rand INT = ABS(CHECKSUM(NEWID())) % 3;

        IF @rand = 0 SET @currency = 'TRY';
        ELSE IF @rand = 1 SET @currency = 'USD';
        ELSE SET @currency = 'EUR';

        -- Generate unique idempotency key for each transaction
        DECLARE @key NVARCHAR(100) =
            'heavy-' + CAST(@i AS NVARCHAR(10)) + '-' +
            CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));

        -- Execute transaction creation via stored procedure
        EXEC dbo.sp_create_transaction
            @tenant_id = @tenant,
            @amount = @amount,
            @currency = @currency,
            @idempotency_key = @key;

        SET @i += 1;
    END

    -- Log completion of main tenant load
    PRINT '✔ 10K main tenant inserted';

    --------------------------------------------------
    -- SECOND TENANT (MULTI-TENANT SCENARIO)
    --------------------------------------------------
    -- Simulates additional tenant with moderate load
    DECLARE @tenant2 UNIQUEIDENTIFIER = NEWID();
    SET @i = 1;

    WHILE @i <= 500
    BEGIN
        -- Generate pseudo-random amount between 50 and 550
        DECLARE @amount2 DECIMAL(18,2) =
            (ABS(CHECKSUM(NEWID())) % 500) + 50;

        -- Deterministic idempotency key for second tenant
        DECLARE @key2 NVARCHAR(100) =
            'tenant2-' + CAST(@i AS NVARCHAR(10));

        -- Execute transaction creation
        EXEC dbo.sp_create_transaction
            @tenant_id = @tenant2,
            @amount = @amount2,
            @currency = 'TRY',
            @idempotency_key = @key2;

        SET @i += 1;
    END

    -- Log completion of multi-tenant load
    PRINT '✔ multi-tenant data inserted';

    --------------------------------------------------
    -- AUDIT TEST (TRIGGER VALIDATION)
    --------------------------------------------------
    -- Updates a subset of records to trigger audit logging mechanism
    UPDATE TOP (200) dbo.payment_intents
    SET status = 'COMPLETED'
    WHERE status = 'PENDING';

    -- Log audit test completion
    PRINT '✔ audit update done';

    -- Commit all operations after successful execution
    COMMIT;

    -- Final success log
    PRINT '--- HEAVY SEED DONE ---';

END TRY
BEGIN CATCH
    -- Rollback all changes in case of failure
    ROLLBACK;

    -- Log error message for debugging
    PRINT '❌ ERROR: ' + ERROR_MESSAGE();

    -- Propagate error to caller
    THROW;
END CATCH;