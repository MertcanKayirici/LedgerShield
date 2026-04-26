-- =============================================
-- DATABASE SETUP: LEDGERSHIELDDB
-- =============================================

-- Create database only if it does not already exist
IF DB_ID('LedgerShieldDB') IS NULL
BEGIN
    CREATE DATABASE LedgerShieldDB; -- Primary database for ledger system
END
GO

-- Switch context to the target database
USE LedgerShieldDB;
GO