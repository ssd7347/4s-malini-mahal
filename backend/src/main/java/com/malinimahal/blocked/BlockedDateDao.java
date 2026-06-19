package com.malinimahal.blocked;

import com.malinimahal.db.Database;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class BlockedDateDao {

    public List<BlockedDate> listAll() throws SQLException {
        final String sql = "SELECT id, blocked_date, reason, created_at FROM blocked_dates ORDER BY blocked_date";
        List<BlockedDate> out = new ArrayList<>();
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                BlockedDate b = new BlockedDate();
                b.setId(rs.getLong("id"));
                b.setBlockedDate(rs.getObject("blocked_date", LocalDate.class));
                b.setReason(rs.getString("reason"));
                b.setCreatedAt(rs.getObject("created_at", java.time.OffsetDateTime.class));
                out.add(b);
            }
        }
        return out;
    }

    /** Adds a blocked date. Returns false if the date is already blocked. */
    public boolean add(LocalDate date, String reason) throws SQLException {
        final String sql = "INSERT INTO blocked_dates (blocked_date, reason) VALUES (?, ?) "
                + "ON CONFLICT (blocked_date) DO NOTHING";
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setObject(1, date);
            ps.setString(2, reason);
            return ps.executeUpdate() > 0;
        }
    }

    /** Removes a blocked date. Returns true if a row was removed. */
    public boolean remove(LocalDate date) throws SQLException {
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement("DELETE FROM blocked_dates WHERE blocked_date = ?")) {
            ps.setObject(1, date);
            return ps.executeUpdate() > 0;
        }
    }
}
