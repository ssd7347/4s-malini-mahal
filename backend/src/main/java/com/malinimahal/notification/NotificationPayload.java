package com.malinimahal.notification;

import com.malinimahal.enquiry.Enquiry;

import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Map;

public class NotificationPayload {

    private static final ZoneId IST = ZoneId.of("Asia/Kolkata");
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd-MM-yyyy");
    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("h:mm a");

    private static final Map<String, String> FUNCTION_LABELS = Map.ofEntries(
        Map.entry("MARRIAGE",         "Marriage"),
        Map.entry("RECEPTION",        "Reception"),
        Map.entry("ENGAGEMENT",       "Engagement"),
        Map.entry("BIRTHDAY_FUNCTION","Birthday Function"),
        Map.entry("OTHER",             "Other"),
        Map.entry("MEETING",          "Meeting"),
        Map.entry("CONFERENCE",       "Conference"),
        Map.entry("TRAINING_SESSION", "Training Session"),
        Map.entry("SEMINAR",          "Seminar"),
        Map.entry("WORKSHOP",         "Workshop"),
        Map.entry("SMALL_GATHERING",  "Small Gathering"),
        Map.entry("OTHER_HOURLY",     "Other Hourly Events")
    );

    private static final Map<String, String> RENTAL_LABELS = Map.of(
        "FULL_DAY", "Full Day",
        "HALF_DAY", "Half Day",
        "HOURLY",   "Hourly"
    );

    public final String bookingId;
    public final String customerName;
    public final String mobile;
    public final String functionType;
    public final String rentalType;
    public final String date;
    public final String timeRange;

    public NotificationPayload(Enquiry e) {
        this.bookingId    = e.getReference();
        this.customerName = e.getCustomerName();
        this.mobile       = e.getMobile();
        this.functionType = FUNCTION_LABELS.getOrDefault(e.getFunctionType(), e.getFunctionType());
        this.rentalType   = RENTAL_LABELS.getOrDefault(e.getRentalType(), e.getRentalType());
        this.date         = e.getEventDate() != null ? e.getEventDate().format(DATE_FMT) : "—";

        if (e.getStartDatetime() != null && e.getEndDatetime() != null) {
            this.timeRange = e.getStartDatetime().atZoneSameInstant(IST).format(TIME_FMT)
                + " - " + e.getEndDatetime().atZoneSameInstant(IST).format(TIME_FMT);
        } else {
            this.timeRange = "—";
        }
    }

    public String toMessageText() {
        return "New Booking Received\n\n"
            + "Booking ID: "   + bookingId    + "\n"
            + "Customer: "     + customerName + "\n"
            + "Phone: "        + mobile       + "\n"
            + "Function: "     + functionType + "\n"
            + "Rental Type: "  + rentalType   + "\n"
            + "Date: "         + date         + "\n"
            + "Time: "         + timeRange    + "\n\n"
            + "Please review the booking in the admin portal.";
    }

    public String toEmailSubject() {
        return "New Booking: " + bookingId + " — " + customerName;
    }

    public String toEmailHtml() {
        return "<!DOCTYPE html><html><body style='font-family:sans-serif;color:#333'>"
            + "<h2 style='color:#b91c1c'>New Booking Received</h2>"
            + "<table style='border-collapse:collapse;width:100%;max-width:480px'>"
            + row("Booking ID",   bookingId)
            + row("Customer",     customerName)
            + row("Phone",        mobile)
            + row("Function",     functionType)
            + row("Rental Type",  rentalType)
            + row("Date",         date)
            + row("Time",         timeRange)
            + "</table>"
            + "<p style='margin-top:24px'>Please review the booking in the admin portal.</p>"
            + "</body></html>";
    }

    private static String row(String label, String value) {
        return "<tr>"
            + "<td style='padding:6px 12px 6px 0;font-weight:600;white-space:nowrap'>" + label + "</td>"
            + "<td style='padding:6px 0'>" + value + "</td>"
            + "</tr>";
    }
}
