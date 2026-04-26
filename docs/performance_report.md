# 📊 Performance Report

## 🎯 Overview

This report demonstrates the performance impact of optimizing balance queries in the LedgerShield system.

The focus is on eliminating full table scans and enabling efficient aggregation using:

* Filtered indexes
* Indexed views

---

## 🧪 Test Scenario

### Query

```sql
SELECT 
    account, 
    SUM(debit - credit) AS balance
FROM ledger_entries
WHERE is_deleted = 0
GROUP BY account;
```

### Dataset

* ~10,000 transactions
* Multi-tenant structure
* Double-entry ledger entries

---

## 🔴 Before Optimization

Execution without proper indexing or pre-aggregation.

* Execution Plan: **Table Scan**
* Logical Reads: **234**
* CPU Time: **~10 ms**
* Elapsed Time: **~10 ms**

### ❗ Problem

* Full table scan on `ledger_entries`
* High I/O cost
* Poor scalability as data grows

---

## 🟢 After Optimization

Execution using:

* Filtered index (`is_deleted = 0`)
* Indexed view (`vw_account_balance`)

* Execution Plan: **Index Seek**

* Logical Reads: **2**

* CPU Time: **~0 ms**

* Elapsed Time: **~0–1 ms**

### ✅ Improvement

* Eliminated full table scan
* Reduced I/O dramatically
* Enabled pre-aggregated reads

---

## 📊 Comparison

| Metric        | Before | After | Improvement  |
| ------------- | ------ | ----- | ------------ |
| Logical Reads | 234    | 2     | 🔥 ~99% ↓  (~117x)  |
| CPU Time      | 10 ms  | 0 ms  | ⚡ Near 0     |
| Execution     | Scan   | Seek  | 💥 Optimized |

---

## 🖼️ Visual Evidence

![Performance Comparison](diagrams/before_after_balance_update.png)

---

## 🧠 Analysis

The optimization works because:

* Indexed view stores pre-aggregated balances
* Filtered index limits unnecessary row access
* Query avoids scanning entire ledger table

This transforms the query from **O(n)** scanning to near **constant-time lookup**.

---

## 🚀 Conclusion

LedgerShield achieves high performance by:

* Shifting computation from query-time to write-time
* Using indexed views for real-time aggregation
* Minimizing I/O operations

### 🔥 Key Insight

> Performance is not improved by faster queries,
> but by avoiding unnecessary work entirely.

---

## 🎯 Result

The system is optimized for:

* Read-heavy financial workloads
* Real-time balance queries
* Scalable ledger operations
