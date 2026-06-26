package com.malinimahal.gallery;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
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

    private static final Cloudinary CLOUDINARY;
    static {
        String url = System.getenv("CLOUDINARY_URL");
        CLOUDINARY = (url != null && !url.isBlank()) ? new Cloudinary(url) : null;
    }

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
        String title = req.getParameter("title");
        String storedFilename;
        if (CLOUDINARY != null) {
            byte[] fileBytes = filePart.getInputStream().readAllBytes();
            @SuppressWarnings("unchecked")
            Map<String, Object> result = CLOUDINARY.uploader().upload(
                fileBytes,
                ObjectUtils.asMap(
                    "folder", "malinimahal",
                    "resource_type", VIDEO_ALLOWED.contains(ext) ? "video" : "image"
                )
            );
            storedFilename = (String) result.get("secure_url");
        } else {
            storedFilename = UUID.randomUUID() + "." + ext;
            Path dir = uploadDir();
            Files.createDirectories(dir);
            Files.copy(filePart.getInputStream(), dir.resolve(storedFilename), StandardCopyOption.REPLACE_EXISTING);
        }
        GalleryItem item = dao.add(mediaType, storedFilename, null, title != null ? title.strip() : null);
        JsonSupport.write(resp, HttpServletResponse.SC_CREATED, item);
    }

    private static String cloudinaryPublicId(String url) {
        int idx = url.indexOf("/upload/");
        if (idx < 0) return url;
        String after = url.substring(idx + "/upload/".length());
        if (after.matches("v\\d+/.*")) after = after.substring(after.indexOf('/') + 1);
        int dot = after.lastIndexOf('.');
        return dot >= 0 ? after.substring(0, dot) : after;
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

    /** PATCH /api/admin/gallery/{id}  body: {"homeSlot": 1}  or {"homeSlot": null} */
    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp)
            throws jakarta.servlet.ServletException, IOException {
        if ("PATCH".equalsIgnoreCase(req.getMethod())) {
            handlePatch(req, resp);
        } else {
            super.service(req, resp);
        }
    }

    @SuppressWarnings("unchecked")
    private void handlePatch(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.length() < 2) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "ID required");
            return;
        }
        long id;
        try { id = Long.parseLong(pathInfo.substring(1)); }
        catch (NumberFormatException e) { JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Invalid ID"); return; }
        try {
            Map<String, Object> body = JsonSupport.MAPPER.readValue(req.getInputStream(), Map.class);
            Object slotVal = body.get("homeSlot");
            Integer slot = (slotVal == null) ? null : ((Number) slotVal).intValue();
            if (slot != null && (slot < 1 || slot > 4)) {
                JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "homeSlot must be 1–4 or null");
                return;
            }
            // If setting a slot, clear any other image already in that slot first
            if (slot != null) {
                for (GalleryItem other : dao.listAll()) {
                    if (slot.equals(other.getHomeSlot()) && other.getId() != id) {
                        dao.setHomeSlot(other.getId(), null);
                    }
                }
            }
            dao.setHomeSlot(id, slot);
            GalleryItem item = dao.findById(id);
            JsonSupport.write(resp, HttpServletResponse.SC_OK, item);
        } catch (Exception e) {
            getServletContext().log("Gallery patch failed", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not update item");
        }
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
                if (item.getFilename().startsWith("https://") && CLOUDINARY != null) {
                    try {
                        String publicId = cloudinaryPublicId(item.getFilename());
                        String rtype = "VIDEO".equals(item.getMediaType()) ? "video" : "image";
                        CLOUDINARY.uploader().destroy(publicId, ObjectUtils.asMap("resource_type", rtype));
                    } catch (Exception ex) { getServletContext().log("Cloudinary delete failed", ex); }
                } else {
                    try { Files.deleteIfExists(uploadDir().resolve(item.getFilename())); }
                    catch (IOException ex) { getServletContext().log("File delete failed", ex); }
                }
            }
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (Exception e) {
            getServletContext().log("Gallery delete failed", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not delete item");
        }
    }
}
