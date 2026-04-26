# 🧠 LedgerShield Architecture

## 🎯 Purpose

LedgerShield is a database-first financial system designed to enforce correctness at the data layer.

**Objectives:**

* Enforce financial correctness at the database level
* Make invalid states impossible
* Define strict concurrency, invariants, and delivery guarantees

---

## 📦 System Boundaries

### ✅ Included

* Schema (tables, constraints, triggers)
* Transaction isolation & concurrency
* Ledger invariant enforcement
* Outbox delivery guarantees

### ❌ Excluded

* UI
* Business workflows
* External system guarantees

---

## 🏗️ Core Modules

* **payment_intents** → state authority
* **ledger_transactions** → transaction boundary
* **ledger_entries** → financial atomic units
* **account_balance** → aggregated state
* **outbox** → event publishing
* **processed_events** → deduplication

---

## 🔒 Core Principles

* Database is the single source of truth
* Invalid states are impossible
* System correctness is enforced, not assumed
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

**Forbidden:**

* Partial commits
* Writes outside transactions

---

## ⚡ Concurrency Model

* Isolation Level: **SERIALIZABLE**
* Default: Optimistic locking (version-based)
* High contention: Pessimistic locking

**Forbidden:**

* READ COMMITTED for financial writes
* Lost update scenarios

---

## 📊 Ledger Invariant

**Mandatory Rule:**

```text
SUM(debit) = SUM(credit)
```

**Enforced by:**

* Trigger validation
* Transaction-level atomicity

---

## 🛡️ Data Integrity Rules

### Allowed

* Tenant-scoped ownership
* Shard-local data

### Forbidden

* Cross-tenant references
* Orphan records

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

### Forbidden

* UPDATE financial data
* DELETE financial data

---

## 🚀 Idempotency & Delivery

* Idempotency enforced via `idempotency_key`
* Outbox pattern ensures **at-least-once delivery**
* Deduplication via `processed_events`

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

---

## 📊 Guarantees

* Ledger balance is always correct
* Invalid states cannot exist
* Duplicate operations are prevented
* Cross-tenant data leakage is impossible

---

## ⚠️ Residual Risks

| Risk        | Reason             | Impact                    |
| ----------- | ------------------ | ------------------------- |
| Data loss   | Async replication  | Latest writes may be lost |
| Split-brain | Network partition  | Divergent state           |
| Human error | Operational issues | Service disruption        |

---

## 🧠 Final Verdict

* Consistency: **STRICT (SERIALIZABLE)**
* Enforcement: Database-level guarantees
* Financial correctness: Mathematically enforced

---

## 🔥 Golden Rule

> Incorrect data cannot be written 

> System correctness is enforced, not assumed

---

## 🧩 Assumptions

* Database is the single source of truth
* Network is unreliable
* External systems are eventually consistent
