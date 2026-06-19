package com.malinimahal.availability;

import com.malinimahal.db.Database;
import com.malinimahal.muhurtham.MuhurthamDateDao;
import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Public availability check: GET /api/availability?date=yyyy-MM-dd
 *
 * Returns only a coarse status — never other customers' bookings or the full
 * calendar (by design):
 *   UNAVAILABLE   the date is blocked or already has a confirmed booking
 *   UNDER_ENQUIRY one or more enquiries are open for the date
 *   AVAILABLE     nothing on the date yet
 */
@WebServlet("/api/availability")
public class AvailabilityServlet extends HttpServlet {

    private final MuhurthamDateDao muhurthamDao = new MuhurthamDateDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String dateParam = req.getParameter("date");
        LocalDate date;
        try {
            date = LocalDate.parse(dateParam == null ? "" : dateParam);
        } catch (DateTimeParseException e) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "A valid date (yyyy-MM-dd) is required");
            return;
        }

        // param 4 = tomorrow: Full Day for tomorrow means today is blocked from 13:00 (2h before 15:00 entry)
        final String statusSql = """
                SELECT
                  EXISTS(SELECT 1 FROM blocked_dates WHERE blocked_date = ?) AS blocked,
                  EXISTS(SELECT 1 FROM enquiries WHERE event_date = ?
                         AND status IN ('NEW','UNDER_ENQUIRY','AWAITING_PAYMENT','CONFIRMED')) AS any_booking,
                  EXISTS(SELECT 1 FROM enquiries WHERE event_date = ?
                         AND rental_type = 'FULL_DAY'
                         AND status IN ('NEW','UNDER_ENQUIRY','AWAITING_PAYMENT','CONFIRMED')) AS today_full_day,
                  EXISTS(SELECT 1 FROM enquiries WHERE event_date = ?
                         AND rental_type = 'FULL_DAY'
                         AND status IN ('NEW','UNDER_ENQUIRY','AWAITING_PAYMENT','CONFIRMED')) AS next_full_day
                """;
        final String slotSql = """
                SELECT rental_type,
                       start_datetime AT TIME ZONE 'Asia/Kolkata' AS local_start,
                       end_datetime   AT TIME ZONE 'Asia/Kolkata' AS local_end
                FROM enquiries
                WHERE event_date = ?
                AND rental_type != 'FULL_DAY'
                AND status IN ('NEW','UNDER_ENQUIRY','AWAITING_PAYMENT','CONFIRMED')
                ORDER BY start_datetime
                """;
        try (Connection conn = Database.getConnection()) {
            boolean blocked, anyBooking, todayFD, nextFD;
            try (PreparedStatement ps = conn.prepareStatement(statusSql)) {
                ps.setObject(1, date);
                ps.setObject(2, date);
                ps.setObject(3, date);
                ps.setObject(4, date.plusDays(1));
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    blocked    = rs.getBoolean("blocked");
                    anyBooking = rs.getBoolean("any_booking");
                    todayFD    = rs.getBoolean("today_full_day");
                    nextFD     = rs.getBoolean("next_full_day");
                }
            }

            // UNAVAILABLE only for admin-blocked dates.
            // Full Day bookings (either today's or tomorrow's) show UNDER_ENQUIRY — some slots remain open.
            String status;
            if (blocked) {
                status = "UNAVAILABLE";
            } else if (anyBooking || nextFD) {
                status = "UNDER_ENQUIRY";
            } else {
                status = "AVAILABLE";
            }

            List<Map<String, String>> bookedSlots = new ArrayList<>();
            if (!blocked) {
                // Full Day for today occupies midnight→14:00; prepend so it sorts first
                if (todayFD) {
                    Map<String, String> fdSlot = new LinkedHashMap<>();
                    fdSlot.put("rentalType", "FULL_DAY");
                    fdSlot.put("startTime", "00:00");
                    fdSlot.put("endTime", "14:00");
                    bookedSlots.add(fdSlot);
                }
                // Non-Full-Day bookings on this date
                try (PreparedStatement ps2 = conn.prepareStatement(slotSql)) {
                    ps2.setObject(1, date);
                    try (ResultSet rs2 = ps2.executeQuery()) {
                        while (rs2.next()) {
                            LocalDateTime localStart = rs2.getObject("local_start", LocalDateTime.class);
                            LocalDateTime localEnd   = rs2.getObject("local_end",   LocalDateTime.class);
                            Map<String, String> slot = new LinkedHashMap<>();
                            slot.put("rentalType", rs2.getString("rental_type"));
                            slot.put("startTime", String.format("%02d:%02d",
                                    localStart.getHour(), localStart.getMinute()));
                            slot.put("endTime", String.format("%02d:%02d",
                                    localEnd.getHour(), localEnd.getMinute()));
                            bookedSlots.add(slot);
                        }
                    }
                }
                // Full Day for tomorrow: setup crew arrives at 15:00, cleaning from 13:00 — block 13:00 onwards
                if (nextFD) {
                    Map<String, String> setupSlot = new LinkedHashMap<>();
                    setupSlot.put("rentalType", "FULL_DAY");
                    setupSlot.put("startTime", "13:00");
                    setupSlot.put("endTime", "23:00");
                    bookedSlots.add(setupSlot);
                }
            }

            boolean isMuhurtham = false;
            try { isMuhurtham = muhurthamDao.isOnMuhurtham(date); } catch (Exception ignore) {}

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("date", date.toString());
            result.put("status", status);
            result.put("isMuhurtham", isMuhurtham);
            result.put("bookedSlots", bookedSlots);
            JsonSupport.write(resp, HttpServletResponse.SC_OK, result);

        } catch (Exception e) {
            getServletContext().log("Availability check failed", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not check availability");
        }
    }
}
