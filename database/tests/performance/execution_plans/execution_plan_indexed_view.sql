-- =============================================
-- PERFORMANCE TEST: INDEXED VIEW QUERY (LOW COST)
-- =============================================

/*
DESCRIPTION:
Optimized query using Indexed View

EXPECTED:
- Clustered Index Seek on indexed view
- Minimal logical reads (typically ~2)
- No aggregation at runtime (precomputed)

NOTES:
- NOEXPAND hint forces usage of indexed view instead of base table expansion
- STATISTICS IO/TIME used for performance measurement
*/

--------------------------------------------------
-- ENABLE PERFORMANCE METRICS
--------------------------------------------------
-- Displays logical reads and CPU/elapsed time
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

--------------------------------------------------
-- EXECUTE OPTIMIZED QUERY
--------------------------------------------------
-- Reads directly from materialized indexed view
-- Avoids expensive GROUP BY on large dataset
SELECT 
    account,  -- Grouping key (clustered index key)
    balance   -- Precomputed aggregate value
FROM dbo.vw_account_balance WITH (NOEXPAND);

--------------------------------------------------
-- DISABLE PERFORMANCE METRICS
--------------------------------------------------
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

--------------------------------------------------
-- EXPECTED OUTPUT (SSMS MESSAGES TAB)
--------------------------------------------------
-- IO: Very low logical reads (e.g., ~2)
-- TIME: Minimal CPU and elapsed time
-- PLAN: Clustered Index Seek on IX_vw_account_balance