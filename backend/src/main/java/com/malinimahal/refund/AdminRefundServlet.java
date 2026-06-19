package com.malinimahal.refund;

import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.Map;

/**
 * Admin refund management (requires ADMIN session):
 *   GET  /api/admin/refunds              list all refund records
 *   POST /api/admin/refunds/{id}/process mark as PROCESSED
 *   POST /api/admin/refunds/{id}/deny    mark as DENIED
 */
@WebServlet(urlPatterns = {"/api/admin/refunds", "/api/admin/refunds/*"})
public class AdminRefundServlet extends HttpServlet {

    private final RefundDao dao = new RefundDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            JsonSupport.write(resp, 200, dao.listAll());
        } catch (Exception e) {
            JsonSupport.error(resp, 500, "Could not load refunds");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getPathInfo();
        if (path == null) { JsonSupport.error(resp, 404, "Not found"); return; }
        long id;
        try { id = Long.parseLong(path.replaceAll("[^0-9]", "")); }
        catch (NumberFormatException e) { JsonSupport.error(resp, 400, "Invalid ID"); return; }

        try {
            if (path.endsWith("/process")) {
                boolean ok = dao.markProcessed(id);
                if (!ok) { JsonSupport.error(resp, 404, "Refund not found"); return; }
                JsonSupport.write(resp, 200, Map.of("id", id, "status", "PROCESSED"));
            } else if (path.endsWith("/deny")) {
                boolean ok = dao.markDenied(id);
                if (!ok) { JsonSupport.error(resp, 404, "Refund not found"); return; }
                JsonSupport.write(resp, 200, Map.of("id", id, "status", "DENIED"));
            } else {
                JsonSupport.error(resp, 404, "Unknown action");
            }
        } catch (Exception e) {
            JsonSupport.error(resp, 500, "Could not update refund");
        }
    }
}
