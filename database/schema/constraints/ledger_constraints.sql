-- =============================================
-- LEDGER CONSTRAINTS: DATA INTEGRITY RULES
-- =============================================

--------------------------------------------------
-- CHECK CONSTRAINT: POSITIVE VALUES ONLY
--------------------------------------------------
-- Ensures debit and credit values are never negative
IF NOT EXISTS (
    SELECT * FROM sys.check_constraints 
    WHERE name = 'chk_positive_values'
)
BEGIN
    ALTER TABLE ledger_entries
    ADD CONSTRAINT chk_positive_values
    CHECK (debit >= 0 AND credit >= 0);
END
GO

--------------------------------------------------
-- CHECK CONSTRAINT: MUTUALLY EXCLUSIVE SIDES
--------------------------------------------------
-- Enforces double-entry rule:
-- Only one side (debit or credit) can have a value greater than zero
IF NOT EXISTS (
    SELECT * FROM sys.check_constraints 
    WHERE name = 'chk_one_side'
)
BEGIN
    ALTER TABLE ledger_entries
    ADD CONSTRAINT chk_one_side
    CHECK (
        (debit > 0 AND credit = 0) OR
        (credit > 0 AND debit = 0)
    );
END
GO