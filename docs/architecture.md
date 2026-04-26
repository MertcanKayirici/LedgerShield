# 🧠 LedgerShield Architecture

## 🎯 Purpose

LedgerShield is a **database-first financial system** designed to enforce correctness directly at the data layer.

### Objectives

* Enforce financial correctness at the database level
* Make invalid states **structurally impossible**
* Define strict rules for concurrency, invariants, and delivery guarantees

---

## 📦 System Boundaries

### ✅ Included

* Schema (tables, constraints, triggers)
* Transaction isolation & concurrency
* Ledger invariant enforcement
* Outbox delivery guarantees

### ❌ Excluded

* UI layer
* Business workflow orchestration
* External system guarantees

---

## 🏗️ Core Modules

- **payment_intents** → source of truth for transaction state  
- **ledger_transactions** → atomic transaction boundary  
- **ledger_entries** → immutable financial records  
- **account_balance** → derived, aggregated state  
- **outbox** → reliable event publishing mechanism  
- **processed_events** → idempotency & deduplication layer  

---

## 🔒 Core Principles

* Database is the **single source of truth**
* Invalid states are **impossible by design**
* System correctness is **enforced, not assumed**
* Consistency is prioritized over availability

---

## 🔁 Write Flow (Mandatory)

1. Resolve tenant / shard
2. Begin transaction
3. Insert into `ledger_transactions`
4. Insert into `ledger_entries`
5. Apply constraints and triggers
6. Commit transaction
7. Write to outbox

### 🚫 Forbidden

* Partial commits
* Writes outside transactions

**Why:** Breaks atomicity
**Consequence:** Financial inconsistency

---

## ⚡ Concurrency Model

* Isolation Level: **SERIALIZABLE**
* Default: Optimistic locking (version-based)
* High contention: Pessimistic locking

### 🚫 Forbidden

* READ COMMITTED for financial writes
* Lost update scenarios

**Why:** Race conditions
**Consequence:** Double-spend / inconsistent state

---

## 📊 Ledger Invariant

### Mandatory Rule

```text
SUM(debit) = SUM(credit)
```

### Enforcement

* Trigger-based validation
* Transaction-level atomicity

### 🚫 Forbidden

* Imbalanced commit

**Why:** Financial correctness
**Consequence:** Accounting failure

---

## 🛡️ Data Integrity Rules

### Allowed

* Tenant-scoped ownership
* Shard-local data

### 🚫 Forbidden

* Cross-tenant references
* Orphan records

**Why:** Data integrity violation
**Consequence:** Silent financial corruption

---

## 🔄 Failure Handling

| Scenario             | Action       |
| -------------------- | ------------ |
| Constraint violation | Reject write |
| Trigger violation    | Rollback     |
| Version conflict     | Retry        |
| Deadlock             | Retry        |

---

## 🔁 Reversal Strategy

### Allowed

* Append-only reversal (new transaction)

### 🚫 Forbidden

* UPDATE financial data
* DELETE financial data

**Why:** Audit integrity
**Consequence:** Compliance failure

---

## 🚀 Idempotency & Delivery

* Idempotency enforced via `idempotency_key`
* Outbox ensures **at-least-once delivery**
* Deduplication via `processed_events`

### 🚫 Forbidden

* Assuming exactly-once delivery

**Why:** Distributed system limitation
**Consequence:** Duplicate execution

---

## 📦 Naming Conventions

| Type    | Format |
| ------- | ------ |
| PK      | pk_*   |
| FK      | fk_*   |
| UNIQUE  | uq_*   |
| CHECK   | chk_*  |
| INDEX   | idx_*  |
| TRIGGER | trg_*  |

---

## 🧾 Audit & Traceability

All writes must include:

* `tenant_id`
* `trace_id`
* `shard_id`
* `node_id`

### 🚫 Forbidden

* Untraceable operations

**Why:** Debugging becomes impossible
**Consequence:** Irrecoverable incidents

---

## 📊 Guarantees

The system guarantees:

- Ledger balance is always mathematically correct  
- Invalid states cannot exist in storage  
- Duplicate operations are prevented at write time  
- Cross-tenant data leakage is impossible by design  

---

## ⚠️ Residual Risks

| Risk        | Reason                 | Impact                |
| ----------- | ---------------------- | --------------------- |
| Data loss   | Async replication      | Loss of latest writes |
| Split-brain | Network partition      | Divergent state       |
| Human error | Operational complexity | Service disruption    |

---

## 🧠 Final Verdict

LedgerShield enforces:

- Consistency: **STRICT (SERIALIZABLE)**  
- Enforcement: **Database-level guarantees**  
- Financial correctness: **Mathematically enforced, not validated later**

---

## 🎯 Why This Architecture

Traditional systems enforce business rules at the application layer.

LedgerShield takes a different approach:

- Moves correctness into the database  
- Eliminates entire classes of bugs  
- Guarantees financial integrity by design  

This results in a system that is:

- Predictable  
- Verifiable  
- Safe under concurrency  

---

## 🔥 Golden Rule

> **Incorrect data cannot be written**  
> **System correctness is enforced, not assumed**

---

## 🧩 Assumptions

* Database is the single source of truth
* Network is unreliable
* External systems are eventually consistent
