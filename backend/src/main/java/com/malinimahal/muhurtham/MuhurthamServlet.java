package com.malinimahal.muhurtham;

import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/** Public endpoint: GET /api/muhurtham — returns all muhurtham dates so the frontend can highlight them. */
@WebServlet("/api/muhurtham")
public class MuhurthamServlet extends HttpServlet {

    private final MuhurthamDateDao dao = new MuhurthamDateDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            JsonSupport.write(resp, 200, dao.listAll());
        } catch (Exception e) {
            getServletContext().log("Failed to list muhurtham dates", e);
            JsonSupport.error(resp, 500, "Could not load muhurtham dates");
        }
    }
}
