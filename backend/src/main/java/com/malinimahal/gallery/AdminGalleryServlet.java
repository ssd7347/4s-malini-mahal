package com.malinimahal.gallery;

import com.malinimahal.web.JsonSupport;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Admin-only gallery management. Protected by AuthFilter on /api/admin/*.
 *   POST /api/admin/gallery          — multipart: upload image or video; JSON: add YouTube video
 *   DELETE /api/admin/gallery/{id}   — remove item (deletes file on disk for images and local videos)
 */
@WebServlet("/api/admin/gallery/*")
@MultipartConfig(maxFileSize = 200L * 1024 * 1024, maxRequestSize = 210L * 1024 * 1024)
public class AdminGalleryServlet extends HttpServlet {

    private final GalleryDao dao = new GalleryDao();
    private static final Set<String> IMAGE_ALLOWED = Set.of("jpg", "jpeg", "png", "webp");
    private static final Set<String> VIDEO_ALLOWED = Set.of("mp4", "webm", "mov");

    private Path uploadDir() {
        String dir = System.getenv("UPLOAD_DIR");
        if (dir == null || dir.isBlank()) {
            dir = System.getProperty("catalina.home") + "/uploads/malinimahal";
        }
        return Path.of(dir);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        String ct = req.getContentType();
        try {
            if (ct != null && ct.startsWith("multipart/")) {
                handleFileUpload(req, resp);
            } else {
                handleYouTubeAdd(req, resp);
            }
        } catch (Exception e) {
            getServletContext().log("Gallery add failed", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not add item");
        }
    }

    private void handleFileUpload(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        Part filePart = req.getPart("file");
        if (filePart == null || filePart.getSize() == 0) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "No file provided");
            return;
        }
        String origName = filePart.getSubmittedFileName();
        if (origName == null || !origName.contains(".")) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "File must have an extension");
            return;
        }
        String ext = origName.substring(origName.lastIndexOf('.') + 1).toLowerCase();
        String mediaType;
        if (IMAGE_ALLOWED.contains(ext)) {
            mediaType = "IMAGE";
        } else if (VIDEO_ALLOWED.contains(ext)) {
            mediaType = "VIDEO";
        } else {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST,
                    "Allowed images: JPG, PNG, WebP — Allowed videos: MP4, WebM, MOV");
            return;
        }
        String filename = UUID.randomUUID() + "." + ext;
        Path dir = uploadDir();
        Files.createDirectories(dir);
        Files.copy(filePart.getInputStream(), dir.resolve(filename), StandardCopyOption.REPLACE_EXISTING);

        String title = req.getParameter("title");
        GalleryItem item = dao.add(mediaType, filename, null, title != null ? title.strip() : null);
        JsonSupport.write(resp, HttpServletResponse.SC_CREATED, item);
    }

    @SuppressWarnings("unchecked")
    private void handleYouTubeAdd(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        Map<String, String> body = JsonSupport.MAPPER.readValue(req.getInputStream(), Map.class);
        String youtubeUrl = body.get("youtubeUrl");
        String title = body.get("title");
        if (youtubeUrl == null || youtubeUrl.isBlank()) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "youtubeUrl is required");
            return;
        }
        GalleryItem item = dao.add("VIDEO", null, youtubeUrl.strip(),
                title != null ? title.strip() : null);
        JsonSupport.write(resp, HttpServletResponse.SC_CREATED, item);
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.length() < 2) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "ID required");
            return;
        }
        long id;
        try {
            id = Long.parseLong(pathInfo.substring(1));
        } catch (NumberFormatException e) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Invalid ID");
            return;
        }
        try {
            GalleryItem item = dao.findById(id);
            if (item == null) {
                JsonSupport.error(resp, HttpServletResponse.SC_NOT_FOUND, "Item not found");
                return;
            }
            dao.remove(id);
            if (item.getFilename() != null) {
                try { Files.deleteIfExists(uploadDir().resolve(item.getFilename())); }
                catch (IOException ex) { getServletContext().log("File delete failed", ex); }
            }
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (Exception e) {
            getServletContext().log("Gallery delete failed", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not delete item");
        }
    }
}
