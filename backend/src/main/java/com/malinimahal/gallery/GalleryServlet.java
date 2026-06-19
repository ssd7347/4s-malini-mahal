package com.malinimahal.gallery;

import com.malinimahal.web.JsonSupport;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/** Public endpoint — no auth required. */
@WebServlet("/api/gallery")
public class GalleryServlet extends HttpServlet {

    private final GalleryDao dao = new GalleryDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            JsonSupport.write(resp, HttpServletResponse.SC_OK, dao.listAll());
        } catch (Exception e) {
            getServletContext().log("Gallery list failed", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not load gallery");
        }
    }
}
