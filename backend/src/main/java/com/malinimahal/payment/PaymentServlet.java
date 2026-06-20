package com.malinimahal.payment;

import com.malinimahal.enquiry.Enquiry;
import com.malinimahal.enquiry.EnquiryDao;
import com.malinimahal.notification.OwnerNotifier;
import com.malinimahal.terms.TermsAcceptanceDao;
import com.malinimahal.terms.TermsVersionDao;
import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

/**
 * Payment endpoints:
 *   POST /api/payments/create-order    {reference, paymentType} → Razorpay order
 *   POST /api/payments/verify          {reference, razorpayOrderId, ...} → confirm booking
 *   GET  /api/payments/invoice/:ref    full invoice data
 *   GET  /api/payments/history/:ref    payment records for a booking
 */
@WebServlet("/api/payments/*")
public class PaymentServlet extends HttpServlet {

    private static final Logger LOG = Logger.getLogger(PaymentServlet.class.getName());

    private static final String KEY_ID     = System.getenv("RAZORPAY_KEY_ID");
    private static final String KEY_SECRET = System.getenv("RAZORPAY_KEY_SECRET");

    private final EnquiryDao         enquiryDao      = new EnquiryDao();
    private final PaymentDao          paymentDao      = new PaymentDao();
    private final TermsVersionDao     termsVersionDao = new TermsVersionDao();
    private final TermsAcceptanceDao  termsAcceptDao  = new TermsAcceptanceDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getPathInfo();
        if (path == null) { JsonSupport.error(resp, 404, "Not found"); return; }
        if (path.startsWith("/invoice/")) {
            getInvoice(resp, path.substring("/invoice/".length()).trim());
        } else if (path.startsWith("/history/")) {
            getHistory(resp, path.substring("/history/".length()).trim());
        } else {
            JsonSupport.error(resp, 404, "Unknown endpoint");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getPathInfo();
        if ("/create-order".equals(path)) {
            createOrder(req, resp);
        } else if ("/verify".equals(path)) {
            verifyPayment(req, resp);
        } else {
            JsonSupport.error(resp, 404, "Unknown endpoint");
        }
    }

