-- =============================================
-- TABLE CREATION: ACCOUNT BALANCE SNAPSHOT
-- =============================================

-- Informational log indicating table creation start
PRINT 'Creating table: account_balance';

-- Create table only if it does not already exist
IF OBJECT_ID('dbo.account_balance', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.account_balance (
        account NVARCHAR(50) PRIMARY KEY,        -- Unique account identifier
        balance DECIMAL(18,2) NOT NULL DEFAULT 0, -- Current aggregated balance
        updated_at DATETIME2 DEFAULT GETDATE()   -- Last update timestamp
    );
END

-- Informational log indicating table is ready for use
PRINT 'account_balance ready';