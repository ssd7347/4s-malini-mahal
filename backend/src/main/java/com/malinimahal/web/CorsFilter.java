package com.malinimahal.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * Allows the Ember dev server (a different origin during development) to call
 * the API. The allowed origin defaults to the Ember dev server and can be
 * overridden with the CORS_ORIGIN environment variable. In production, when
 * the frontend is served from the same origin, CORS is not needed but these
 * headers are harmless.
 */
@WebFilter("/api/*")
public class CorsFilter extends HttpFilter {

    private String allowedOrigin;

    @Override
    public void init() {
        String env = System.getenv("CORS_ORIGIN");
        allowedOrigin = (env != null && !env.isBlank()) ? env : "http://localhost:4200";
    }

    @Override
    protected void doFilter(HttpServletRequest req, HttpServletResponse resp, FilterChain chain)
            throws IOException, ServletException {

        resp.setHeader("Access-Control-Allow-Origin", allowedOrigin);
        resp.setHeader("Vary", "Origin");
        resp.setHeader("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers", "Content-Type");
        // Allow the admin session cookie to be sent on cross-origin (dev: :4200 -> :8080) requests.
        resp.setHeader("Access-Control-Allow-Credentials", "true");
        resp.setHeader("Access-Control-Max-Age", "3600");

        // Answer CORS preflight requests directly.
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) {
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
            return;
        }

        chain.doFilter(req, resp);
    }
}
