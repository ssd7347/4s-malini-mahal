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
        return false; // SMS disabled — OTP shown on screen
    }
}
