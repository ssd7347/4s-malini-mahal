package com.malinimahal.gallery;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/** Serves uploaded gallery images. GET /api/media/{filename} */
@WebServlet("/api/media/*")
public class MediaServlet extends HttpServlet {

    private Path uploadDir() {
        String dir = System.getenv("UPLOAD_DIR");
        if (dir == null || dir.isBlank()) {
            dir = System.getProperty("catalina.home") + "/uploads/malinimahal";
        }
        return Path.of(dir);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.length() < 2) {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        // getFileName() prevents path-traversal attacks
        String filename = Path.of(pathInfo.substring(1)).getFileName().toString();
        Path file = uploadDir().resolve(filename);

        if (!Files.exists(file) || !Files.isRegularFile(file)) {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        String ext = filename.contains(".")
                ? filename.substring(filename.lastIndexOf('.') + 1).toLowerCase()
                : "";
        String contentType = switch (ext) {
            case "jpg", "jpeg" -> "image/jpeg";
            case "png"         -> "image/png";
            case "webp"        -> "image/webp";
            default            -> "application/octet-stream";
        };

        resp.setContentType(contentType);
        resp.setHeader("Cache-Control", "public, max-age=86400");
        resp.setContentLengthLong(Files.size(file));
        Files.copy(file, resp.getOutputStream());
    }
}
