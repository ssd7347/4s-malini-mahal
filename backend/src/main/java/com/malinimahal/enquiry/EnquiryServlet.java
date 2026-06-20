package com.malinimahal.enquiry;

import com.malinimahal.auth.OtpServlet;
import com.malinimahal.muhurtham.MuhurthamDateDao;
import com.malinimahal.notification.OwnerNotifier;
import com.malinimahal.payment.PaymentDao;
import com.malinimahal.refund.Refund;
import com.malinimahal.refund.RefundDao;
import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;

@WebServlet(urlPatterns = {"/api/enquiries", "/api/enquiries/*"})
public class EnquiryServlet extends HttpServlet {

    private static final ZoneId IST = ZoneId.of("Asia/Kolkata");

    private static final Map<String, List<String>> FUNCTION_TYPES = Map.of(
        "FULL_DAY",  List.of("MARRIAGE"),
        "HALF_DAY",  List.of("RECEPTION", "ENGAGEMENT", "BIRTHDAY_FUNCTION", "OTHER"),
        "HOURLY",    List.of("MEETING", "CONFERENCE", "TRAINING_SESSION", "SEMINAR",
                             "WORKSHOP", "SMALL_GATHERING", "OTHER_HOURLY")
    );

    private final EnquiryDao        dao             = new EnquiryDao();
    private final MuhurthamDateDao  muhurthamDao    = new MuhurthamDateDao();
    private final PaymentDao        paymentDao      = new PaymentDao();
    private final RefundDao         refundDao       = new RefundDao();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String postPath = req.getPathInfo();
        if (postPath != null && postPath.endsWith("/cancel")) {
            handleCancel(req, resp);
            return;
        }

