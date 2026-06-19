package com.malinimahal.admin;

import com.malinimahal.notification.NotificationDao;
import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

@WebServlet(urlPatterns = {"/api/admin/notification-log", "/api/admin/notification-config"})
public class AdminNotificationServlet extends HttpServlet {

    private final NotificationDao dao = new NotificationDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (req.getServletPath().endsWith("/notification-config")) {
            serveConfig(resp);
        } else {
            serveLog(resp);
        }
    }

    private void serveConfig(HttpServletResponse resp) throws IOException {
        String waEnabled   = System.getenv("WA_ENABLED");
        String waToken     = System.getenv("WA_META_TOKEN");
        String waPhoneId   = System.getenv("WA_META_PHONE_ID");
        String ownerMobile = System.getenv("OWNER_MOBILE");
        String ownerEmail  = System.getenv("OWNER_EMAIL");

        boolean whatsappActive = "true".equalsIgnoreCase(waEnabled)
                              && notBlank(waToken)
                              && notBlank(waPhoneId)
                              && notBlank(ownerMobile);

        Map<String, Object> cfg = new LinkedHashMap<>();
        cfg.put("whatsappActive",  whatsappActive);
        cfg.put("ownerMobileSet",  notBlank(ownerMobile));
        cfg.put("ownerEmailSet",   notBlank(ownerEmail));
        cfg.put("waEnabledVar",    "true".equalsIgnoreCase(waEnabled));
        cfg.put("waTokenSet",      notBlank(waToken));
        cfg.put("waPhoneIdSet",    notBlank(waPhoneId));

        JsonSupport.write(resp, HttpServletResponse.SC_OK, cfg);
    }

    private void serveLog(HttpServletResponse resp) throws IOException {
        try {
            JsonSupport.write(resp, HttpServletResponse.SC_OK, dao.listRecent(50));
        } catch (Exception e) {
            getServletContext().log("Failed to load notification log", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Could not load notification log");
        }
    }

    private static boolean notBlank(String s) { return s != null && !s.isBlank(); }
}
