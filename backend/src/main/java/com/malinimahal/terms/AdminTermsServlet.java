package com.malinimahal.terms;

import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.time.Duration;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

/**
 * Admin Terms & Conditions management (requires ADMIN session):
 *   GET    /api/admin/terms/versions                list all
 *   POST   /api/admin/terms/versions                create new version (multipart: tamilText, englishText, file?)
 *   POST   /api/admin/terms/versions/{id}/translate trigger Google Translate → fill englishText
 *   POST   /api/admin/terms/versions/{id}/activate  make this version active
 *   GET    /api/admin/terms/acceptances/{ref}        list acceptances for a booking
 */
@WebServlet(urlPatterns = {"/api/admin/terms/versions", "/api/admin/terms/versions/*",
                            "/api/admin/terms/acceptances", "/api/admin/terms/acceptances/*"})
@MultipartConfig(maxFileSize = 10 * 1024 * 1024)
public class AdminTermsServlet extends HttpServlet {

    private static final String GOOGLE_TRANSLATE_KEY = System.getenv("GOOGLE_TRANSLATE_KEY");
    private static final String GOOGLE_VISION_KEY    = System.getenv("GOOGLE_VISION_KEY");
    private static final String UPLOAD_DIR;

    static {
        String catHome = System.getProperty("catalina.home", ".");
        UPLOAD_DIR = catHome + "/uploads/terms/";
        try { Files.createDirectories(Path.of(UPLOAD_DIR)); } catch (IOException ignore) {}
    }

    private final TermsVersionDao    versionDao    = new TermsVersionDao();
    private final TermsAcceptanceDao acceptanceDao = new TermsAcceptanceDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getServletPath() + (req.getPathInfo() != null ? req.getPathInfo() : "");
        if (path.contains("/acceptances/")) {
            String ref = req.getPathInfo().substring(1);
            try {
                JsonSupport.write(resp, 200, acceptanceDao.listByRef(ref));
            } catch (Exception e) {
                JsonSupport.error(resp, 500, "Could not load acceptances");
            }
        } else {
            try {
                JsonSupport.write(resp, 200, versionDao.listAll());
            } catch (Exception e) {
                JsonSupport.error(resp, 500, "Could not list T&C versions");
            }
        }
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getPathInfo() != null ? req.getPathInfo() : "";

