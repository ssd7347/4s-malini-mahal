package com.malinimahal.refund;

import com.malinimahal.db.Database;

import java.sql.*;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

public class RefundDao {

    public Refund create(String enquiryRef, boolean isMuhurtham, long advancePaise)
            throws SQLException {
        // T&C Rule 6: muhurtham/special day cancellation = 0% refund always.
        // Non-muhurtham cancellation = 100% refund (T&C is silent, no penalty permitted).
        int refundPct = isMuhurtham ? 0 : 100;
        long refundPaise = advancePaise * refundPct / 100;
        final String sql = """
                INSERT INTO refunds (enquiry_ref, is_muhurtham, advance_paise, refund_pct, refund_paise)
                VALUES (?, ?, ?, ?, ?)
                ON CONFLICT (enquiry_ref) DO UPDATE
                  SET is_muhurtham = EXCLUDED.is_muhurtham,
                      advance_paise = EXCLUDED.advance_paise,
                      refund_pct = EXCLUDED.refund_pct,
                      refund_paise = EXCLUDED.refund_paise,
                      status = 'PENDING'
                RETURNING id, enquiry_ref, is_muhurtham, advance_paise, replaced_by_ref,
                          refund_pct, refund_paise, status, processed_at, created_at
                """;
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, enquiryRef);
            ps.setBoolean(2, isMuhurtham);
            ps.setLong(3, advancePaise);
            ps.setInt(4, refundPct);
            ps.setLong(5, refundPaise);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return mapRow(rs);
            }
        }
    }

    /** Called when a new booking takes the same slot as a cancelled booking → 100% refund. */
    public boolean markReplaced(String cancelledRef, String replacementRef) throws SQLException {
        final String sql = """
                UPDATE refunds
                SET replaced_by_ref = ?, refund_pct = 100, refund_paise = advance_paise
                WHERE enquiry_ref = ? AND status = 'PENDING'
                """;
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, replacementRef);
            ps.setString(2, cancelledRef);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean markProcessed(long id) throws SQLException {
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "UPDATE refunds SET status = 'PROCESSED', processed_at = NOW() WHERE id = ?")) {
            ps.setLong(1, id);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean markDenied(long id) throws SQLException {
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "UPDATE refunds SET status = 'DENIED' WHERE id = ?")) {
            ps.setLong(1, id);
            return ps.executeUpdate() > 0;
        }
    }

    public List<Refund> listAll() throws SQLException {
        List<Refund> out = new ArrayList<>();
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT * FROM refunds ORDER BY created_at DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) out.add(mapRow(rs));
        }
        return out;
    }

    /** Find PENDING refunds for cancelled bookings whose slot overlaps with a new confirmed booking. */
    public List<String> findOverlappingPendingRefs(OffsetDateTime newStart, OffsetDateTime newEnd)
            throws SQLException {
        final String sql = """
                SELECT r.enquiry_ref
                FROM refunds r
                JOIN enquiries e ON e.reference = r.enquiry_ref
                WHERE r.status = 'PENDING'
                  AND e.status = 'CANCELLED'
                  AND e.start_datetime IS NOT NULL
                  AND e.end_datetime IS NOT NULL
                  AND ? < e.end_datetime + INTERVAL '1 hour'
                  AND ? + INTERVAL '1 hour' > e.start_datetime
                """;
        List<String> out = new ArrayList<>();
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setObject(1, newStart);
            ps.setObject(2, newEnd);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.add(rs.getString("enquiry_ref"));
            }
        }
        return out;
    }

    private static Refund mapRow(ResultSet rs) throws SQLException {
        Refund r = new Refund();
        r.setId(rs.getLong("id"));
        r.setEnquiryRef(rs.getString("enquiry_ref"));
        r.setMuhurtham(rs.getBoolean("is_muhurtham"));
        r.setAdvancePaise(rs.getLong("advance_paise"));
        r.setReplacedByRef(rs.getString("replaced_by_ref"));
        Object pct = rs.getObject("refund_pct");
        if (pct != null) r.setRefundPct(((Number) pct).intValue());
        Object rp = rs.getObject("refund_paise");
        if (rp != null) r.setRefundPaise(((Number) rp).longValue());
        r.setStatus(rs.getString("status"));
        r.setProcessedAt(rs.getObject("processed_at", OffsetDateTime.class));
        r.setCreatedAt(rs.getObject("created_at", OffsetDateTime.class));
        return r;
    }
}
