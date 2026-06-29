package com.malinimahal.auth;

import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Unified OTP authentication for customers and admin:
 *   POST /api/auth/otp/send    {mobile}       → generate OTP, send via WhatsApp
 *   POST /api/auth/otp/verify  {mobile, code} → verify OTP, create session
 *   GET  /api/auth/me                          → {role, mobile} or 401
 *   POST /api/auth/logout                      → clear session
 *
 * Session attributes set on success:
 *   authRole       = "ADMIN" | "CUSTOMER"
 *   authMobile     = mobile number string
 *   authCustomerId = customer DB id (CUSTOMER only)
 */
@WebServlet(urlPatterns = {
    "/api/auth/otp/send",
    "/api/auth/otp/verify",
    "/api/auth/me",
    "/api/auth/logout"
})
public class OtpServlet extends HttpServlet {

    public static final String ATTR_ROLE      = "authRole";
    public static final String ATTR_MOBILE    = "authMobile";
    public static final String ATTR_CUST_ID   = "authCustomerId";

    private static final int OTP_TTL_MINUTES = 2;

    private static final String ADMIN_MOBILE =
            System.getenv().getOrDefault("ADMIN_MOBILE", "9443380023");

    // Only return devOtp in the response if DEV_MODE=true is explicitly set.
    // In production with a working SMS provider this never fires; but if SMS fails
    // in prod without this guard, the OTP would be visible in the browser network tab.
    private static final boolean DEV_MODE =
            "true".equalsIgnoreCase(System.getenv("DEV_MODE"));

    // Rate limiting: max 3 OTP requests per mobile per 10 minutes.
    private static final int RATE_LIMIT_MAX     = 3;
    private static final long RATE_LIMIT_WINDOW = 10 * 60 * 1000L; // 10 minutes in ms

    private record RateEntry(AtomicInteger count, long windowStart) {}
    private final ConcurrentHashMap<String, RateEntry> rateLimits = new ConcurrentHashMap<>();

    private final OtpDao      otpDao      = new OtpDao();
    private final CustomerDao customerDao = new CustomerDao();

    // ── GET /api/auth/me ──────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute(ATTR_ROLE) == null) {
            JsonSupport.error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Not logged in");
            return;
        }
        Map<String, Object> body = new HashMap<>();
        body.put("role",   session.getAttribute(ATTR_ROLE));
        body.put("mobile", session.getAttribute(ATTR_MOBILE));
        JsonSupport.write(resp, HttpServletResponse.SC_OK, body);
    }

    // ── POST dispatch ─────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getServletPath();
        if      (path.endsWith("/send"))   sendOtp(req, resp);
        else if (path.endsWith("/verify")) verifyOtp(req, resp);
        else if (path.endsWith("/logout")) logout(req, resp);
        else JsonSupport.error(resp, HttpServletResponse.SC_NOT_FOUND, "Unknown endpoint");
    }

    // ── Send OTP ──────────────────────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private void sendOtp(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Map<String, Object> body = (Map<String, Object>) parseBody(req, resp);
        if (body == null) return;

        String mobile = body.getOrDefault("mobile", "").toString().trim();
        if (!mobile.matches("[6-9]\\d{9}")) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST,
                    "Enter a valid 10-digit Indian mobile number");
            return;
        }

        // Rate limit: max 3 OTP requests per mobile per 10-minute window.
        if (!checkRateLimit(mobile)) {
            JsonSupport.error(resp, 429,
                    "Too many OTP requests. Please wait 10 minutes before trying again.");
            return;
        }

        String code;
        try {
            code = otpDao.generate(mobile);
        } catch (Exception e) {
            getServletContext().log("OTP generation failed", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not generate OTP");
            return;
        }

        boolean sent = SmsSender.send(mobile, code);

        Map<String, Object> result = new HashMap<>();
        result.put("sent", true);
        if (!sent) {
            if (DEV_MODE) {
                // Dev mode only: return OTP for testing without a real SMS provider.
                result.put("devOtp", code);
            } else {
                // Production: SMS failed — tell user to try again rather than exposing OTP.
                JsonSupport.error(resp, HttpServletResponse.SC_SERVICE_UNAVAILABLE,
                        "Could not send OTP. Please try again in a moment.");
                return;
            }
        }
        JsonSupport.write(resp, HttpServletResponse.SC_OK, result);
    }

    private boolean checkRateLimit(String mobile) {
        long now = Instant.now().toEpochMilli();
        RateEntry entry = rateLimits.compute(mobile, (k, existing) -> {
            if (existing == null || (now - existing.windowStart()) >= RATE_LIMIT_WINDOW) {
                return new RateEntry(new AtomicInteger(1), now);
            }
            existing.count().incrementAndGet();
            return existing;
        });
        return entry.count().get() <= RATE_LIMIT_MAX;
    }

    // ── Verify OTP ────────────────────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private void verifyOtp(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Map<String, Object> body = (Map<String, Object>) parseBody(req, resp);
        if (body == null) return;

        String mobile = body.getOrDefault("mobile", "").toString().trim();
        String code   = body.getOrDefault("code",   "").toString().trim();

        if (mobile.isBlank() || code.isBlank()) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Mobile and code are required");
            return;
        }

        boolean ok;
        try {
            ok = otpDao.verify(mobile, code);
        } catch (Exception e) {
            getServletContext().log("OTP verify failed", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Verification error");
            return;
        }

        if (!ok) {
            JsonSupport.error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Invalid or expired OTP");
            return;
        }

        boolean isAdmin = ADMIN_MOBILE.equals(mobile);
        String role = isAdmin ? "ADMIN" : "CUSTOMER";

        HttpSession old = req.getSession(false);
        if (old != null) old.invalidate();
        HttpSession session = req.getSession(true);
        session.setAttribute(ATTR_ROLE,   role);
        session.setAttribute(ATTR_MOBILE, mobile);

        if (!isAdmin) {
            try {
                session.setAttribute(ATTR_CUST_ID, customerDao.findOrCreate(mobile));
            } catch (Exception e) {
                getServletContext().log("Could not create customer record", e);
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("role",   role);
        result.put("mobile", mobile);
        JsonSupport.write(resp, HttpServletResponse.SC_OK, result);
    }

    // ── Logout ────────────────────────────────────────────────────────────────

    private void logout(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session != null) session.invalidate();
        JsonSupport.write(resp, HttpServletResponse.SC_OK, Map.of("status", "logged_out"));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Map<?, ?> parseBody(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> m = JsonSupport.MAPPER.readValue(req.getInputStream(), Map.class);
            return m;
        } catch (Exception e) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Invalid JSON body");
            return null;
        }
    }
}
