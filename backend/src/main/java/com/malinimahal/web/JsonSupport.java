package com.malinimahal.web;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.Map;

/**
 * Shared, pre-configured Jackson mapper plus small JSON response helpers.
 */
public final class JsonSupport {

    public static final ObjectMapper MAPPER = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            // Write dates as ISO-8601 strings (e.g. "2026-08-15") instead of numeric arrays.
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    private JsonSupport() {
    }

    public static void write(HttpServletResponse resp, int status, Object body) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        MAPPER.writeValue(resp.getWriter(), body);
    }

    public static void error(HttpServletResponse resp, int status, String message) throws IOException {
        write(resp, status, Map.of("error", message));
    }
}
