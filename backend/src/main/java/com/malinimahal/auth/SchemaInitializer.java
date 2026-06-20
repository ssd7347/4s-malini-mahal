package com.malinimahal.auth;

import com.malinimahal.db.Database;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

import java.sql.Connection;
import java.sql.Statement;

@WebListener
public class SchemaInitializer implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        try (Connection c = Database.getConnection(); Statement st = c.createStatement()) {
            st.execute(
                "CREATE TABLE IF NOT EXISTS customers (" +
                "  id         BIGSERIAL PRIMARY KEY," +
                "  mobile     VARCHAR(15) UNIQUE NOT NULL," +
                "  created_at TIMESTAMPTZ DEFAULT NOW()" +
                ")"
            );
            st.execute(
                "CREATE TABLE IF NOT EXISTS auth_otps (" +
                "  id         BIGSERIAL PRIMARY KEY," +
                "  mobile     VARCHAR(15) NOT NULL," +
                "  code       VARCHAR(6)  NOT NULL," +
                "  created_at TIMESTAMPTZ DEFAULT NOW()," +
                "  expires_at TIMESTAMPTZ NOT NULL," +
                "  attempts   INT NOT NULL DEFAULT 0," +
                "  used       BOOLEAN NOT NULL DEFAULT FALSE" +
                ")"
            );
            st.execute(
                "CREATE INDEX IF NOT EXISTS idx_auth_otps_active " +
                "ON auth_otps(mobile, used, expires_at)"
            );
            sce.getServletContext().log("Auth schema ready.");
        } catch (Exception e) {
            sce.getServletContext().log("Auth schema init failed", e);
        }

        // Enquiry table migrations — safe to run at every startup (idempotent via DO block).
        try (Connection c2 = Database.getConnection(); Statement st2 = c2.createStatement()) {
            st2.execute(
                "DO $$ BEGIN " +
                "  ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS end_date DATE; " +
                "  UPDATE enquiries SET end_date = event_date WHERE end_date IS NULL; " +
                "  ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS start_datetime TIMESTAMPTZ; " +
                "  ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS end_datetime TIMESTAMPTZ; " +
                "  ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS elec_units DOUBLE PRECISION; " +
                "  ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS gas_kg DOUBLE PRECISION; " +
                "  ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS decoration_charge_paise BIGINT; " +
                "  ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS is_muhurtham BOOLEAN NOT NULL DEFAULT FALSE; " +
                "  ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS early_entry_charge_paise BIGINT DEFAULT 0; " +
                "  ALTER TABLE enquiries ADD COLUMN IF NOT EXISTS key_loss_charge_paise BIGINT DEFAULT 0; " +
                "  ALTER TABLE enquiries DROP CONSTRAINT IF EXISTS enquiries_status_check; " +
                "  ALTER TABLE enquiries ADD CONSTRAINT enquiries_status_check " +
                "    CHECK (status IN ('NEW','UNDER_ENQUIRY','AWAITING_PAYMENT','CONFIRMED','DECLINED','CANCELLED','COMPLETED','REJECTED')); " +
                "  ALTER TABLE enquiries DROP CONSTRAINT IF EXISTS enquiries_function_type_check; " +
                "  ALTER TABLE enquiries ADD CONSTRAINT enquiries_function_type_check " +
                "    CHECK (function_type IN ('MARRIAGE','RECEPTION','ENGAGEMENT','BIRTHDAY_FUNCTION','OTHER'," +
                "      'MEETING','CONFERENCE','TRAINING_SESSION','SEMINAR','WORKSHOP','SMALL_GATHERING','OTHER_HOURLY')); " +
                "EXCEPTION WHEN OTHERS THEN NULL; END $$;"
            );
            sce.getServletContext().log("Enquiry schema migrations applied.");
        } catch (Exception e) {
            sce.getServletContext().log("Enquiry schema migration failed (non-fatal)", e);
        }

        // Payments table — created once, idempotent
        try (Connection c3 = Database.getConnection(); Statement st3 = c3.createStatement()) {
            st3.execute(
                "CREATE TABLE IF NOT EXISTS payments (" +
                "  id                  BIGSERIAL PRIMARY KEY," +
                "  enquiry_ref         VARCHAR(20) NOT NULL," +
                "  razorpay_order_id   VARCHAR(64) UNIQUE NOT NULL," +
                "  razorpay_payment_id VARCHAR(64)," +
                "  razorpay_signature  TEXT," +
                "  amount_paise        BIGINT NOT NULL," +
                "  payment_type        VARCHAR(10) NOT NULL CHECK (payment_type IN ('ADVANCE','BALANCE'))," +
                "  status              VARCHAR(10) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','SUCCESS','FAILED'))," +
                "  created_at          TIMESTAMPTZ DEFAULT NOW()" +
                ")"
            );
            st3.execute(
                "CREATE INDEX IF NOT EXISTS idx_payments_enquiry_ref ON payments(enquiry_ref)"
            );
            sce.getServletContext().log("Payments schema ready.");
        } catch (Exception e) {
            sce.getServletContext().log("Payments schema init failed (non-fatal)", e);
        }

        // Muhurtham dates table
        try (Connection c4 = Database.getConnection(); Statement st4 = c4.createStatement()) {
            st4.execute(
                "CREATE TABLE IF NOT EXISTS muhurtham_dates (" +
                "  id         BIGSERIAL PRIMARY KEY," +
                "  mdate      DATE NOT NULL UNIQUE," +
                "  note       TEXT," +
                "  created_at TIMESTAMPTZ DEFAULT NOW()" +
                ")"
            );
            sce.getServletContext().log("Muhurtham schema ready.");
        } catch (Exception e) {
            sce.getServletContext().log("Muhurtham schema init failed (non-fatal)", e);
        }

        // Terms & Conditions tables
        try (Connection c5 = Database.getConnection(); Statement st5 = c5.createStatement()) {
            st5.execute(
                "CREATE TABLE IF NOT EXISTS terms_versions (" +
                "  id             BIGSERIAL PRIMARY KEY," +
                "  version        INT NOT NULL UNIQUE," +
                "  tamil_text     TEXT NOT NULL," +
                "  english_text   TEXT," +
                "  image_filename TEXT," +
                "  is_active      BOOLEAN NOT NULL DEFAULT FALSE," +
                "  created_at     TIMESTAMPTZ DEFAULT NOW()" +
                ")"
            );
            st5.execute(
                "CREATE TABLE IF NOT EXISTS terms_acceptances (" +
                "  id          BIGSERIAL PRIMARY KEY," +
                "  enquiry_ref VARCHAR(20) NOT NULL," +
                "  mobile      VARCHAR(15) NOT NULL," +
                "  version_id  BIGINT NOT NULL," +
                "  accepted_at TIMESTAMPTZ DEFAULT NOW()," +
                "  UNIQUE(enquiry_ref, version_id)" +
                ")"
            );
            sce.getServletContext().log("Terms schema ready.");
        } catch (Exception e) {
            sce.getServletContext().log("Terms schema init failed (non-fatal)", e);
        }

        // Refunds table
        try (Connection c6 = Database.getConnection(); Statement st6 = c6.createStatement()) {
            st6.execute(
                "CREATE TABLE IF NOT EXISTS refunds (" +
                "  id               BIGSERIAL PRIMARY KEY," +
                "  enquiry_ref      VARCHAR(20) NOT NULL UNIQUE," +
                "  is_muhurtham     BOOLEAN NOT NULL DEFAULT FALSE," +
                "  advance_paise    BIGINT NOT NULL," +
                "  replaced_by_ref  VARCHAR(20)," +
                "  refund_pct       INT," +
                "  refund_paise     BIGINT," +
                "  status           VARCHAR(20) NOT NULL DEFAULT 'PENDING'," +
                "  processed_at     TIMESTAMPTZ," +
                "  created_at       TIMESTAMPTZ DEFAULT NOW()" +
                ")"
            );
            sce.getServletContext().log("Refunds schema ready.");
        } catch (Exception e) {
            sce.getServletContext().log("Refunds schema init failed (non-fatal)", e);
        }

        // Notification log table
        try (Connection c7 = Database.getConnection(); Statement st7 = c7.createStatement()) {
            st7.execute(
                "CREATE TABLE IF NOT EXISTS notification_log (" +
                "  id            BIGSERIAL PRIMARY KEY," +
                "  enquiry_ref   VARCHAR(20) NOT NULL," +
                "  channel       VARCHAR(20) NOT NULL," +
                "  status        VARCHAR(20) NOT NULL DEFAULT 'pending'," +
                "  attempts      INT NOT NULL DEFAULT 0," +
                "  last_error    TEXT," +
                "  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()," +
                "  sent_at       TIMESTAMPTZ," +
                "  next_retry_at TIMESTAMPTZ" +
                ")"
            );
            st7.execute(
                "CREATE INDEX IF NOT EXISTS idx_notification_retry " +
                "ON notification_log(status, next_retry_at) WHERE status='retrying'"
            );
            sce.getServletContext().log("Notification log schema ready.");
        } catch (Exception e) {
            sce.getServletContext().log("Notification log schema init failed (non-fatal)", e);
        }
    }
}
