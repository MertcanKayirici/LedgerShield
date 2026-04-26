-- =============================================
-- TABLE CREATION: OUTBOX (EVENT DISPATCH PATTERN)
-- =============================================

-- Create table only if it does not already exist
IF OBJECT_ID('outbox', 'U') IS NULL
BEGIN
    CREATE TABLE outbox (
        event_id UNIQUEIDENTIFIER PRIMARY KEY, -- Unique identifier for each event

        aggregate_id UNIQUEIDENTIFIER NOT NULL, -- Reference to related aggregate (e.g., payment_intent_id)

        event_type NVARCHAR(100) NOT NULL, -- Type of event (e.g., PaymentCreated)

        payload NVARCHAR(MAX) NOT NULL, -- Serialized event data

        created_at DATETIME2 NOT NULL DEFAULT GETDATE(), -- Event creation timestamp

        processed BIT NOT NULL DEFAULT 0 -- Processing flag for async consumers
    );

    --------------------------------------------------
    -- INDEXES
    --------------------------------------------------

    -- Optimizes retrieval of unprocessed events for background workers
    CREATE INDEX idx_outbox_processed
    ON outbox(processed);

END
GO