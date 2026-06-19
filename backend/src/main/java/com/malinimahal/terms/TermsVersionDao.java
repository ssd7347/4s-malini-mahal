package com.malinimahal.terms;

import com.malinimahal.db.Database;

import java.sql.*;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

public class TermsVersionDao {

    public TermsVersion create(String tamilText, String englishText, String imageFilename)
            throws SQLException {
        final String sql = """
                INSERT INTO terms_versions (version, tamil_text, english_text, image_filename)
                VALUES (
                    COALESCE((SELECT MAX(version) FROM terms_versions), 0) + 1,
                    ?, ?, ?
                )
                RETURNING id, version, tamil_text, english_text, image_filename, is_active, created_at
                """;
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, tamilText);
            ps.setString(2, englishText);
            ps.setString(3, imageFilename);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return mapRow(rs);
            }
        }
    }

    public TermsVersion updateTranslation(long id, String englishText) throws SQLException {
        final String sql = """
                UPDATE terms_versions SET english_text = ? WHERE id = ?
                RETURNING id, version, tamil_text, english_text, image_filename, is_active, created_at
                """;
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, englishText);
            ps.setLong(2, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                return mapRow(rs);
            }
        }
    }

    public boolean activate(long id) throws SQLException {
        try (Connection c = Database.getConnection()) {
            c.setAutoCommit(false);
            try {
                try (PreparedStatement ps1 = c.prepareStatement(
                        "UPDATE terms_versions SET is_active = FALSE")) {
                    ps1.executeUpdate();
                }
                try (PreparedStatement ps2 = c.prepareStatement(
                        "UPDATE terms_versions SET is_active = TRUE WHERE id = ?")) {
                    ps2.setLong(1, id);
                    int rows = ps2.executeUpdate();
                    c.commit();
                    return rows > 0;
                }
            } catch (SQLException e) {
                c.rollback();
                throw e;
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    public TermsVersion findActive() throws SQLException {
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT id, version, tamil_text, english_text, image_filename, is_active, created_at FROM terms_versions WHERE is_active = TRUE LIMIT 1");
             ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) return null;
            return mapRow(rs);
        }
    }

    public TermsVersion findById(long id) throws SQLException {
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT id, version, tamil_text, english_text, image_filename, is_active, created_at FROM terms_versions WHERE id = ?")) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                return mapRow(rs);
            }
        }
    }

    public List<TermsVersion> listAll() throws SQLException {
        List<TermsVersion> out = new ArrayList<>();
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT id, version, tamil_text, english_text, image_filename, is_active, created_at FROM terms_versions ORDER BY version DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) out.add(mapRow(rs));
        }
        return out;
    }

    private static TermsVersion mapRow(ResultSet rs) throws SQLException {
        TermsVersion v = new TermsVersion();
        v.setId(rs.getLong("id"));
        v.setVersion(rs.getInt("version"));
        v.setTamilText(rs.getString("tamil_text"));
        v.setEnglishText(rs.getString("english_text"));
        v.setImageFilename(rs.getString("image_filename"));
        v.setActive(rs.getBoolean("is_active"));
        v.setCreatedAt(rs.getObject("created_at", OffsetDateTime.class));
        return v;
    }
}
