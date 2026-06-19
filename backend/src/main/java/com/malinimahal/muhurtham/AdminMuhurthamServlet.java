package com.malinimahal.muhurtham;

import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.time.LocalDate;
import java.util.Map;

/**
 * Admin muhurtham date management (requires ADMIN session — enforced by AuthFilter):
 *   GET    /api/admin/muhurtham          list all
 *   POST   /api/admin/muhurtham          add date  { date, note }
 *   DELETE /api/admin/muhurtham/{date}   remove date
 */
@WebServlet(urlPatterns = {"/api/admin/muhurtham", "/api/admin/muhurtham/*"})
public class AdminMuhurthamServlet extends HttpServlet {

    private final MuhurthamDateDao dao = new MuhurthamDateDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            JsonSupport.write(resp, 200, dao.listAll());
        } catch (Exception e) {
            JsonSupport.error(resp, 500, "Could not load muhurtham dates");
        }
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Map<String, Object> body;
        try {
            body = JsonSupport.MAPPER.readValue(req.getInputStream(), Map.class);
        } catch (Exception e) {
            JsonSupport.error(resp, 400, "Invalid request body");
            return;
        }
        String dateStr = body.getOrDefault("date", "").toString().trim();
        String note    = body.getOrDefault("note", "").toString().trim();
        LocalDate date;
        try {
            date = LocalDate.parse(dateStr);
        } catch (Exception e) {
            JsonSupport.error(resp, 400, "Invalid date format (expected yyyy-MM-dd)");
            return;
        }
        try {
            MuhurthamDate added = dao.add(date, note.isBlank() ? null : note);
            JsonSupport.write(resp, 201, added);
        } catch (Exception e) {
            if (e.getMessage() != null && e.getMessage().contains("unique")) {
                JsonSupport.error(resp, 409, "This date is already marked as a muhurtham date");
            } else {
                getServletContext().log("Failed to add muhurtham date", e);
                JsonSupport.error(resp, 500, "Could not add muhurtham date");
            }
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getPathInfo();
        if (path == null || path.length() <= 1) {
            JsonSupport.error(resp, 400, "Date required in path");
            return;
        }
        String dateStr = path.substring(1);
        LocalDate date;
        try {
            date = LocalDate.parse(dateStr);
        } catch (Exception e) {
            JsonSupport.error(resp, 400, "Invalid date format");
            return;
        }
        try {
            boolean removed = dao.remove(date);
            if (!removed) {
                JsonSupport.error(resp, 404, "Muhurtham date not found");
                return;
            }
            JsonSupport.write(resp, 200, Map.of("removed", dateStr));
        } catch (Exception e) {
            JsonSupport.error(resp, 500, "Could not remove muhurtham date");
        }
    }
}
