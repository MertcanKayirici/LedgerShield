-- =============================================
-- DATA SEED SCRIPT: SAMPLE TRANSACTIONS & AUDIT TEST
-- =============================================

-- Informational log indicating seed process start
PRINT '--- SEED START ---';

-- Suppress row count messages for cleaner output
SET NOCOUNT ON;

BEGIN TRY
    -- Begin transaction to ensure atomic seeding
    BEGIN TRAN;

    --------------------------------------------------
    -- MAIN TENANT DATA GENERATION
    --------------------------------------------------
    -- Create a primary tenant and generate high-volume transactions
    DECLARE @tenant UNIQUEIDENTIFIER = NEWID();
    DECLARE @i INT = 1;

    WHILE @i <= 10000
    BEGIN
        --------------------------------------------------
        -- RANDOM AMOUNT GENERATION (10 - 1000)
        --------------------------------------------------
        -- Generates pseudo-random amount using NEWID checksum
        DECLARE @amount DECIMAL(18,2) = 
            (ABS(CHECKSUM(NEWID())) % 990) + 10;

        --------------------------------------------------
        -- RANDOM CURRENCY SELECTION
        --------------------------------------------------
        -- Distributes transactions across TRY, USD, EUR
        DECLARE @currency NVARCHAR(10);

        DECLARE @rand INT = ABS(CHECKSUM(NEWID())) % 3;

        IF @rand = 0 SET @currency = 'TRY';
        ELSE IF @rand = 1 SET @currency = 'USD';
        ELSE SET @currency = 'EUR';

        --------------------------------------------------
        -- UNIQUE IDEMPOTENCY KEY
        --------------------------------------------------
        -- Ensures each transaction is uniquely identifiable
        DECLARE @key NVARCHAR(100) =
            CONCAT('seed-', @i, '-', ABS(CHECKSUM(NEWID())));

        --------------------------------------------------
        -- EXECUTE TRANSACTION CREATION
        --------------------------------------------------
        -- Uses stored procedure to enforce business rules and consistency
        EXEC sp_create_transaction
            @tenant_id = @tenant,
            @amount = @amount,
            @currency = @currency,
            @idempotency_key = @key;

        SET @i += 1;
    END

    -- Log completion of main tenant seeding
    PRINT '✔ 10K main tenant inserted';

    --------------------------------------------------
    -- SECOND TENANT (MULTI-TENANT SCENARIO)
    --------------------------------------------------
    -- Simulates a smaller tenant dataset
    DECLARE @tenant2 UNIQUEIDENTIFIER = NEWID();
    SET @i = 1;

    WHILE @i <= 200
    BEGIN
        -- Generate random amount (50 - 550)
        DECLARE @amount2 DECIMAL(18,2) =
            (ABS(CHECKSUM(NEWID())) % 500) + 50;

        -- Simpler deterministic idempotency key
        DECLARE @key2 NVARCHAR(100) =
            CONCAT('tenant2-', @i);

        -- Execute transaction creation
        EXEC sp_create_transaction
            @tenant_id = @tenant2,
            @amount = @amount2,
            @currency = 'TRY',
            @idempotency_key = @key2;

        SET @i += 1;
    END

    -- Log completion of multi-tenant data
    PRINT '✔ multi-tenant data inserted';

    --------------------------------------------------
    -- STATUS UPDATE (AUDIT TRIGGER TEST)
    --------------------------------------------------
    -- Updates subset of records to trigger audit logging
    UPDATE TOP (100) payment_intents
    SET status = 'COMPLETED'
    WHERE status = 'PENDING';

    -- Log audit trigger test completion
    PRINT '✔ audit update done';

    -- Commit all seeded data
    COMMIT;

    -- Final success log
    PRINT '--- SEED COMPLETED SUCCESSFULLY ---';

END TRY
BEGIN CATCH
    -- Rollback all changes in case of failure
    ROLLBACK;

    -- Capture and print error message
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT '❌ ERROR: ' + @msg;

    -- Re-throw error for upstream handling
    THROW;
END CATCH;