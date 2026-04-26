# 📊 Performance Report

## 🎯 Overview

This report evaluates the performance of balance calculation queries in the LedgerShield system.

The goal is to measure the impact of:

* Index optimization
* Indexed view usage

---

## 🧪 Test Scenario

Balance calculation query:

```sql
SELECT 
    account, 
    SUM(debit - credit) AS balance
FROM ledger_entries
WHERE is_deleted = 0
GROUP BY account;
```

Dataset:

* ~10,000 transactions
* Multi-tenant structure
* Double-entry ledger records

---

## 🔴 Before Optimization

Execution without indexed view and optimized indexes.

* Execution Type: Table Scan
* Logical Reads: 234
* CPU Time: ~10 ms
* Elapsed Time: ~10 ms

---

## 🟢 After Optimization

Execution using:

* Filtered index

* Indexed view (`vw_account_balance`)

* Execution Type: Index Seek

* Logical Reads: 2

* CPU Time: ~0 ms

* Elapsed Time: ~0–1 ms

---

## 📊 Comparison

| Metric         | Before | After |
| -------------- | ------ | ----- |
| Logical Reads  | 234    | 2     |
| CPU Time       | 10 ms  | 0 ms  |
| Execution Plan | Scan   | Seek  |

---

## 🖼️ Visual Evidence

![Performance Comparison](docs/diagrams/before_after_balance_update.png)

---

## 🧠 Analysis

* Full table scan is eliminated after optimization
* Indexed view enables pre-aggregated balance calculation
* Filtered index reduces unnecessary row reads (`is_deleted = 0`)
* Query cost is reduced dramatically

---

## 🚀 Conclusion

The system achieves significant performance improvement by:

* Using indexed views for aggregation
* Applying targeted indexing strategy
* Reducing I/O operations

This demonstrates that the LedgerShield system is optimized for **read-heavy financial workloads**.
