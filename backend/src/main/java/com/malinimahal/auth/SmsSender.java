package com.malinimahal.auth;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.logging.Logger;

public class SmsSender {

    private static final Logger LOG = Logger.getLogger(SmsSender.class.getName());
    private static final String FAST2SMS_KEY = System.getenv("FAST2SMS_KEY");

    public static boolean isConfigured() {
        return FAST2SMS_KEY != null && !FAST2SMS_KEY.isBlank();
    }

    /** Sends an arbitrary plain-text message (used for owner notifications). */
    public static boolean sendNotification(String mobile, String message) {
        return sendRaw(mobile, message);
    }

    /** Returns true if OTP SMS was sent, false if key not configured or send failed. */
    public static boolean send(String mobile, String otp) {
        if (!isConfigured()) return false;
        String message = "Your 4S Malini Mahal login OTP is " + otp + ". Valid for 2 minutes. Do not share.";
        return sendRaw(mobile, message);
    }

    private static boolean sendRaw(String mobile, String message) {
        if (!isConfigured()) {
            return false;
        }
        try {
            String url = "https://www.fast2sms.com/dev/bulkV2"
                    + "?authorization=" + URLEncoder.encode(FAST2SMS_KEY, StandardCharsets.UTF_8)
                    + "&route=q"
                    + "&message=" + URLEncoder.encode(message, StandardCharsets.UTF_8)
                    + "&flash=0"
                    + "&numbers=" + URLEncoder.encode(mobile, StandardCharsets.UTF_8);

            HttpResponse<String> res = HttpClient.newHttpClient().send(
                    HttpRequest.newBuilder()
                            .uri(URI.create(url))
                            .timeout(Duration.ofSeconds(10))
                            .GET()
                            .build(),
                    HttpResponse.BodyHandlers.ofString());

            String body = res.body();
            if (res.statusCode() == 200 && body.contains("\"return\":true")) {
                LOG.info("OTP SMS sent via Fast2SMS to " + mobile);
                return true;
            }
            LOG.warning("Fast2SMS failed (" + res.statusCode() + "): " + body);
            return false;
        } catch (Exception e) {
            LOG.warning("Fast2SMS send error: " + e.getMessage());
            return false;
        }
    }
}
