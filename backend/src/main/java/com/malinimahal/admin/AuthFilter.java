package com.malinimahal.admin;

import com.malinimahal.web.JsonSupport;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

/** Protects all /api/admin/* endpoints — requires authRole=ADMIN in the session. */
@WebFilter("/api/admin/*")
public class AuthFilter extends HttpFilter {

    @Override
    protected void doFilter(HttpServletRequest req, HttpServletResponse resp, FilterChain chain)
            throws IOException, ServletException {

        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) {
            chain.doFilter(req, resp);
            return;
        }

        HttpSession session = req.getSession(false);
        if (session == null || !"ADMIN".equals(session.getAttribute("authRole"))) {
            JsonSupport.error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Not authenticated");
            return;
        }

        chain.doFilter(req, resp);
    }
}
