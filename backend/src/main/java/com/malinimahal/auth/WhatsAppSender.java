package com.malinimahal.auth;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.logging.Logger;

/**
 * Sends WhatsApp messages via Meta Cloud API.
 *
 * Dev mode (default — no env vars set): logs the OTP only; OtpServlet echoes
 * it in the API response so the full flow can be tested without WhatsApp.
 *
 * Production: set these three env vars before starting Tomcat:
 *   WA_ENABLED=true
 *   WA_META_TOKEN=<permanent system-user token from Meta>
 *   WA_META_PHONE_ID=<Phone Number ID from WhatsApp > API Setup>
 */
public class WhatsAppSender {

    private static final Logger LOG = Logger.getLogger(WhatsAppSender.class.getName());

    private static final String WA_ENABLED      = System.getenv("WA_ENABLED");
    private static final String WA_META_TOKEN   = System.getenv("WA_META_TOKEN");
    private static final String WA_META_PHONE_ID = System.getenv("WA_META_PHONE_ID");

    private static final String GRAPH_API_VERSION = "v21.0";

    /**
     * Returns true if the message was dispatched to WhatsApp, false in dev mode.
     * When false, the caller should include the OTP in the JSON response.
     */
    public static boolean send(String toMobile, String message) {
        if (!"true".equalsIgnoreCase(WA_ENABLED)) {
            LOG.info("[DEV] WhatsApp → " + toMobile + ": " + message);
            return false;
        }
        if (WA_META_TOKEN == null || WA_META_PHONE_ID == null) {
            LOG.warning("WA_ENABLED=true but WA_META_TOKEN or WA_META_PHONE_ID is not set — falling back to dev mode");
            LOG.info("[DEV] WhatsApp → " + toMobile + ": " + message);
            return false;
        }
        return sendViaMeta(toMobile, message);
    }

    private static boolean sendViaMeta(String mobile, String message) {
        try {
            // Normalise to international format without leading +
            String to = mobile.startsWith("91") ? mobile : "91" + mobile;

            String body = "{"
                + "\"messaging_product\":\"whatsapp\","
                + "\"to\":\"" + to + "\","
                + "\"type\":\"text\","
                + "\"text\":{\"body\":" + jsonString(message) + "}"
                + "}";

            String url = "https://graph.facebook.com/" + GRAPH_API_VERSION
                    + "/" + WA_META_PHONE_ID + "/messages";

            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofSeconds(10))
                    .header("Authorization", "Bearer " + WA_META_TOKEN)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();

            HttpResponse<String> res = HttpClient.newHttpClient()
                    .send(req, HttpResponse.BodyHandlers.ofString());

            if (res.statusCode() == 200 || res.statusCode() == 201) {
                LOG.info("WhatsApp OTP sent via Meta to " + to);
                return true;
            }
            LOG.warning("Meta WhatsApp API error " + res.statusCode() + ": " + res.body());
            return false;
        } catch (Exception e) {
            LOG.warning("Meta WhatsApp send failed: " + e.getMessage());
            return false;
        }
    }

    private static String jsonString(String s) {
        return "\"" + s.replace("\\", "\\\\")
                       .replace("\"", "\\\"")
                       .replace("\n", "\\n")
                       .replace("\r", "\\r") + "\"";
    }
}
