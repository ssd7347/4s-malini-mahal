package com.malinimahal.notification;

import com.malinimahal.db.Database;

import java.sql.*;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class NotificationDao {

    public record NotificationRetry(long id, String enquiryRef, String channel) {}

    /** Inserts a 'pending' row and returns its generated id. */
    public long insertPending(String enquiryRef, String channel) throws SQLException {
        String sql = "INSERT INTO notification_log (enquiry_ref, channel, status) VALUES (?, ?, 'pending') RETURNING id";
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, enquiryRef);
            ps.setString(2, channel);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getLong(1);
            }
        }
    }

    public void markSent(long id) throws SQLException {
        String sql = "UPDATE notification_log SET status='sent', sent_at=NOW(), attempts=attempts+1, last_error=NULL WHERE id=?";
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.executeUpdate();
        }
    }

    public void markFailed(long id, String error, OffsetDateTime nextRetryAt) throws SQLException {
        String status = nextRetryAt != null ? "retrying" : "failed";
        String sql = "UPDATE notification_log SET status=?, attempts=attempts+1, last_error=?, next_retry_at=? WHERE id=?";
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, status);
            String trimmed = (error != null && error.length() > 500) ? error.substring(0, 500) : error;
            ps.setString(2, trimmed);
            if (nextRetryAt != null) {
                ps.setObject(3, nextRetryAt);
            } else {
                ps.setNull(3, Types.OTHER);
            }
            ps.setLong(4, id);
            ps.executeUpdate();
        }
    }

    /** Returns log rows due for retry with fewer than maxAttempts total attempts. */
    public List<NotificationRetry> findDueRetries(int maxAttempts) throws SQLException {
        String sql = "SELECT id, enquiry_ref, channel FROM notification_log "
            + "WHERE status='retrying' AND next_retry_at <= NOW() AND attempts < ? "
            + "ORDER BY next_retry_at LIMIT 100";
        List<NotificationRetry> list = new ArrayList<>();
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, maxAttempts);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new NotificationRetry(rs.getLong(1), rs.getString(2), rs.getString(3)));
                }
            }
        }
        return list;
    }

    public int getAttempts(long id) throws SQLException {
        String sql = "SELECT attempts FROM notification_log WHERE id=?";
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    /** Returns the most recent notification log rows for the admin dashboard. */
    public List<Map<String, Object>> listRecent(int limit) throws SQLException {
        String sql = "SELECT id, enquiry_ref, channel, status, attempts, last_error, sent_at "
                   + "FROM notification_log ORDER BY id DESC LIMIT ?";
        List<Map<String, Object>> out = new ArrayList<>();
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("id",         rs.getLong("id"));
                    row.put("enquiryRef", rs.getString("enquiry_ref"));
                    row.put("channel",    rs.getString("channel"));
                    row.put("status",     rs.getString("status"));
                    row.put("attempts",   rs.getInt("attempts"));
                    row.put("lastError",  rs.getString("last_error"));
                    OffsetDateTime sentAt = rs.getObject("sent_at", OffsetDateTime.class);
                    row.put("sentAt", sentAt != null ? sentAt.toString() : null);
                    out.add(row);
                }
            }
        }
        return out;
    }
}
