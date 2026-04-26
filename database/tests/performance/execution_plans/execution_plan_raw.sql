-- =============================================
-- PERFORMANCE TEST: RAW AGGREGATION (BASE TABLE)
-- =============================================

/*
DESCRIPTION:
Raw aggregation query without optimization

EXPECTED:
- Index Scan or Table Scan on ledger_entries
- Hash Aggregate or Stream Aggregate operator
- Higher logical reads due to full/partial scan

OBSERVATION:
- Significantly more expensive than indexed view approach
- Example: ~150 logical reads vs ~2 reads (indexed view)

NOTES:
- Aggregation is computed at runtime
- Performance degrades with data growth
*/

--------------------------------------------------
-- ENABLE PERFORMANCE METRICS
--------------------------------------------------
-- Outputs logical reads and execution time
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

--------------------------------------------------
-- EXECUTE RAW AGGREGATION QUERY
--------------------------------------------------
-- Performs on-the-fly aggregation over ledger_entries
SELECT 
    account,                               -- Grouping column
    SUM(debit - credit) AS balance          -- Runtime aggregation
FROM dbo.ledger_entries
WHERE is_deleted = 0                       -- Filter active records
GROUP BY account;

--------------------------------------------------
-- DISABLE PERFORMANCE METRICS
--------------------------------------------------
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

--------------------------------------------------
-- EXPECTED OUTPUT (SSMS MESSAGES TAB)
--------------------------------------------------
-- IO: Higher logical reads (e.g., ~150+ depending on data size)
-- TIME: Higher CPU and elapsed time
-- PLAN: Index/Table Scan + Aggregate (Hash/Stream)
--
-- COMPARISON:
-- - Slower than indexed view approach
-- - Suitable only for small datasets or ad-hoc queries