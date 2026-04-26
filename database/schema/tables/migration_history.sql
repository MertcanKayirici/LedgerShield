-- =============================================
-- TABLE CREATION: MIGRATION HISTORY
-- =============================================

-- Create table only if it does not already exist
IF OBJECT_ID('migration_history', 'U') IS NULL
BEGIN
    CREATE TABLE migration_history (
        id INT IDENTITY PRIMARY KEY,         -- Auto-incrementing unique identifier for each migration record
        script_name NVARCHAR(200),           -- Name of the executed migration script
        executed_at DATETIME2 DEFAULT GETDATE() -- Timestamp when the migration was executed
    );
END
GO