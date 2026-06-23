package com.malinimahal.enquiry;

import com.malinimahal.db.Database;
import com.malinimahal.muhurtham.MuhurthamDateDao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class EnquiryDao {

    private static final char[] CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".toCharArray();
    private static final SecureRandom RANDOM = new SecureRandom();

    public Enquiry create(Enquiry e) throws SQLException {
        final String sql = """
                INSERT INTO enquiries
                    (reference, customer_name, mobile, event_date, end_date, function_type, rental_type, message,
                     start_datetime, end_datetime, is_muhurtham, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'AWAITING_PAYMENT')
                RETURNING id, reference, status, created_at, start_datetime, end_datetime, is_muhurtham, end_date
                """;

        SQLException last = null;
        for (int attempt = 0; attempt < 5; attempt++) {
            String reference = newReference();
            try (Connection conn = Database.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, reference);
                ps.setString(2, e.getCustomerName());
                ps.setString(3, e.getMobile());
                ps.setObject(4, e.getEventDate());
                ps.setObject(5, e.getEndDate() != null ? e.getEndDate() : e.getEventDate());
                ps.setString(6, e.getFunctionType());
                ps.setString(7, e.getRentalType());
                ps.setString(8, e.getMessage());
                ps.setObject(9, e.getStartDatetime());
                ps.setObject(10, e.getEndDatetime());
                ps.setBoolean(11, e.isMuhurtham());

                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    e.setId(rs.getLong("id"));
                    e.setReference(rs.getString("reference"));
                    e.setStatus(rs.getString("status"));
                    e.setCreatedAt(rs.getObject("created_at", OffsetDateTime.class));
                    e.setStartDatetime(rs.getObject("start_datetime", OffsetDateTime.class));
                    e.setEndDatetime(rs.getObject("end_datetime", OffsetDateTime.class));
                    e.setMuhurtham(rs.getBoolean("is_muhurtham"));
                    e.setEndDate(rs.getObject("end_date", java.time.LocalDate.class));
                    return e;
                }
            } catch (SQLException ex) {
                if ("23505".equals(ex.getSQLState())) { last = ex; continue; }
                throw ex;
            }
        }
        throw last != null ? last : new SQLException("Could not generate a unique reference");
    }

    public boolean updateBilling(String reference, Double elecUnits, Double gasKg,
                                  Long decorationChargePaise, Long earlyEntryChargePaise,
                                  Long keyLossChargePaise) throws SQLException {
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE enquiries SET elec_units = ?, gas_kg = ?, decoration_charge_paise = ?," +
                     " early_entry_charge_paise = ?, key_loss_charge_paise = ? WHERE reference = ?")) {
            ps.setObject(1, elecUnits);
            ps.setObject(2, gasKg);
            ps.setObject(3, decorationChargePaise);
            ps.setObject(4, earlyEntryChargePaise);
            ps.setObject(5, keyLossChargePaise);
            ps.setString(6, reference);
            return ps.executeUpdate() > 0;
        }
    }

    public Enquiry findByReference(String reference) throws SQLException {
        final String sql = """
                SELECT id, reference, customer_name, mobile, event_date, end_date,
                       function_type, rental_type, message, status, created_at,
                       start_datetime, end_datetime,
                       elec_units, gas_kg, decoration_charge_paise,
                       early_entry_charge_paise, key_loss_charge_paise, is_muhurtham
                FROM enquiries
                WHERE reference = ?
                """;
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, reference);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                return mapRow(rs);
            }
        }
    }

    public List<Enquiry> listByMobile(String mobile) throws SQLException {
        final String sql = """
                SELECT id, reference, customer_name, mobile, event_date, end_date,
                       function_type, rental_type, message, status, created_at,
                       start_datetime, end_datetime,
                       elec_units, gas_kg, decoration_charge_paise,
                       early_entry_charge_paise, key_loss_charge_paise, is_muhurtham
                FROM enquiries
                WHERE mobile = ?
                ORDER BY created_at DESC
                """;
        List<Enquiry> out = new ArrayList<>();
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, mobile);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.add(mapRow(rs));
            }
        }
        return out;
    }

    public List<Enquiry> listAll() throws SQLException {
        final String sql = """
                SELECT id, reference, customer_name, mobile, event_date, end_date,
                       function_type, rental_type, message, status, created_at,
                       start_datetime, end_datetime,
                       elec_units, gas_kg, decoration_charge_paise,
                       early_entry_charge_paise, key_loss_charge_paise, is_muhurtham
                FROM enquiries
                ORDER BY created_at DESC
                """;
        List<Enquiry> out = new ArrayList<>();
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) out.add(mapRow(rs));
        }
        return out;
    }

    public List<String> findReferencesForAutoComplete() throws SQLException {
        List<String> refs = new ArrayList<>();
        String sql =
            "SELECT reference FROM enquiries WHERE status = 'CONFIRMED' AND (" +
            "  (rental_type IN ('HOURLY','HALF_DAY') AND end_datetime < NOW()) OR" +
            "  (rental_type = 'FULL_DAY' AND COALESCE(end_date, event_date) < CURRENT_DATE)" +
            ")";
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) refs.add(rs.getString("reference"));
        }
        return refs;
    }

    public boolean updateStatus(String reference, String status) throws SQLException {
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE enquiries SET status = ? WHERE reference = ?")) {
            ps.setString(1, status);
            ps.setString(2, reference);
            return ps.executeUpdate() > 0;
        }
    }

    /**
     * Returns true if the proposed booking conflicts with any active booking.
     *
     * Four cases:
     *   1. Both Full Day       → direct slot overlap only; consecutive FDs on adjacent dates are valid.
     *   2a. Existing FD, proposed non-FD → non-FD must start ≥ 2h after FD exits (2h cleanup gap).
     *   2b. Existing non-FD, proposed FD → non-FD must end ≤ 0h before FD's 2h prep window starts
     *                                       (blockStart = FD entry − 2h = 13:00).
     *   3. Both non-Full-Day   → 2h gap required between the two bookings.
     */
    public boolean hasConflict(String proposedRentalType,
                                OffsetDateTime proposedStart, OffsetDateTime proposedEnd,
                                String excludeReference) throws SQLException {
        // For Full Day the conflict window opens 2 h before customer entry (prep/cleaning time).
        // For non-FD this equals proposedStart (no offset).
        OffsetDateTime blockStart = "FULL_DAY".equals(proposedRentalType)
                ? proposedStart.minusHours(2) : proposedStart;

        final String sql = """
                SELECT EXISTS(
                    SELECT 1 FROM enquiries
                    WHERE status NOT IN ('CANCELLED', 'REJECTED', 'DECLINED', 'COMPLETED')
                    AND start_datetime IS NOT NULL
                    AND end_datetime IS NOT NULL
                    AND (
                        /* 1. Both FD: direct overlap — consecutive dates (exit 14:00 / entry 15:00) are fine */
                        (   rental_type = 'FULL_DAY' AND ?::text = 'FULL_DAY'
                            AND ?::timestamptz < end_datetime
                            AND start_datetime < ?::timestamptz
                        )
                        OR
                        /* 2a. Existing FD, proposed non-FD: non-FD must start ≥ 2h after FD exits */
                        (   rental_type = 'FULL_DAY' AND ?::text != 'FULL_DAY'
                            AND ?::timestamptz < end_datetime + INTERVAL '2 hours'
                            AND start_datetime - INTERVAL '2 hours' < ?::timestamptz
                        )
                        OR
                        /* 2b. Existing non-FD, proposed FD: non-FD must end by 13:00 (blockStart) */
                        (   rental_type != 'FULL_DAY' AND ?::text = 'FULL_DAY'
                            AND ?::timestamptz < end_datetime
                            AND start_datetime < ?::timestamptz
                        )
                        OR
                        /* 3. Both non-FD: 2h gap required between bookings */
                        (   rental_type != 'FULL_DAY' AND ?::text != 'FULL_DAY'
                            AND ?::timestamptz < end_datetime + INTERVAL '2 hours'
                            AND start_datetime < ?::timestamptz + INTERVAL '2 hours'
                        )
                    )
                    AND (? IS NULL OR reference != ?)
                )
                """;
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, proposedRentalType);  // Case 1: both FD
            ps.setObject(2, proposedStart);        // Case 1: proposed start < existing FD end
            ps.setObject(3, proposedEnd);          // Case 1: existing FD start < proposed end
            ps.setString(4, proposedRentalType);  // Case 2a: proposed != FULL_DAY
            ps.setObject(5, proposedStart);        // Case 2a: non-FD start < FD end + 2h
            ps.setObject(6, proposedEnd);          // Case 2a: FD setup start (entry-2h) < non-FD end
            ps.setString(7, proposedRentalType);  // Case 2b: proposed = FULL_DAY
            ps.setObject(8, blockStart);           // Case 2b: FD blockStart (entry-2h) < non-FD end
            ps.setObject(9, proposedEnd);          // Case 2b: non-FD start < FD end
            ps.setString(10, proposedRentalType); // Case 3: both non-FD
            ps.setObject(11, proposedStart);       // Case 3: proposed start < existing end + 2h
            ps.setObject(12, proposedEnd);         // Case 3: existing start < proposed end + 2h
            ps.setString(13, excludeReference);
            ps.setString(14, excludeReference);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getBoolean(1);
            }
        }
    }

    private static Enquiry mapRow(ResultSet rs) throws SQLException {
        Enquiry e = new Enquiry();
        e.setId(rs.getLong("id"));
        e.setReference(rs.getString("reference"));
        e.setCustomerName(rs.getString("customer_name"));
        e.setMobile(rs.getString("mobile"));
        e.setEventDate(rs.getObject("event_date", java.time.LocalDate.class));
        e.setEndDate(rs.getObject("end_date", java.time.LocalDate.class));
        e.setFunctionType(rs.getString("function_type"));
        e.setRentalType(rs.getString("rental_type"));
        e.setMessage(rs.getString("message"));
        e.setStatus(rs.getString("status"));
        e.setCreatedAt(rs.getObject("created_at", OffsetDateTime.class));
        e.setStartDatetime(rs.getObject("start_datetime", OffsetDateTime.class));
        e.setEndDatetime(rs.getObject("end_datetime", OffsetDateTime.class));
        e.setElecUnits((Double) rs.getObject("elec_units"));
        e.setGasKg((Double) rs.getObject("gas_kg"));
        Object decor = rs.getObject("decoration_charge_paise");
        if (decor != null) e.setDecorationChargePaise(((Number) decor).longValue());
        Object early = rs.getObject("early_entry_charge_paise");
        if (early != null) e.setEarlyEntryChargePaise(((Number) early).longValue());
        Object keyLoss = rs.getObject("key_loss_charge_paise");
        if (keyLoss != null) e.setKeyLossChargePaise(((Number) keyLoss).longValue());
        e.setMuhurtham(rs.getBoolean("is_muhurtham"));
        return e;
    }

    public boolean updateIsMuhurtham(String reference, boolean isMuhurtham) throws SQLException {
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE enquiries SET is_muhurtham = ? WHERE reference = ?")) {
            ps.setBoolean(1, isMuhurtham);
            ps.setString(2, reference);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean reschedule(String reference, LocalDate newEventDate, LocalDate newEndDate,
                               OffsetDateTime newStart, OffsetDateTime newEnd,
                               boolean newIsMuhurtham) throws SQLException {
        final String sql = """
                UPDATE enquiries
                   SET event_date = ?, end_date = ?, start_datetime = ?, end_datetime = ?, is_muhurtham = ?
                 WHERE reference = ?
                """;
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setObject(1, newEventDate);
            ps.setObject(2, newEndDate);
            ps.setObject(3, newStart);
            ps.setObject(4, newEnd);
            ps.setBoolean(5, newIsMuhurtham);
            ps.setString(6, reference);
            return ps.executeUpdate() > 0;
        }
    }

    public Map<String, Object> statsForMonth(String yearMonth) throws SQLException {
        YearMonth ym = YearMonth.parse(yearMonth);
        LocalDate firstDay = ym.atDay(1);
        LocalDate lastDay = ym.atEndOfMonth();
        int daysInMonth = ym.lengthOfMonth();
        long bookingsCount = 0, billingPaise = 0, occupiedDays = 0;
        try (Connection conn = Database.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*) FROM enquiries WHERE status IN ('CONFIRMED','COMPLETED') " +
                    "AND event_date >= ? AND event_date <= ?")) {
                ps.setObject(1, firstDay);
                ps.setObject(2, lastDay);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) bookingsCount = rs.getLong(1); }
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COALESCE(SUM(COALESCE(elec_units,0)*4000 + COALESCE(gas_kg,0)*18000 + " +
                    "COALESCE(decoration_charge_paise,0) + COALESCE(early_entry_charge_paise,0) + " +
                    "COALESCE(key_loss_charge_paise,0)),0) FROM enquiries " +
                    "WHERE status='COMPLETED' AND event_date >= ? AND event_date <= ?")) {
                ps.setObject(1, firstDay);
                ps.setObject(2, lastDay);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) billingPaise = rs.getLong(1); }
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(DISTINCT event_date) FROM enquiries WHERE status IN ('CONFIRMED','COMPLETED') " +
                    "AND event_date >= ? AND event_date <= ?")) {
                ps.setObject(1, firstDay);
                ps.setObject(2, lastDay);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) occupiedDays = rs.getLong(1); }
            }
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("bookingsCount", bookingsCount);
        result.put("billingCollectedPaise", billingPaise);
        result.put("occupiedDays", occupiedDays);
        result.put("daysInMonth", daysInMonth);
        result.put("occupancyRate", daysInMonth > 0 ? (int) Math.round(occupiedDays * 100.0 / daysInMonth) : 0);
        return result;
    }

    public List<Enquiry> listForMonth(String yearMonth) throws SQLException {
        YearMonth ym = YearMonth.parse(yearMonth);
        List<Enquiry> list = new ArrayList<>();
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT * FROM enquiries WHERE event_date >= ? AND event_date <= ? " +
                     "ORDER BY event_date, start_datetime")) {
            ps.setObject(1, ym.atDay(1));
            ps.setObject(2, ym.atEndOfMonth());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        }
        return list;
    }

    private static String newReference() {
        StringBuilder sb = new StringBuilder("MM-");
        for (int i = 0; i < 6; i++) sb.append(CODE_ALPHABET[RANDOM.nextInt(CODE_ALPHABET.length)]);
        return sb.toString();
    }
}
