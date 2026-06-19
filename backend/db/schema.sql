-- 4S Malini Mahal — database schema
-- Apply with:  psql -U postgres -d malinimahal -f backend/db/schema.sql

CREATE TABLE IF NOT EXISTS enquiries (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reference     TEXT        NOT NULL UNIQUE,
    customer_name TEXT        NOT NULL,
    mobile        TEXT        NOT NULL,
    event_date    DATE        NOT NULL,
    function_type TEXT        NOT NULL,
    rental_type   TEXT        NOT NULL
                  CHECK (rental_type IN ('HOURLY', 'HALF_DAY', 'FULL_DAY')),
    message       TEXT,
    status        TEXT        NOT NULL DEFAULT 'NEW'
                  CHECK (status IN ('NEW', 'UNDER_ENQUIRY', 'CONFIRMED', 'DECLINED', 'CANCELLED')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_enquiries_event_date ON enquiries (event_date);

CREATE TABLE IF NOT EXISTS admin_users (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      TEXT        NOT NULL UNIQUE,
    password_hash TEXT        NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS gallery_items (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    media_type    TEXT        NOT NULL CHECK (media_type IN ('IMAGE', 'VIDEO')),
    filename      TEXT,
    youtube_url   TEXT,
    title         TEXT,
    display_order INT         NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS blocked_dates (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    blocked_date DATE        NOT NULL UNIQUE,
    reason       TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Migration: rename event_type → function_type (idempotent) ──────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'enquiries' AND column_name = 'event_type'
  ) THEN
    ALTER TABLE enquiries RENAME COLUMN event_type TO function_type;
  END IF;
END $$;

-- ── Migration: enforce valid function_type values (idempotent) ─────────────
ALTER TABLE enquiries DROP CONSTRAINT IF EXISTS enquiries_function_type_check;
ALTER TABLE enquiries ADD CONSTRAINT enquiries_function_type_check
  CHECK (function_type IN (
    'MARRIAGE',
    'RECEPTION', 'ENGAGEMENT', 'BIRTHDAY_FUNCTION', 'KARI_SAAPADU',
    'MEETING', 'CONFERENCE', 'TRAINING_SESSION', 'SEMINAR', 'WORKSHOP',
    'SMALL_GATHERING', 'OTHER_HOURLY'
  ));

-- ── Migration: add time columns for bookings (idempotent) ─────────────────
ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS start_datetime TIMESTAMPTZ;
ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS end_datetime TIMESTAMPTZ;

-- ── Migration: expand valid statuses to include payment workflow ─────────
ALTER TABLE enquiries DROP CONSTRAINT IF EXISTS enquiries_status_check;
ALTER TABLE enquiries ADD CONSTRAINT enquiries_status_check
  CHECK (status IN ('NEW', 'UNDER_ENQUIRY', 'AWAITING_PAYMENT', 'CONFIRMED', 'DECLINED', 'CANCELLED', 'COMPLETED', 'REJECTED'));

-- ── Migration: billing columns (post-event charges entered by admin) ──────
ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS elec_units               DOUBLE PRECISION;
ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS gas_kg                   DOUBLE PRECISION;
ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS decoration_charge_paise  BIGINT;

-- ── Payments table ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
    id                  BIGSERIAL PRIMARY KEY,
    enquiry_ref         VARCHAR(20)  NOT NULL,
    razorpay_order_id   VARCHAR(64)  UNIQUE NOT NULL,
    razorpay_payment_id VARCHAR(64),
    razorpay_signature  TEXT,
    amount_paise        BIGINT       NOT NULL,
    payment_type        VARCHAR(10)  NOT NULL CHECK (payment_type IN ('ADVANCE', 'BALANCE')),
    status              VARCHAR(10)  NOT NULL DEFAULT 'PENDING'
                        CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED')),
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_enquiry_ref ON payments (enquiry_ref);
