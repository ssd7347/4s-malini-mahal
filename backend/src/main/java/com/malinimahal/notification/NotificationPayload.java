package com.malinimahal.notification;

import com.malinimahal.enquiry.Enquiry;

import java.time.LocalDate;
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

    private final String type; // "CONFIRMED", "RESCHEDULED", "CANCELLED"

    public final String bookingId;
    public final String customerName;
    public final String mobile;
    public final String functionType;
    public final String rentalType;
    public final String date;      // current/new event date
    public final String timeRange;
    public final String oldDate;   // only set for RESCHEDULED

    /** Called after successful payment. */
    public NotificationPayload(Enquiry e) {
        this("CONFIRMED", e, null);
    }

    private NotificationPayload(String type, Enquiry e, String oldDate) {
        this.type         = type;
        this.bookingId    = e.getReference();
        this.customerName = e.getCustomerName();
        this.mobile       = e.getMobile();
        this.functionType = FUNCTION_LABELS.getOrDefault(e.getFunctionType(), e.getFunctionType());
        this.rentalType   = RENTAL_LABELS.getOrDefault(e.getRentalType(), e.getRentalType());
        this.date         = e.getEventDate() != null ? e.getEventDate().format(DATE_FMT) : "—";
        this.oldDate      = oldDate;

        if (e.getStartDatetime() != null && e.getEndDatetime() != null) {
            this.timeRange = e.getStartDatetime().atZoneSameInstant(IST).format(TIME_FMT)
                + " - " + e.getEndDatetime().atZoneSameInstant(IST).format(TIME_FMT);
        } else {
            this.timeRange = "—";
        }
    }

    public static NotificationPayload forCancellation(Enquiry e) {
        return new NotificationPayload("CANCELLED", e, null);
    }

    public static NotificationPayload forReschedule(Enquiry e, LocalDate previousDate) {
        return new NotificationPayload("RESCHEDULED", e, previousDate.format(DATE_FMT));
    }

    public String toMessageText() {
        if ("CANCELLED".equals(type)) {
            return "Booking Cancelled\n\n"
                + "Booking ID: "   + bookingId    + "\n"
                + "Customer: "     + customerName + "\n"
                + "Phone: "        + mobile       + "\n"
                + "Function: "     + functionType + "\n"
                + "Rental Type: "  + rentalType   + "\n"
                + "Date: "         + date         + "\n\n"
                + "The customer has cancelled this booking.";
        }
        if ("RESCHEDULED".equals(type)) {
            return "Booking Rescheduled\n\n"
                + "Booking ID: "   + bookingId    + "\n"
                + "Customer: "     + customerName + "\n"
                + "Phone: "        + mobile       + "\n"
                + "Function: "     + functionType + "\n"
                + "Rental Type: "  + rentalType   + "\n"
                + "Old Date: "     + oldDate      + "\n"
                + "New Date: "     + date         + "\n"
                + "Time: "         + timeRange    + "\n\n"
                + "The customer has rescheduled this booking.";
        }
        // CONFIRMED
        return "Booking Confirmed — Payment Received\n\n"
            + "Booking ID: "   + bookingId    + "\n"
            + "Customer: "     + customerName + "\n"
            + "Phone: "        + mobile       + "\n"
            + "Function: "     + functionType + "\n"
            + "Rental Type: "  + rentalType   + "\n"
            + "Date: "         + date         + "\n"
            + "Time: "         + timeRange    + "\n\n"
            + "Advance payment has been received. View details in the admin portal.";
    }

    public String toEmailSubject() {
        if ("CANCELLED".equals(type))   return "Booking Cancelled: "   + bookingId + " — " + customerName;
        if ("RESCHEDULED".equals(type)) return "Booking Rescheduled: " + bookingId + " — " + customerName;
        return "Booking Confirmed: " + bookingId + " — " + customerName;
    }

    public String toEmailHtml() {
        if ("CANCELLED".equals(type)) {
            return "<!DOCTYPE html><html><body style='font-family:sans-serif;color:#333'>"
                + "<h2 style='color:#b91c1c'>Booking Cancelled</h2>"
                + "<table style='border-collapse:collapse;width:100%;max-width:480px'>"
                + row("Booking ID",   bookingId)
                + row("Customer",     customerName)
                + row("Phone",        mobile)
                + row("Function",     functionType)
                + row("Rental Type",  rentalType)
                + row("Date",         date)
                + "</table>"
                + "<p style='margin-top:24px'>The customer has cancelled this booking.</p>"
                + "</body></html>";
        }
        if ("RESCHEDULED".equals(type)) {
            return "<!DOCTYPE html><html><body style='font-family:sans-serif;color:#333'>"
                + "<h2 style='color:#1d4ed8'>Booking Rescheduled</h2>"
                + "<table style='border-collapse:collapse;width:100%;max-width:480px'>"
                + row("Booking ID",   bookingId)
                + row("Customer",     customerName)
                + row("Phone",        mobile)
                + row("Function",     functionType)
                + row("Rental Type",  rentalType)
                + row("Old Date",     "<s>" + oldDate + "</s>")
                + row("New Date",     "<strong>" + date + "</strong>")
                + row("Time",         timeRange)
                + "</table>"
                + "<p style='margin-top:24px'>The customer has rescheduled this booking. Please update your calendar.</p>"
                + "</body></html>";
        }
        // CONFIRMED
        return "<!DOCTYPE html><html><body style='font-family:sans-serif;color:#333'>"
            + "<h2 style='color:#b91c1c'>Booking Confirmed — Payment Received</h2>"
            + "<table style='border-collapse:collapse;width:100%;max-width:480px'>"
            + row("Booking ID",   bookingId)
            + row("Customer",     customerName)
            + row("Phone",        mobile)
            + row("Function",     functionType)
            + row("Rental Type",  rentalType)
            + row("Date",         date)
            + row("Time",         timeRange)
            + "</table>"
            + "<p style='margin-top:24px'>Advance payment has been received. View details in the admin portal.</p>"
            + "</body></html>";
    }

    private static String row(String label, String value) {
        return "<tr>"
            + "<td style='padding:6px 12px 6px 0;font-weight:600;white-space:nowrap'>" + label + "</td>"
            + "<td style='padding:6px 0'>" + value + "</td>"
            + "</tr>";
    }
}
