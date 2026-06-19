package com.malinimahal.payment;

import com.malinimahal.db.Database;

import java.sql.*;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

public class PaymentDao {

    public Payment createOrder(Payment p) throws SQLException {
        final String sql = """
                INSERT INTO payments (enquiry_ref, razorpay_order_id, amount_paise, payment_type)
                VALUES (?, ?, ?, ?)
                RETURNING id, status, created_at
                """;
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, p.getEnquiryRef());
            ps.setString(2, p.getRazorpayOrderId());
            ps.setLong(3, p.getAmountPaise());
            ps.setString(4, p.getPaymentType());
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                p.setId(rs.getLong("id"));
                p.setStatus(rs.getString("status"));
                p.setCreatedAt(rs.getObject("created_at", OffsetDateTime.class));
                return p;
            }
        }
    }

    public boolean markSuccess(String razorpayOrderId, String paymentId, String signature)
            throws SQLException {
        final String sql = """
                UPDATE payments
                SET status = 'SUCCESS', razorpay_payment_id = ?, razorpay_signature = ?
                WHERE razorpay_order_id = ?
                """;
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, paymentId);
            ps.setString(2, signature);
            ps.setString(3, razorpayOrderId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean markFailed(String razorpayOrderId) throws SQLException {
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "UPDATE payments SET status = 'FAILED' WHERE razorpay_order_id = ?")) {
            ps.setString(1, razorpayOrderId);
            return ps.executeUpdate() > 0;
        }
    }

    public List<Payment> listByRef(String enquiryRef) throws SQLException {
        final String sql = """
                SELECT id, enquiry_ref, razorpay_order_id, razorpay_payment_id,
                       amount_paise, payment_type, status, created_at
                FROM payments
                WHERE enquiry_ref = ?
                ORDER BY created_at DESC
                """;
        List<Payment> out = new ArrayList<>();
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, enquiryRef);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.add(mapRow(rs));
            }
        }
        return out;
    }

    public long getTotalPaidPaise(String enquiryRef, String paymentType) throws SQLException {
        final String sql = """
                SELECT COALESCE(SUM(amount_paise), 0)
                FROM payments
                WHERE enquiry_ref = ? AND payment_type = ? AND status = 'SUCCESS'
                """;
        try (Connection c = Database.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, enquiryRef);
            ps.setString(2, paymentType);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getLong(1);
            }
        }
    }

    private static Payment mapRow(ResultSet rs) throws SQLException {
        Payment p = new Payment();
        p.setId(rs.getLong("id"));
        p.setEnquiryRef(rs.getString("enquiry_ref"));
        p.setRazorpayOrderId(rs.getString("razorpay_order_id"));
        p.setRazorpayPaymentId(rs.getString("razorpay_payment_id"));
        p.setAmountPaise(rs.getLong("amount_paise"));
        p.setPaymentType(rs.getString("payment_type"));
        p.setStatus(rs.getString("status"));
        p.setCreatedAt(rs.getObject("created_at", OffsetDateTime.class));
        return p;
    }
}
