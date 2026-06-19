package com.malinimahal.admin;

import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.Map;

/**
 * Legacy admin auth endpoints kept for the admin portal.
 * Login now happens via POST /api/auth/otp/verify (OtpServlet).
 *
 *   GET  /api/admin/me      → {role, mobile} — protected by AuthFilter (ADMIN only)
 *   POST /api/admin/logout  → end the session
 */
@WebServlet(urlPatterns = {"/api/admin/me", "/api/admin/logout"})
public class AdminAuthServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        // Only reached past AuthFilter, so session.authRole == "ADMIN".
        HttpSession session = req.getSession(false);
        String mobile = session == null ? "" : (String) session.getAttribute("authMobile");
        JsonSupport.write(resp, HttpServletResponse.SC_OK,
                Map.of("role", "ADMIN", "mobile", mobile == null ? "" : mobile));
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session != null) session.invalidate();
        JsonSupport.write(resp, HttpServletResponse.SC_OK, Map.of("status", "logged_out"));
    }
}
