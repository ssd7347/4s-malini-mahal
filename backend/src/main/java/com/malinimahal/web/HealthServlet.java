package com.malinimahal.web;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.malinimahal.db.Database;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Health-check endpoint: GET /api/health
 *
 * Returns {"status":"ok","database":"up"} if the app is running and can reach
 * PostgreSQL. Useful to confirm the whole chain (Tomcat -> app -> DB) works
 * before building real features.
 */
@WebServlet(urlPatterns = "/api/health")
public class HealthServlet extends HttpServlet {

    private final ObjectMapper json = new ObjectMapper();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("status", "ok");
        body.put("service", "4S Malini Mahal");

        try (Connection ignored = Database.getConnection()) {
            body.put("database", "up");
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            body.put("database", "down");
            body.put("error", e.getMessage());
        }

        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        json.writeValue(resp.getWriter(), body);
    }
}
