-- =============================================
-- PERFORMANCE COMPARISON TEST: RAW vs INDEXED VIEW
-- =============================================

-- Informational log indicating test start
PRINT '--- PERFORMANCE TEST START ---';

-- Suppress row count messages for cleaner output
SET NOCOUNT ON;

--------------------------------------------------
-- RAW QUERY (BASELINE MEASUREMENT)
--------------------------------------------------
-- Measures cost of runtime aggregation on base table
PRINT 'Running RAW query...';

-- Enable IO and TIME statistics
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Perform aggregation directly on ledger_entries
SELECT 
    account,                               -- Grouping column
    SUM(debit - credit) AS balance          -- Runtime aggregation
FROM dbo.ledger_entries
WHERE is_deleted = 0                       -- Filter active records
GROUP BY account;

-- Disable statistics collection
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- Log completion of RAW query
PRINT '--- RAW DONE ---';

--------------------------------------------------
-- INDEXED VIEW QUERY (OPTIMIZED)
--------------------------------------------------
-- Measures cost of reading pre-aggregated data
PRINT 'Running INDEXED VIEW...';

-- Enable IO and TIME statistics
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Query materialized indexed view
-- NOEXPAND forces usage of indexed view instead of base table expansion
SELECT 
    account, -- Clustered index key
    balance  -- Precomputed aggregate value
FROM dbo.vw_account_balance WITH (NOEXPAND);

-- Disable statistics collection
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- Log completion of indexed view query
PRINT '--- INDEXED VIEW DONE ---';

--------------------------------------------------
-- EXPECTED COMPARISON RESULTS
--------------------------------------------------
-- RAW QUERY:
--   - Higher logical reads (e.g., ~150+)
--   - Uses scan + aggregation operators
--   - CPU and elapsed time increase with data size
--
-- INDEXED VIEW:
--   - Very low logical reads (e.g., ~2)
--   - Uses clustered index seek
--   - Minimal CPU and execution time
--
-- CONCLUSION:
-- Indexed view provides significant performance improvement
-- for aggregation-heavy workloads

-- Informational log indicating test completion
PRINT '--- PERFORMANCE TEST END ---';