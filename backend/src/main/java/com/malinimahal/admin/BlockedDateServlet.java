package com.malinimahal.admin;

import com.malinimahal.blocked.BlockedDateDao;
import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Map;

/**
 * Admin blocked-date management (requires login — enforced by AuthFilter):
 *   GET    /api/admin/blocked-dates              list blocked dates
 *   POST   /api/admin/blocked-dates              {date, reason} block a date
 *   DELETE /api/admin/blocked-dates/{date}       unblock a date (yyyy-MM-dd)
 */
@WebServlet(urlPatterns = {"/api/admin/blocked-dates", "/api/admin/blocked-dates/*"})
public class BlockedDateServlet extends HttpServlet {

    private final BlockedDateDao dao = new BlockedDateDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            JsonSupport.write(resp, HttpServletResponse.SC_OK, dao.listAll());
        } catch (Exception e) {
            getServletContext().log("Failed to list blocked dates", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not load blocked dates");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Map<String, String> body;
        try {
            body = JsonSupport.MAPPER.readValue(req.getInputStream(), Map.class);
        } catch (Exception e) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Invalid request body");
            return;
        }
        LocalDate date;
        try {
            date = LocalDate.parse(body.getOrDefault("date", ""));
        } catch (DateTimeParseException e) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "A valid date (yyyy-MM-dd) is required");
            return;
        }
        String reason = body.get("reason");

        try {
            boolean added = dao.add(date, reason);
            if (!added) {
                JsonSupport.error(resp, HttpServletResponse.SC_CONFLICT, "That date is already blocked");
                return;
            }
            JsonSupport.write(resp, HttpServletResponse.SC_CREATED, Map.of("date", date.toString()));
        } catch (Exception e) {
            getServletContext().log("Failed to block date", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not block the date");
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getPathInfo();
        if (path == null || path.length() <= 1) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing date");
            return;
        }
        LocalDate date;
        try {
            date = LocalDate.parse(path.substring(1));
        } catch (DateTimeParseException e) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Invalid date format (use yyyy-MM-dd)");
            return;
        }
        try {
            boolean removed = dao.remove(date);
            if (!removed) {
                JsonSupport.error(resp, HttpServletResponse.SC_NOT_FOUND, "That date was not blocked");
                return;
            }
            JsonSupport.write(resp, HttpServletResponse.SC_OK, Map.of("date", date.toString(), "status", "unblocked"));
        } catch (Exception e) {
            getServletContext().log("Failed to unblock date", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not unblock the date");
        }
    }
}
