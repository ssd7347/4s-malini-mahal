package com.malinimahal.muhurtham;

import com.malinimahal.db.Database;

import java.sql.*;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

public class MuhurthamDateDao {

    public MuhurthamDate add(LocalDate date, String note) throws SQLException {
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "INSERT INTO muhurtham_dates (mdate, note) VALUES (?, ?) RETURNING id, mdate, note, created_at")) {
            ps.setObject(1, date);
            ps.setString(2, note);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return mapRow(rs);
            }
        }
    }

    public boolean remove(LocalDate date) throws SQLException {
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement("DELETE FROM muhurtham_dates WHERE mdate = ?")) {
            ps.setObject(1, date);
            return ps.executeUpdate() > 0;
        }
    }

    public List<MuhurthamDate> listAll() throws SQLException {
        List<MuhurthamDate> out = new ArrayList<>();
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT id, mdate, note, created_at FROM muhurtham_dates ORDER BY mdate");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) out.add(mapRow(rs));
        }
        return out;
    }

    public List<LocalDate> listDatesInRange(LocalDate from, LocalDate to) throws SQLException {
        List<LocalDate> out = new ArrayList<>();
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT mdate FROM muhurtham_dates WHERE mdate BETWEEN ? AND ? ORDER BY mdate")) {
            ps.setObject(1, from);
            ps.setObject(2, to);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.add(rs.getObject("mdate", LocalDate.class));
            }
        }
        return out;
    }

    public boolean isOnMuhurtham(LocalDate date) throws SQLException {
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT EXISTS(SELECT 1 FROM muhurtham_dates WHERE mdate = ?)")) {
            ps.setObject(1, date);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getBoolean(1);
            }
        }
    }

    private static MuhurthamDate mapRow(ResultSet rs) throws SQLException {
        MuhurthamDate m = new MuhurthamDate();
        m.setId(rs.getLong("id"));
        m.setMdate(rs.getObject("mdate", LocalDate.class));
        m.setNote(rs.getString("note"));
        m.setCreatedAt(rs.getObject("created_at", OffsetDateTime.class));
        return m;
    }
}
