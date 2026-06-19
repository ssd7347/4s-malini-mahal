package com.malinimahal.gallery;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;

/** Serves uploaded gallery images and videos. GET /api/media/{filename} */
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
            case "mp4"         -> "video/mp4";
            case "webm"        -> "video/webm";
            case "mov"         -> "video/quicktime";
            default            -> "application/octet-stream";
        };

        long fileSize = Files.size(file);
        resp.setHeader("Accept-Ranges", "bytes");
        resp.setHeader("Cache-Control", "public, max-age=86400");

        String rangeHeader = req.getHeader("Range");
        if (rangeHeader != null && rangeHeader.startsWith("bytes=")) {
            String range = rangeHeader.substring("bytes=".length());
            String[] parts = range.split("-", 2);
            long start = Long.parseLong(parts[0]);
            long end   = (parts.length > 1 && !parts[1].isEmpty())
                          ? Long.parseLong(parts[1]) : fileSize - 1;
            if (end >= fileSize) end = fileSize - 1;
            long contentLength = end - start + 1;

            resp.setStatus(HttpServletResponse.SC_PARTIAL_CONTENT);
            resp.setContentType(contentType);
            resp.setHeader("Content-Range", "bytes " + start + "-" + end + "/" + fileSize);
            resp.setContentLengthLong(contentLength);

            try (InputStream is = Files.newInputStream(file)) {
                is.skip(start);
                byte[] buf = new byte[65536];
                long remaining = contentLength;
                int read;
                OutputStream out = resp.getOutputStream();
                while (remaining > 0 &&
                       (read = is.read(buf, 0, (int) Math.min(buf.length, remaining))) != -1) {
                    out.write(buf, 0, read);
                    remaining -= read;
                }
            }
        } else {
            resp.setContentType(contentType);
            resp.setContentLengthLong(fileSize);
            Files.copy(file, resp.getOutputStream());
        }
    }
}
