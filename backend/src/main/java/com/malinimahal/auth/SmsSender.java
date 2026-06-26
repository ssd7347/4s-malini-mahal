package com.malinimahal.auth;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.logging.Logger;

public class SmsSender {

    private static final Logger LOG = Logger.getLogger(SmsSender.class.getName());
    private static final String TWO_FACTOR_KEY = System.getenv("TWO_FACTOR_KEY");

    public static boolean isConfigured() {
        return TWO_FACTOR_KEY != null && !TWO_FACTOR_KEY.isBlank();
    }

    public static boolean sendNotification(String mobile, String message) {
        return false; // 2Factor OTP-only; notifications not supported on this route
    }

    /** Returns true if OTP SMS was sent, false if key not configured or send failed. */
    public static boolean send(String mobile, String otp) {
        if (!isConfigured()) return false;
        try {
            String url = "https://2factor.in/API/V1/" + TWO_FACTOR_KEY
                    + "/SMS/" + mobile + "/" + otp;

            HttpResponse<String> res = HttpClient.newHttpClient().send(
                    HttpRequest.newBuilder()
                            .uri(URI.create(url))
                            .timeout(Duration.ofSeconds(10))
                            .GET()
                            .build(),
                    HttpResponse.BodyHandlers.ofString());

            String body = res.body();
            if (res.statusCode() == 200 && body.contains("\"Success\"")) {
                LOG.info("OTP SMS sent via 2Factor to " + mobile);
                return true;
            }
            LOG.warning("2Factor failed (" + res.statusCode() + "): " + body);
            return false;
        } catch (Exception e) {
            LOG.warning("2Factor send error: " + e.getMessage());
            return false;
        }
    }
}
