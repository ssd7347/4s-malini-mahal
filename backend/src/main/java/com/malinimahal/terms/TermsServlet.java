package com.malinimahal.terms;

import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/** Public endpoint: GET /api/terms/current — returns the active T&C version. */
@WebServlet("/api/terms/current")
public class TermsServlet extends HttpServlet {

    private final TermsVersionDao dao = new TermsVersionDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            TermsVersion active = dao.findActive();
            if (active == null) {
                JsonSupport.error(resp, 404, "No active Terms & Conditions version found");
                return;
            }
            JsonSupport.write(resp, 200, active);
        } catch (Exception e) {
            getServletContext().log("Failed to load active T&C", e);
            JsonSupport.error(resp, 500, "Could not load Terms & Conditions");
        }
    }
}
