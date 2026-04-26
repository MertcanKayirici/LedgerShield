-- =============================================
-- TABLE CREATION: PROCESSED EVENTS (IDEMPOTENCY / DEDUPLICATION)
-- =============================================

-- Create table only if it does not already exist
IF OBJECT_ID('processed_events', 'U') IS NULL
BEGIN
    CREATE TABLE processed_events (
        event_id UNIQUEIDENTIFIER PRIMARY KEY, -- Unique identifier of processed event (ensures idempotency)

        processed_at DATETIME2 NOT NULL DEFAULT GETDATE() -- Timestamp when the event was processed
    );
END
GO