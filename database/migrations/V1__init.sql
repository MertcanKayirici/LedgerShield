-- =============================================
-- INITIAL SETUP SCRIPT ENTRY POINT
-- =============================================

PRINT 'START';

-- Execute base database setup (e.g., DB creation, configs)
:r ..\setup\setup_database.sql

--------------------------------------------------
-- MIGRATION HISTORY (CREATE FIRST)
--------------------------------------------------
-- Ensures migration tracking table exists before any checks/inserts
:r ..\schema\tables\migration_history.sql

--------------------------------------------------
-- V1 CHECK (LOG ONLY, NO BLOCKING)
--------------------------------------------------
-- Check if V1 migration has already been applied
IF EXISTS (
    SELECT 1 FROM migration_history 
    WHERE script_name = 'V1__init.sql'
)
BEGIN
    -- Informational log only, does not stop execution
    PRINT 'V1 already applied';
END
ELSE
BEGIN
    -- Informational log before applying schema
    PRINT 'Applying V1...';
END

--------------------------------------------------
-- TABLES
--------------------------------------------------
-- Core domain tables
:r ..\schema\tables\payment_intents.sql
:r ..\schema\tables\ledger_transactions.sql
:r ..\schema\tables\ledger_entries.sql
:r ..\schema\tables\outbox.sql
:r ..\schema\tables\processed_events.sql
:r ..\schema\tables\account_balance.sql

--------------------------------------------------
-- CONSTRAINTS
--------------------------------------------------
-- Apply relational and business rule constraints
:r ..\schema\constraints\payment_constraints.sql
:r ..\schema\constraints\ledger_constraints.sql

--------------------------------------------------
-- INDEXES
--------------------------------------------------
-- Performance optimization indexes
:r ..\schema\indexes\indexes.sql

--------------------------------------------------
-- TRIGGER
--------------------------------------------------
-- Trigger for maintaining ledger balance integrity
:r ..\triggers\trg_ledger_balance.sql

--------------------------------------------------
-- PROCEDURE
--------------------------------------------------
-- Stored procedure for transaction creation logic
:r ..\procedures\sp_create_transaction.sql

-- Trigger for updating account balance after changes
:r ..\triggers\trg_update_balance.sql

--------------------------------------------------
-- HISTORY INSERT
--------------------------------------------------
-- Record migration execution if not already logged
IF NOT EXISTS (
    SELECT 1 FROM migration_history 
    WHERE script_name = 'V1__init.sql'
)
BEGIN
    INSERT INTO migration_history (script_name)
    VALUES ('V1__init.sql');
END

-- Final status output
PRINT 'SETUP OK';