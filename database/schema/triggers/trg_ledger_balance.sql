-- =============================================
-- TRIGGER: LEDGER BALANCE ENFORCEMENT
-- =============================================

-- Drop existing trigger to allow clean recreation
IF OBJECT_ID('trg_ledger_balance', 'TR') IS NOT NULL
    DROP TRIGGER trg_ledger_balance;
GO

-- Trigger ensures double-entry accounting integrity
-- Fires after insert operations on ledger_entries
CREATE TRIGGER trg_ledger_balance
ON ledger_entries
AFTER INSERT
AS
BEGIN
    -- Prevent extra result sets
    SET NOCOUNT ON;

    --------------------------------------------------
    -- VALIDATION: DEBIT MUST EQUAL CREDIT
    --------------------------------------------------
    -- Checks all affected transactions for balance consistency
    IF EXISTS (
        SELECT 1
        FROM ledger_entries le
        JOIN inserted i ON le.transaction_id = i.transaction_id
        GROUP BY le.transaction_id
        HAVING SUM(le.debit) <> SUM(le.credit)
    )
    BEGIN
        --------------------------------------------------
        -- ERROR HANDLING: ROLLBACK INVALID TRANSACTION
        --------------------------------------------------
        -- Cancels entire transaction if imbalance is detected
        ROLLBACK TRANSACTION;

        -- Raise custom error for caller
        THROW 50001, 'Ledger not balanced!', 1;
    END
END;
GO