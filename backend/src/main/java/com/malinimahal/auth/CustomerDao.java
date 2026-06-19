package com.malinimahal.auth;

import com.malinimahal.db.Database;

import java.sql.*;

public class CustomerDao {

    /** Returns the customer's DB id, creating a row if this mobile is new. */
    public long findOrCreate(String mobile) throws SQLException {
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "INSERT INTO customers (mobile) VALUES (?) " +
                     "ON CONFLICT (mobile) DO UPDATE SET mobile = EXCLUDED.mobile RETURNING id")) {
            ps.setString(1, mobile);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getLong(1);
            }
        }
        throw new SQLException("findOrCreate returned no id for " + mobile);
    }
}
