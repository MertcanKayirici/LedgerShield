-- =============================================
-- PAYMENT CONSTRAINTS: DATA VALIDATION RULES
-- =============================================

--------------------------------------------------
-- CHECK CONSTRAINT: AMOUNT MUST BE POSITIVE
--------------------------------------------------
-- Ensures that payment amounts are greater than zero
IF NOT EXISTS (
    SELECT * FROM sys.check_constraints 
    WHERE name = 'chk_payment_amount'
)
BEGIN
    ALTER TABLE payment_intents
    ADD CONSTRAINT chk_payment_amount 
    CHECK (amount > 0);
END
GO

--------------------------------------------------
-- CHECK CONSTRAINT: VALID STATUS VALUES
--------------------------------------------------
-- Restricts status field to predefined lifecycle states
IF NOT EXISTS (
    SELECT * FROM sys.check_constraints 
    WHERE name = 'chk_payment_status'
)
BEGIN
    ALTER TABLE payment_intents
    ADD CONSTRAINT chk_payment_status
    CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED'));
END
GO

--------------------------------------------------
-- UNIQUE CONSTRAINT: IDEMPOTENCY KEY
--------------------------------------------------
-- Guarantees that each idempotency_key is unique across payment_intents
-- Prevents duplicate processing of the same request
IF NOT EXISTS (
    SELECT * FROM sys.indexes 
    WHERE name = 'uq_payment_idempotency'
)
BEGIN
    ALTER TABLE payment_intents
    ADD CONSTRAINT uq_payment_idempotency
    UNIQUE (idempotency_key);
END
GO