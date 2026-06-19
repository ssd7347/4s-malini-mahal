package com.malinimahal.terms;

import com.malinimahal.db.Database;

import java.sql.*;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

public class TermsAcceptanceDao {

    public TermsAcceptance record(String enquiryRef, String mobile, long versionId)
            throws SQLException {
        final String sql = """
                INSERT INTO terms_acceptances (enquiry_ref, mobile, version_id)
                VALUES (?, ?, ?)
                ON CONFLICT (enquiry_ref, version_id) DO UPDATE SET accepted_at = NOW()
                RETURNING id, enquiry_ref, mobile, version_id, accepted_at
                """;
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, enquiryRef);
            ps.setString(2, mobile);
            ps.setLong(3, versionId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return mapRow(rs, -1);
            }
        }
    }

    public boolean hasAccepted(String enquiryRef, long versionId) throws SQLException {
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT EXISTS(SELECT 1 FROM terms_acceptances WHERE enquiry_ref = ? AND version_id = ?)")) {
            ps.setString(1, enquiryRef);
            ps.setLong(2, versionId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getBoolean(1);
            }
        }
    }

    public List<TermsAcceptance> listByRef(String enquiryRef) throws SQLException {
        final String sql = """
                SELECT ta.id, ta.enquiry_ref, ta.mobile, ta.version_id, tv.version, ta.accepted_at
                FROM terms_acceptances ta
                JOIN terms_versions tv ON ta.version_id = tv.id
                WHERE ta.enquiry_ref = ?
                ORDER BY ta.accepted_at DESC
                """;
        List<TermsAcceptance> out = new ArrayList<>();
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, enquiryRef);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.add(mapRow(rs, rs.getInt("version")));
            }
        }
        return out;
    }

    private static TermsAcceptance mapRow(ResultSet rs, int versionNumber) throws SQLException {
        TermsAcceptance a = new TermsAcceptance();
        a.setId(rs.getLong("id"));
        a.setEnquiryRef(rs.getString("enquiry_ref"));
        a.setMobile(rs.getString("mobile"));
        a.setVersionId(rs.getLong("version_id"));
        a.setVersionNumber(versionNumber);
        a.setAcceptedAt(rs.getObject("accepted_at", OffsetDateTime.class));
        return a;
    }
}
