-- =============================================
-- V8 MIGRATION: TABLE PARTITIONING SETUP (BY YEAR)
-- =============================================

-- Informational log indicating migration start
PRINT 'Running V8__partitioning';

-- Ensure migration is executed only once
IF NOT EXISTS (
    SELECT 1 FROM migration_history 
    WHERE script_name = 'V8__partitioning.sql'
)
BEGIN
    BEGIN TRY
        -- Start transaction for atomic schema changes
        BEGIN TRANSACTION;

        --------------------------------------------------
        -- CREATE PARTITION FUNCTION (IF NOT EXISTS)
        --------------------------------------------------
        -- Defines boundary values to split data by year based on DATETIME2 column
        IF NOT EXISTS (
            SELECT * FROM sys.partition_functions 
            WHERE name = 'pf_ledger_by_year'
        )
        BEGIN
            CREATE PARTITION FUNCTION pf_ledger_by_year (DATETIME2)
            AS RANGE RIGHT FOR VALUES 
            ('2023-01-01', '2024-01-01', '2025-01-01');
        END

        --------------------------------------------------
        -- CREATE PARTITION SCHEME (IF NOT EXISTS)
        --------------------------------------------------
        -- Maps partitions to filegroups (currently all mapped to PRIMARY)
        IF NOT EXISTS (
            SELECT * FROM sys.partition_schemes 
            WHERE name = 'ps_ledger_by_year'
        )
        BEGIN
            CREATE PARTITION SCHEME ps_ledger_by_year
            AS PARTITION pf_ledger_by_year
            ALL TO ([PRIMARY]);
        END

        --------------------------------------------------
        -- RECORD MIGRATION HISTORY
        --------------------------------------------------
        -- Logs execution to prevent duplicate application
        INSERT INTO migration_history (script_name)
        VALUES ('V8__partitioning.sql');

        -- Commit transaction after successful execution
        COMMIT;

        -- Success log
        PRINT 'V8 applied';

    END TRY
    BEGIN CATCH
        -- Rollback transaction on failure
        ROLLBACK;

        -- Propagate error for upstream handling
        THROW;
    END CATCH
END

-- Batch separator required by SQL Server
GO