        if (path.endsWith("/translate")) {
            long id = parseId(path.replace("/translate", ""));
            if (id <= 0) { JsonSupport.error(resp, 400, "Invalid version ID"); return; }
            translate(resp, id);
        } else if (path.endsWith("/activate")) {
            long id = parseId(path.replace("/activate", ""));
            if (id <= 0) { JsonSupport.error(resp, 400, "Invalid version ID"); return; }
            try {
                boolean ok = versionDao.activate(id);
                if (!ok) { JsonSupport.error(resp, 404, "Version not found"); return; }
                JsonSupport.write(resp, 200, Map.of("activated", id));
            } catch (Exception e) {
                JsonSupport.error(resp, 500, "Could not activate version");
            }
        } else if (path.endsWith("/ocr")) {
            long id = parseId(path.replace("/ocr", ""));
            if (id <= 0) { JsonSupport.error(resp, 400, "Invalid version ID"); return; }
            ocr(req, resp, id);
        } else {
            // Create new version
            createVersion(req, resp);
        }
    }

    // ── Create new T&C version ────────────────────────────────────────────────

    private void createVersion(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String contentType = req.getContentType();
        String tamilText = "", englishText = "", imageFilename = null;

        if (contentType != null && contentType.startsWith("multipart/")) {
            try {
                Part textPart  = req.getPart("tamilText");
                Part engPart   = req.getPart("englishText");
                Part filePart  = req.getPart("file");
                if (textPart != null) tamilText = new String(textPart.getInputStream().readAllBytes(), StandardCharsets.UTF_8).trim();
                if (engPart  != null) englishText = new String(engPart.getInputStream().readAllBytes(), StandardCharsets.UTF_8).trim();
                if (filePart != null && filePart.getSize() > 0) {
                    imageFilename = "terms-" + UUID.randomUUID() + getExtension(filePart.getSubmittedFileName());
                    try (InputStream in = filePart.getInputStream()) {
                        Files.copy(in, Path.of(UPLOAD_DIR, imageFilename), StandardCopyOption.REPLACE_EXISTING);
                    }
                }
            } catch (Exception e) {
                JsonSupport.error(resp, 400, "Could not parse multipart form: " + e.getMessage());
                return;
            }
        } else {
            try {
                Map<String, Object> body = JsonSupport.MAPPER.readValue(req.getInputStream(), Map.class);
                tamilText   = body.getOrDefault("tamilText",   "").toString().trim();
                englishText = body.getOrDefault("englishText", "").toString().trim();
            } catch (Exception e) {
                JsonSupport.error(resp, 400, "Invalid request body");
                return;
            }
        }

        if (tamilText.isBlank()) {
            JsonSupport.error(resp, 400, "Tamil text is required");
            return;
        }
        try {
            TermsVersion v = versionDao.create(tamilText, englishText, imageFilename);
            JsonSupport.write(resp, 201, v);
        } catch (Exception e) {
            getServletContext().log("Failed to create T&C version", e);
            JsonSupport.error(resp, 500, "Could not create T&C version");
        }
    }

    // ── Google Translate ──────────────────────────────────────────────────────

    private void translate(HttpServletResponse resp, long id) throws IOException {
        if (GOOGLE_TRANSLATE_KEY == null) {
            JsonSupport.error(resp, 503,
                    "Translation not configured. Set GOOGLE_TRANSLATE_KEY environment variable.");
            return;
        }
        TermsVersion v;
        try { v = versionDao.findById(id); } catch (Exception e) {
            JsonSupport.error(resp, 500, "Could not load version"); return;
        }
        if (v == null) { JsonSupport.error(resp, 404, "Version not found"); return; }

        try {
            String payload = JsonSupport.MAPPER.writeValueAsString(Map.of(
                    "q", v.getTamilText(), "source", "ta", "target", "en", "format", "text"));
            String url = "https://translation.googleapis.com/language/translate/v2?key=" + GOOGLE_TRANSLATE_KEY;
            HttpResponse<String> apiResp = HttpClient.newHttpClient().send(
                    HttpRequest.newBuilder().uri(URI.create(url))
                            .timeout(Duration.ofSeconds(15))
                            .header("Content-Type", "application/json")
                            .POST(HttpRequest.BodyPublishers.ofString(payload))
                            .build(),
                    HttpResponse.BodyHandlers.ofString());

            if (apiResp.statusCode() != 200) {
                JsonSupport.error(resp, 502, "Translation API error: " + apiResp.statusCode());
                return;
            }
            Map<?, ?> body = JsonSupport.MAPPER.readValue(apiResp.body(), Map.class);
            String translated = ((Map<?, ?>) ((Map<?, ?>) ((java.util.List<?>) ((Map<?, ?>) body.get("data")).get("translations")).get(0))).get("translatedText").toString();

            TermsVersion updated = versionDao.updateTranslation(id, translated);
            JsonSupport.write(resp, 200, updated);
        } catch (Exception e) {
            getServletContext().log("Translation failed", e);
            JsonSupport.error(resp, 500, "Translation failed: " + e.getMessage());
        }
    }

    // ── Google Vision OCR ─────────────────────────────────────────────────────

    private void ocr(HttpServletRequest req, HttpServletResponse resp, long id) throws IOException {
        if (GOOGLE_VISION_KEY == null) {
            JsonSupport.error(resp, 503,
                    "OCR not configured. Set GOOGLE_VISION_KEY environment variable.");
            return;
        }
        TermsVersion v;
        try { v = versionDao.findById(id); } catch (Exception e) {
            JsonSupport.error(resp, 500, "Could not load version"); return;
        }
        if (v == null) { JsonSupport.error(resp, 404, "Version not found"); return; }
        if (v.getImageFilename() == null) {
            JsonSupport.error(resp, 400, "No image uploaded for this version"); return;
        }

        try {
            byte[] imageBytes = Files.readAllBytes(Path.of(UPLOAD_DIR, v.getImageFilename()));
            String b64 = Base64.getEncoder().encodeToString(imageBytes);
            String payload = """
                    {"requests":[{"image":{"content":"%s"},"features":[{"type":"DOCUMENT_TEXT_DETECTION"}]}]}
                    """.formatted(b64);
            String url = "https://vision.googleapis.com/v1/images:annotate?key=" + GOOGLE_VISION_KEY;
            HttpResponse<String> apiResp = HttpClient.newHttpClient().send(
                    HttpRequest.newBuilder().uri(URI.create(url))
                            .timeout(Duration.ofSeconds(30))
                            .header("Content-Type", "application/json")
                            .POST(HttpRequest.BodyPublishers.ofString(payload))
                            .build(),
                    HttpResponse.BodyHandlers.ofString());

            if (apiResp.statusCode() != 200) {
                JsonSupport.error(resp, 502, "Vision API error: " + apiResp.statusCode());
                return;
            }
            Map<?, ?> body = JsonSupport.MAPPER.readValue(apiResp.body(), Map.class);
            java.util.List<?> responses = (java.util.List<?>) body.get("responses");
            Map<?, ?> firstResp = (Map<?, ?>) responses.get(0);
            Map<?, ?> annotation = (Map<?, ?>) firstResp.get("fullTextAnnotation");
            if (annotation == null) {
                JsonSupport.error(resp, 422, "No text detected in image");
                return;
            }
            String extractedText = annotation.get("text").toString();
            TermsVersion updated = versionDao.create(extractedText, "", v.getImageFilename());
            JsonSupport.write(resp, 200, updated);
        } catch (Exception e) {
            getServletContext().log("OCR failed", e);
            JsonSupport.error(resp, 500, "OCR failed: " + e.getMessage());
        }
    }

    private static long parseId(String path) {
        try { return Long.parseLong(path.replaceAll("[^0-9]", "")); }
        catch (NumberFormatException e) { return -1; }
    }

    private static String getExtension(String filename) {
        if (filename == null) return ".bin";
        int dot = filename.lastIndexOf('.');
        return dot >= 0 ? filename.substring(dot) : ".bin";
    }
}