        Enquiry input;
        try {
            input = JsonSupport.MAPPER.readValue(req.getInputStream(), Enquiry.class);
        } catch (Exception e) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Invalid request body");
            return;
        }

        String validationError = validate(input);
        if (validationError != null) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, validationError);
            return;
        }

        OffsetDateTime startDt = computeStart(input);
        OffsetDateTime endDt   = computeEnd(input);

        try {
            if (dao.hasConflict(input.getRentalType(), startDt, endDt, null)) {
                JsonSupport.error(resp, 409,
                        "This time slot is already booked. Please choose a different date or time.");
                return;
            }
        } catch (Exception conflictEx) {
            getServletContext().log("Conflict check failed — proceeding without check", conflictEx);
        }

        boolean muhurtham = false;
        try {
            muhurtham = muhurthamDao.isOnMuhurtham(input.getEventDate());
        } catch (Exception ignore) {}

        if (muhurtham && "HOURLY".equals(input.getRentalType())) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST,
                    "Hourly rentals are not available on muhurtham dates");
            return;
        }

        Enquiry toSave = new Enquiry();
        toSave.setCustomerName(input.getCustomerName().trim());
        toSave.setMobile(input.getMobile().trim());
        toSave.setEventDate(input.getEventDate());
        LocalDate effectiveEndDate = (input.getEndDate() != null) ? input.getEndDate() : input.getEventDate();
        toSave.setEndDate(effectiveEndDate);
        toSave.setRentalType(input.getRentalType());
        toSave.setFunctionType(input.getFunctionType().trim());
        toSave.setMessage(input.getMessage() == null ? null : input.getMessage().trim());
        toSave.setStartDatetime(startDt);
        toSave.setEndDatetime(endDt);
        toSave.setMuhurtham(muhurtham);

        try {
            Enquiry saved = dao.create(toSave);
            OwnerNotifier.notifyAsync(saved);
            JsonSupport.write(resp, HttpServletResponse.SC_CREATED, saved);
        } catch (Exception e) {
            getServletContext().log("Failed to create enquiry", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Could not save the enquiry. Please try again.");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getPathInfo();
        if (path == null || path.length() <= 1) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing enquiry reference");
            return;
        }
        String sub = path.substring(1);

        if ("my".equals(sub)) {
            HttpSession session = req.getSession(false);
            String mobile = (session != null)
                    ? (String) session.getAttribute(OtpServlet.ATTR_MOBILE) : null;
            if (mobile == null) {
                JsonSupport.error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Not logged in");
                return;
            }
            try {
                List<com.malinimahal.enquiry.Enquiry> list = dao.listByMobile(mobile);
                JsonSupport.write(resp, HttpServletResponse.SC_OK, list);
            } catch (Exception e) {
                getServletContext().log("Failed to list enquiries for mobile", e);
                JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                        "Could not load your bookings. Please try again.");
            }
            return;
        }

        try {
            Enquiry found = dao.findByReference(sub);
            if (found == null) {
                JsonSupport.error(resp, HttpServletResponse.SC_NOT_FOUND, "No enquiry found for that reference");
                return;
            }
            JsonSupport.write(resp, HttpServletResponse.SC_OK, found);
        } catch (Exception e) {
            getServletContext().log("Failed to look up enquiry", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Could not look up the enquiry. Please try again.");
        }
    }

    private void handleCancel(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        // path = "/:ref/cancel"
        String p   = req.getPathInfo();
        String ref = p.substring(1, p.lastIndexOf('/'));

        HttpSession session = req.getSession(false);
        String mobile = (session != null) ? (String) session.getAttribute(OtpServlet.ATTR_MOBILE) : null;
        if (mobile == null) {
            JsonSupport.error(resp, HttpServletResponse.SC_UNAUTHORIZED, "Not logged in");
            return;
        }

        Enquiry enquiry;
        try {
            enquiry = dao.findByReference(ref);
        } catch (Exception e) {
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not load booking");
            return;
        }

        if (enquiry == null) {
            JsonSupport.error(resp, HttpServletResponse.SC_NOT_FOUND, "Booking not found");
            return;
        }
        if (!mobile.equals(enquiry.getMobile())) {
            JsonSupport.error(resp, HttpServletResponse.SC_FORBIDDEN, "This booking does not belong to your account");
            return;
        }

        String status = enquiry.getStatus();
        if (!"AWAITING_PAYMENT".equals(status) && !"CONFIRMED".equals(status)) {
            JsonSupport.error(resp, HttpServletResponse.SC_CONFLICT,
                    "This booking cannot be cancelled (current status: " + status + ")");
            return;
        }

        try {
            boolean hadPayment = "CONFIRMED".equals(status);
            Refund  refund     = null;

            if (hadPayment) {
                long advancePaise = paymentDao.getTotalPaidPaise(ref, "ADVANCE");
                if (advancePaise > 0) {
                    refund = refundDao.create(ref, enquiry.isMuhurtham(), advancePaise);
                }
            }

            dao.updateStatus(ref, "CANCELLED");

            LinkedHashMap<String, Object> result = new LinkedHashMap<>();
            result.put("success", true);
            result.put("hadPayment", hadPayment);
            if (refund != null) {
                result.put("isMuhurtham",  refund.isMuhurtham());
                result.put("refundPct",    refund.getRefundPct());
                result.put("refundPaise",  refund.getRefundPaise());
            }
            JsonSupport.write(resp, HttpServletResponse.SC_OK, result);

        } catch (Exception e) {
            getServletContext().log("Failed to cancel booking " + ref, e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Could not cancel the booking. Please try again.");
        }
    }

    /**
     * Compute start_datetime in IST per T&C Rule 1:
     *   FULL_DAY → day BEFORE event date at 15:00 (3:00 PM)
     *   HALF_DAY / HOURLY → event date at customer-supplied startTime
     */
    private static OffsetDateTime computeStart(Enquiry e) {
        if ("FULL_DAY".equals(e.getRentalType())) {
            return e.getEventDate().minusDays(1).atTime(15, 0)
                    .atZone(IST).toOffsetDateTime();
        }
        return e.getEventDate().atTime(LocalTime.parse(e.getStartTime()))
                .atZone(IST).toOffsetDateTime();
    }

    /**
     * Compute end_datetime in IST per T&C Rule 1:
     *   FULL_DAY → endDate (or eventDate for single-day) at 14:00 (2:00 PM)
     *   HALF_DAY / HOURLY → event date at customer-supplied endTime
     */
    private static OffsetDateTime computeEnd(Enquiry e) {
        if ("FULL_DAY".equals(e.getRentalType())) {
            LocalDate lastDay = e.getEndDate() != null ? e.getEndDate() : e.getEventDate();
            return lastDay.atTime(14, 0).atZone(IST).toOffsetDateTime();
        }
        return e.getEventDate().atTime(LocalTime.parse(e.getEndTime()))
                .atZone(IST).toOffsetDateTime();
    }

    private static String validate(Enquiry e) {
        if (isBlank(e.getCustomerName())) return "Name is required";
        if (isBlank(e.getMobile()))       return "Mobile number is required";
        if (!e.getMobile().trim().matches("[6-9]\\d{9}"))
            return "Mobile must be a 10-digit number starting with 6, 7, 8, or 9";
        if (e.getEventDate() == null)     return "Event date is required";
        if (e.getEndDate() != null && e.getEndDate().isBefore(e.getEventDate()))
            return "End date cannot be before start date";
        if (e.getEndDate() != null && !e.getEndDate().equals(e.getEventDate()) && !"FULL_DAY".equals(e.getRentalType()))
            return "Multi-day booking is only available for Full Day rental";
        if (isBlank(e.getRentalType()))   return "Rental type is required";

        List<String> allowed = FUNCTION_TYPES.get(e.getRentalType());
        if (allowed == null) return "Invalid rental type";

        if (isBlank(e.getFunctionType())) return "Function type is required";
        if (!allowed.contains(e.getFunctionType())) {
            return "Function type '" + e.getFunctionType() + "' is not valid for rental type " + e.getRentalType();
        }

        // FULL_DAY (Marriage) datetimes are auto-computed; no time input needed
        if (!"FULL_DAY".equals(e.getRentalType())) {
            if (isBlank(e.getStartTime())) return "Start time is required";
            if (isBlank(e.getEndTime()))   return "End time is required";
            try {
                LocalTime start = LocalTime.parse(e.getStartTime());
                LocalTime end   = LocalTime.parse(e.getEndTime());
                if (!end.isAfter(start)) return "End time must be after start time";
                if ("HOURLY".equals(e.getRentalType())) {
                    long hours = Duration.between(start, end).toHours();
                    if (hours < 2) return "Hourly rental requires at least 2 hours";
                    if (hours > 4) return "Hourly rental allows a maximum of 4 hours";
                }
            } catch (Exception ex) {
                return "Invalid time format (expected HH:MM)";
            }
        }
        return null;
    }

    private static boolean isBlank(String s) { return s == null || s.isBlank(); }
}
