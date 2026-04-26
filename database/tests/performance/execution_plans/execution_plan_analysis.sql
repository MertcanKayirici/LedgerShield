-- =============================================
-- EXECUTION PLAN ANALYSIS: QUERY PERFORMANCE
-- =============================================

-- Informational log indicating analysis start
PRINT '--- EXECUTION PLAN ANALYSIS START ---';

-- Suppress row count messages for cleaner output
SET NOCOUNT ON;

--------------------------------------------------
-- ENABLE ACTUAL EXECUTION PLAN
--------------------------------------------------
-- In SSMS: Press Ctrl + M before running this script
-- This allows visualization of actual execution plans

--------------------------------------------------
-- RAW QUERY PLAN (BASE TABLE AGGREGATION)
--------------------------------------------------
-- Evaluates performance of direct aggregation on ledger_entries
-- Expected: Index scan/seek + aggregation (Hash or Stream Aggregate)
PRINT 'RAW QUERY PLAN';

SELECT 
    account, -- Grouping column
    SUM(debit - credit) AS balance -- Runtime aggregation
FROM dbo.ledger_entries
WHERE is_deleted = 0 -- Filter active records
GROUP BY account;

--------------------------------------------------
-- INDEXED VIEW PLAN (PRE-AGGREGATED)
--------------------------------------------------
-- Evaluates performance using materialized indexed view
-- NOEXPAND forces optimizer to use the indexed view directly
PRINT 'INDEXED VIEW PLAN';

SELECT 
    account, -- Pre-aggregated key
    balance  -- Precomputed value
FROM dbo.vw_account_balance WITH (NOEXPAND);

--------------------------------------------------
-- INDEX USAGE STATISTICS
--------------------------------------------------
-- Analyzes how indexes are utilized by the workload
-- Useful for identifying unused or heavily used indexes
PRINT 'INDEX USAGE STATS';

SELECT 
    i.name,           -- Index name
    s.user_seeks,     -- Number of seek operations
    s.user_scans,     -- Number of scan operations
    s.user_lookups,   -- Key lookups performed
    s.user_updates    -- Number of updates affecting the index
FROM sys.dm_db_index_usage_stats s
JOIN sys.indexes i 
    ON s.object_id = i.object_id 
    AND s.index_id = i.index_id
WHERE OBJECT_NAME(s.object_id) IN ('ledger_entries', 'vw_account_balance');

--------------------------------------------------
-- EXPECTED OBSERVATIONS
--------------------------------------------------
-- 1. RAW query may perform scans and runtime aggregation (higher cost)
-- 2. Indexed view should use clustered index seek (lower cost)
-- 3. High user_scans may indicate missing indexes or suboptimal queries
-- 4. High user_updates indicates maintenance overhead on indexes

-- Informational log indicating analysis completion
PRINT '--- EXECUTION PLAN ANALYSIS END ---';