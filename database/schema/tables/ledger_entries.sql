-- =============================================
-- TABLE CREATION: LEDGER ENTRIES (DOUBLE-ENTRY)
-- =============================================

-- Create table only if it does not already exist
IF OBJECT_ID('ledger_entries', 'U') IS NULL
BEGIN
    CREATE TABLE ledger_entries (
        entry_id UNIQUEIDENTIFIER PRIMARY KEY, -- Unique identifier for each ledger entry

        transaction_id UNIQUEIDENTIFIER NOT NULL, -- Reference to parent transaction

        account NVARCHAR(50) NOT NULL, -- Account name or code (e.g., CASH, BANK)

        debit DECIMAL(18,2) NOT NULL DEFAULT 0,  -- Debit amount (must be >= 0)
        credit DECIMAL(18,2) NOT NULL DEFAULT 0, -- Credit amount (must be >= 0)

        created_at DATETIME2 NOT NULL DEFAULT GETDATE(), -- Timestamp of entry creation

        --------------------------------------------------
        -- FOREIGN KEY CONSTRAINT
        --------------------------------------------------
        -- Ensures each entry is linked to a valid transaction
        CONSTRAINT fk_entry_transaction
        FOREIGN KEY (transaction_id)
        REFERENCES ledger_transactions(transaction_id),

        --------------------------------------------------
        -- CHECK CONSTRAINT: NON-NEGATIVE VALUES
        --------------------------------------------------
        -- Prevents negative debit or credit values
        CONSTRAINT chk_positive_values
        CHECK (debit >= 0 AND credit >= 0),

        --------------------------------------------------
        -- CHECK CONSTRAINT: MUTUALLY EXCLUSIVE SIDES
        --------------------------------------------------
        -- Enforces double-entry rule: only one side can be non-zero
        CONSTRAINT chk_one_side
        CHECK (
            (debit > 0 AND credit = 0) OR
            (credit > 0 AND debit = 0)
        )
    );

    --------------------------------------------------
    -- INDEXES
    --------------------------------------------------

    -- Optimizes lookup by transaction_id (joins, filtering)
    CREATE INDEX idx_entry_transaction
    ON ledger_entries(transaction_id);

    -- Optimizes queries filtering or grouping by account
    CREATE INDEX idx_entry_account
    ON ledger_entries(account);

END
GO