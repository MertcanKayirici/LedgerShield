-- =============================================
-- TRIGGER: ACCOUNT BALANCE MAINTENANCE (INCREMENTAL)
-- =============================================

-- Informational log indicating trigger creation start
PRINT 'Creating trigger: trg_update_balance';

--------------------------------------------------
-- DROP EXISTING TRIGGER (IF EXISTS)
--------------------------------------------------
-- Ensures clean recreation with latest definition
IF OBJECT_ID('dbo.trg_update_balance', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_update_balance;
GO

--------------------------------------------------
-- CREATE TRIGGER
--------------------------------------------------
-- Maintains account_balance table incrementally
-- Handles INSERT, UPDATE, DELETE operations on ledger_entries
CREATE TRIGGER dbo.trg_update_balance
ON dbo.ledger_entries
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Prevent extra result sets
    SET NOCOUNT ON;

    /*
      inserted  -> new rows (INSERT / UPDATE)
      deleted   -> old rows (DELETE / UPDATE)

      Logic:
      + inserted values
      - deleted values
      = net change per account
    */

    ;WITH changes AS (
        --------------------------------------------------
        -- INSERT / UPDATE (NEW VALUES)
        --------------------------------------------------
        -- Adds new contributions to balance
        SELECT 
            account,
            SUM(CASE 
                WHEN is_deleted = 0 THEN (debit - credit) 
                ELSE 0 
            END) AS amount
        FROM inserted
        GROUP BY account

        UNION ALL

        --------------------------------------------------
        -- DELETE / UPDATE (OLD VALUES)
        --------------------------------------------------
        -- Subtracts previous contributions from balance
        SELECT 
            account,
            -SUM(CASE 
                WHEN is_deleted = 0 THEN (debit - credit) 
                ELSE 0 
            END)
        FROM deleted
        GROUP BY account
    ),
    aggregated AS (
        --------------------------------------------------
        -- NET CHANGE PER ACCOUNT
        --------------------------------------------------
        -- Consolidates all changes into a single delta per account
        SELECT 
            account,
            SUM(amount) AS net_amount
        FROM changes
        GROUP BY account
    )
    --------------------------------------------------
    -- UPSERT INTO account_balance
    --------------------------------------------------
    -- Applies incremental updates or inserts new accounts
    MERGE dbo.account_balance AS target
    USING aggregated AS src
    ON target.account = src.account

    WHEN MATCHED THEN
        UPDATE SET 
            balance = target.balance + src.net_amount, -- Incremental update
            updated_at = GETDATE()                     -- Refresh timestamp

    WHEN NOT MATCHED THEN
        INSERT (account, balance)
        VALUES (src.account, src.net_amount);          -- Initial insert

END
GO

-- Informational log indicating successful creation
PRINT 'Trigger created successfully';