    // ── Create Razorpay Order ─────────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private void createOrder(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (KEY_ID == null || KEY_SECRET == null) {
            JsonSupport.error(resp, 503,
                    "Payment gateway not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET env vars.");
            return;
        }

        Map<String, Object> body;
        try {
            body = JsonSupport.MAPPER.readValue(req.getInputStream(), Map.class);
        } catch (Exception e) {
            JsonSupport.error(resp, 400, "Invalid request body");
            return;
        }

        String reference      = body.getOrDefault("reference", "").toString().trim();
        String paymentType    = body.getOrDefault("paymentType", "ADVANCE").toString().trim();
        Object termsIdObj     = body.get("termsVersionId");
        long   termsVersionId = termsIdObj != null ? ((Number) termsIdObj).longValue() : 0L;

        // For ADVANCE payments, T&C acceptance is required only when an active version exists
        if ("ADVANCE".equals(paymentType) && termsVersionId <= 0) {
            try {
                if (termsVersionDao.findActive() != null) {
                    JsonSupport.error(resp, 400, "You must accept the Terms & Conditions before paying");
                    return;
                }
            } catch (Exception ignore) {}
        }

        Enquiry enquiry;
        try {
            enquiry = enquiryDao.findByReference(reference);
        } catch (Exception e) {
            getServletContext().log("Failed to look up enquiry", e);
            JsonSupport.error(resp, 500, "Could not look up booking");
            return;
        }
        if (enquiry == null) {
            JsonSupport.error(resp, 404, "Booking not found");
            return;
        }

        long amountPaise;
        if ("ADVANCE".equals(paymentType)) {
            if (!"AWAITING_PAYMENT".equals(enquiry.getStatus())) {
                JsonSupport.error(resp, 400,
                        "This booking is not awaiting payment. Current status: " + enquiry.getStatus());
                return;
            }
            amountPaise = computeBaseRentPaise(enquiry);
        } else {
            // BALANCE payment — charged after event (electricity + gas + decoration)
            if (!"CONFIRMED".equals(enquiry.getStatus())) {
                JsonSupport.error(resp, 400, "Balance payment is only available for CONFIRMED bookings");
                return;
            }
            if (enquiry.getElecUnits() == null) {
                JsonSupport.error(resp, 400, "Billing charges have not been entered yet by the admin");
                return;
            }
            long baseRent = computeBaseRentPaise(enquiry);
            long advancePaid;
            try { advancePaid = paymentDao.getTotalPaidPaise(reference, "ADVANCE"); }
            catch (Exception e) { advancePaid = 0; }
            long elec       = Math.round(enquiry.getElecUnits() * 4000);
            long gas        = Math.round(enquiry.getGasKg()    * 18000);
            long decor      = enquiry.getDecorationChargePaise()    != null ? enquiry.getDecorationChargePaise()    : 0L;
            long earlyEntry = enquiry.getEarlyEntryChargePaise()    != null ? enquiry.getEarlyEntryChargePaise()    : 0L;
            long keyLoss    = enquiry.getKeyLossChargePaise()       != null ? enquiry.getKeyLossChargePaise()       : 0L;
            long total = baseRent + elec + gas + decor + earlyEntry + keyLoss;
            amountPaise = Math.max(0, total - advancePaid);
            if (amountPaise == 0) {
                JsonSupport.error(resp, 400, "No balance remaining");
                return;
            }
        }

        // Record T&C acceptance for ADVANCE payment
        if ("ADVANCE".equals(paymentType) && termsVersionId > 0) {
            try {
                termsAcceptDao.record(reference, enquiry.getMobile(), termsVersionId);
            } catch (Exception e) {
                getServletContext().log("Failed to record T&C acceptance", e);
                // Non-fatal: continue with payment
            }
        }

        // Call Razorpay to create an order
        try {
            String payload = "{\"amount\":" + amountPaise
                    + ",\"currency\":\"INR\",\"receipt\":\"" + reference + "\"}";
            String auth = Base64.getEncoder()
                    .encodeToString((KEY_ID + ":" + KEY_SECRET).getBytes(StandardCharsets.UTF_8));

            HttpResponse<String> rzpResp = HttpClient.newHttpClient().send(
                    HttpRequest.newBuilder()
                            .uri(URI.create("https://api.razorpay.com/v1/orders"))
                            .timeout(Duration.ofSeconds(10))
                            .header("Authorization", "Basic " + auth)
                            .header("Content-Type", "application/json")
                            .POST(HttpRequest.BodyPublishers.ofString(payload))
                            .build(),
                    HttpResponse.BodyHandlers.ofString());

            if (rzpResp.statusCode() != 200) {
                LOG.warning("Razorpay error " + rzpResp.statusCode() + ": " + rzpResp.body());
                JsonSupport.error(resp, 502, "Payment gateway error. Please try again.");
                return;
            }

            Map<?, ?> rzpOrder = JsonSupport.MAPPER.readValue(rzpResp.body(), Map.class);
            String orderId = rzpOrder.get("id").toString();

            // Persist a PENDING payment record
            Payment payment = new Payment();
            payment.setEnquiryRef(reference);
            payment.setRazorpayOrderId(orderId);
            payment.setAmountPaise(amountPaise);
            payment.setPaymentType(paymentType);
            paymentDao.createOrder(payment);

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("orderId",      orderId);
            result.put("amount",       amountPaise);
            result.put("currency",     "INR");
            result.put("keyId",        KEY_ID);
            result.put("customerName", enquiry.getCustomerName());
            result.put("mobile",       enquiry.getMobile());
            JsonSupport.write(resp, 200, result);

        } catch (Exception e) {
            getServletContext().log("Failed to create Razorpay order", e);
            JsonSupport.error(resp, 500, "Could not create payment order");
        }
    }

    // ── Verify Signature and Confirm Booking ──────────────────────────────────

    @SuppressWarnings("unchecked")
    private void verifyPayment(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (KEY_SECRET == null) {
            JsonSupport.error(resp, 503, "Payment gateway not configured");
            return;
        }

        Map<String, Object> body;
        try {
            body = JsonSupport.MAPPER.readValue(req.getInputStream(), Map.class);
        } catch (Exception e) {
            JsonSupport.error(resp, 400, "Invalid request body");
            return;
        }

        String reference   = body.getOrDefault("reference",          "").toString().trim();
        String orderId     = body.getOrDefault("razorpayOrderId",    "").toString().trim();
        String paymentId   = body.getOrDefault("razorpayPaymentId",  "").toString().trim();
        String signature   = body.getOrDefault("razorpaySignature",  "").toString().trim();
        String paymentType = body.getOrDefault("paymentType", "ADVANCE").toString().trim();

        // Verify HMAC-SHA256 signature
        boolean valid;
        try {
            String data = orderId + "|" + paymentId;
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(KEY_SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] hash = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(hash.length * 2);
            for (byte b : hash) hex.append(String.format("%02x", b));
            valid = hex.toString().equals(signature);
        } catch (Exception e) {
            getServletContext().log("Signature verification error", e);
            JsonSupport.error(resp, 500, "Signature verification failed");
            return;
        }

        if (!valid) {
            try { paymentDao.markFailed(orderId); } catch (Exception ignore) {}
            JsonSupport.error(resp, 400, "Invalid payment signature — payment not accepted");
            return;
        }

        // Mark payment as successful
        try {
            paymentDao.markSuccess(orderId, paymentId, signature);
        } catch (Exception e) {
            getServletContext().log("Failed to mark payment success", e);
            JsonSupport.error(resp, 500, "Could not record payment");
            return;
        }

        // Update booking status
        String newStatus = "ADVANCE".equals(paymentType) ? "CONFIRMED" : "COMPLETED";
        try {
            enquiryDao.updateStatus(reference, newStatus);
        } catch (Exception e) {
            getServletContext().log("Failed to update booking status after payment", e);
            JsonSupport.error(resp, 500, "Payment recorded but booking status update failed");
            return;
        }

        // Notify owner now that payment is confirmed
        try {
            Enquiry confirmed = enquiryDao.findByReference(reference);
            if (confirmed != null) OwnerNotifier.notifyAsync(confirmed);
        } catch (Exception e) {
            getServletContext().log("Owner notification failed after payment (non-fatal)", e);
        }

        JsonSupport.write(resp, 200,
                Map.of("reference", reference, "status", newStatus, "paymentId", paymentId));
    }

    // ── Invoice ───────────────────────────────────────────────────────────────

    private void getInvoice(HttpServletResponse resp, String reference) throws IOException {
        if (reference.isBlank()) { JsonSupport.error(resp, 400, "Reference required"); return; }
        try {
            Enquiry e = enquiryDao.findByReference(reference);
            if (e == null) { JsonSupport.error(resp, 404, "Booking not found"); return; }

            long baseRentPaise  = computeBaseRentPaise(e);
            long advancePaid    = paymentDao.getTotalPaidPaise(reference, "ADVANCE");
            long balancePaid    = paymentDao.getTotalPaidPaise(reference, "BALANCE");

            boolean billingReady = e.getElecUnits() != null;
            long elecCharge       = billingReady ? Math.round(e.getElecUnits() * 4000)  : 0;
            long gasCharge        = billingReady ? Math.round(e.getGasKg()    * 18000)  : 0;
            long decorCharge      = (e.getDecorationChargePaise()    != null) ? e.getDecorationChargePaise()    : 0;
            long earlyEntryCharge = (e.getEarlyEntryChargePaise()    != null) ? e.getEarlyEntryChargePaise()    : 0;
            long keyLossCharge    = (e.getKeyLossChargePaise()       != null) ? e.getKeyLossChargePaise()       : 0;
            long totalPaise       = baseRentPaise + elecCharge + gasCharge + decorCharge + earlyEntryCharge + keyLossCharge;
            long remaining        = Math.max(0, totalPaise - advancePaid - balancePaid);

            Map<String, Object> invoice = new LinkedHashMap<>();
            invoice.put("reference",               reference);
            invoice.put("customerName",            e.getCustomerName());
            invoice.put("mobile",                  e.getMobile());
            invoice.put("eventDate",               e.getEventDate());
            invoice.put("rentalType",              e.getRentalType());
            invoice.put("functionType",            e.getFunctionType());
            invoice.put("startDatetime",           e.getStartDatetime());
            invoice.put("endDatetime",             e.getEndDatetime());
            invoice.put("status",                  e.getStatus());
            invoice.put("baseRentPaise",           baseRentPaise);
            invoice.put("advancePaidPaise",        advancePaid);
            invoice.put("balancePaidPaise",        balancePaid);
            invoice.put("elecUnits",               e.getElecUnits());
            invoice.put("elecChargePaise",         elecCharge);
            invoice.put("gasKg",                   e.getGasKg());
            invoice.put("gasChargePaise",          gasCharge);
            invoice.put("decorationChargePaise",   decorCharge);
            invoice.put("earlyEntryChargePaise",   earlyEntryCharge);
            invoice.put("keyLossChargePaise",      keyLossCharge);
            invoice.put("totalPaise",              totalPaise);
            invoice.put("remainingPaise",          remaining);
            invoice.put("billingReady",            billingReady);
            JsonSupport.write(resp, 200, invoice);
        } catch (Exception ex) {
            getServletContext().log("Invoice generation failed", ex);
            JsonSupport.error(resp, 500, "Could not generate invoice");
        }
    }

    // ── Payment History ───────────────────────────────────────────────────────

    private void getHistory(HttpServletResponse resp, String reference) throws IOException {
        if (reference.isBlank()) { JsonSupport.error(resp, 400, "Reference required"); return; }
        try {
            List<Payment> payments = paymentDao.listByRef(reference);
            JsonSupport.write(resp, 200, payments);
        } catch (Exception e) {
            JsonSupport.error(resp, 500, "Could not load payment history");
        }
    }

    // ── Rent Computation ─────────────────────────────────────────────────────

    public static long computeBaseRentPaise(Enquiry enquiry) {
        return switch (enquiry.getRentalType() == null ? "" : enquiry.getRentalType()) {
            case "FULL_DAY" -> {
                long days = 1;
                if (enquiry.getEndDate() != null && enquiry.getEventDate() != null
                        && enquiry.getEndDate().isAfter(enquiry.getEventDate())) {
                    days = java.time.temporal.ChronoUnit.DAYS.between(
                            enquiry.getEventDate(), enquiry.getEndDate()) + 1;
                }
                yield days * 3_500_000L;   // ₹35,000 per day (₹32,000 rent + ₹3,000 security)
            }
            case "HALF_DAY" -> 2_300_000L;
            case "HOURLY"   -> {
                if (enquiry.getStartDatetime() != null && enquiry.getEndDatetime() != null) {
                    long hrs = java.time.Duration.between(
                            enquiry.getStartDatetime(), enquiry.getEndDatetime()).toHours();
                    yield Math.max(2, hrs) * 300_000L;
                }
                yield 600_000L; // 2hr minimum fallback
            }
            default -> 0L;
        };
    }
}
