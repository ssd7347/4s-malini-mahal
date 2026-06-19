package com.malinimahal.auth;

import com.malinimahal.db.Database;

import java.sql.*;
import java.util.Random;

public class OtpDao {

    private static final int TTL_MINUTES = 5;
    private static final int MAX_ATTEMPTS = 3;
    private static final Random RNG = new Random();

    /** Invalidates previous live OTPs for this mobile and returns a fresh 6-digit code. */
    public String generate(String mobile) throws SQLException {
        String code = String.format("%06d", RNG.nextInt(1_000_000));
        try (Connection c = Database.getConnection()) {
            try (PreparedStatement ps = c.prepareStatement(
                    "UPDATE auth_otps SET used = TRUE WHERE mobile = ? AND used = FALSE")) {
                ps.setString(1, mobile);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = c.prepareStatement(
                    "INSERT INTO auth_otps (mobile, code, expires_at) " +
                    "VALUES (?, ?, NOW() + INTERVAL '" + TTL_MINUTES + " minutes')")) {
                ps.setString(1, mobile);
                ps.setString(2, code);
                ps.executeUpdate();
            }
        }
        return code;
    }

    /**
     * Returns true and marks the OTP used on success.
     * Returns false if the code is wrong, expired, already used, or too many attempts.
     */
    public boolean verify(String mobile, String code) throws SQLException {
        try (Connection c = Database.getConnection()) {
            long otpId = -1;
            boolean match = false;
            try (PreparedStatement ps = c.prepareStatement(
                    "SELECT id, code, attempts FROM auth_otps " +
                    "WHERE mobile = ? AND used = FALSE AND expires_at > NOW() " +
                    "ORDER BY id DESC LIMIT 1")) {
                ps.setString(1, mobile);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        if (rs.getInt("attempts") >= MAX_ATTEMPTS) return false;
                        otpId = rs.getLong("id");
                        match = rs.getString("code").equals(code);
                    }
                }
            }
            if (otpId < 0) return false;

            if (!match) {
                try (PreparedStatement ps = c.prepareStatement(
                        "UPDATE auth_otps SET attempts = attempts + 1 WHERE id = ?")) {
                    ps.setLong(1, otpId);
                    ps.executeUpdate();
                }
                return false;
            }

            try (PreparedStatement ps = c.prepareStatement(
                    "UPDATE auth_otps SET used = TRUE WHERE id = ?")) {
                ps.setLong(1, otpId);
                ps.executeUpdate();
            }
            return true;
        }
    }
}
