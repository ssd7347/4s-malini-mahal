package com.malinimahal.admin;

import com.malinimahal.enquiry.Enquiry;
import com.malinimahal.enquiry.EnquiryDao;
import com.malinimahal.payment.PaymentDao;
import com.malinimahal.refund.RefundDao;
import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Admin enquiry management (requires ADMIN session — enforced by AuthFilter):
 *   GET  /api/admin/enquiries                   list all enquiries, newest first
 *   POST /api/admin/enquiries/{ref}/status      change enquiry status
 *   POST /api/admin/enquiries/{ref}/billing     enter post-event billing charges
 */
@WebServlet(urlPatterns = {"/api/admin/enquiries", "/api/admin/enquiries/*"})
public class AdminEnquiryServlet extends HttpServlet {

    private static final Set<String> VALID_STATUSES = Set.of(
            "NEW", "UNDER_ENQUIRY", "AWAITING_PAYMENT", "CONFIRMED", "DECLINED",
            "CANCELLED", "COMPLETED", "REJECTED");

    private final EnquiryDao dao        = new EnquiryDao();
    private final PaymentDao paymentDao = new PaymentDao();
    private final RefundDao  refundDao  = new RefundDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if ("/export".equals(req.getPathInfo())) {
            handleExport(req, resp);
            return;
        }
        try {
            JsonSupport.write(resp, HttpServletResponse.SC_OK, dao.listAll());
        } catch (Exception e) {
            getServletContext().log("Failed to list enquiries", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not load enquiries");
        }
    }

    private void handleExport(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String month = req.getParameter("month");
        try {
            List<Enquiry> list = (month != null && month.matches("\\d{4}-\\d{2}"))
                    ? dao.listForMonth(month)
                    : dao.listAll();
            resp.setContentType("text/csv; charset=UTF-8");
            resp.setHeader("Content-Disposition", "attachment; filename=\"bookings.csv\"");
            PrintWriter w = resp.getWriter();
            w.println("Reference,Name,Mobile,Event Date,End Date,Rental Type,Function Type,Status," +
                      "Elec Units,Gas Kg,Decoration (Rs),Early Entry (Rs),Key Loss (Rs),Created At");
            for (Enquiry e : list) {
                w.println(String.join(",",
                    csv(e.getReference()),
                    csv(e.getCustomerName()),
                    csv(e.getMobile()),
                    e.getEventDate()             != null ? e.getEventDate().toString()                         : "",
                    e.getEndDate()               != null ? e.getEndDate().toString()                           : "",
                    csv(e.getRentalType()),
                    csv(e.getFunctionType()),
                    csv(e.getStatus()),
                    e.getElecUnits()             != null ? e.getElecUnits().toString()                         : "",
                    e.getGasKg()                 != null ? e.getGasKg().toString()                             : "",
                    e.getDecorationChargePaise() != null ? String.valueOf(e.getDecorationChargePaise() / 100.0) : "",
                    e.getEarlyEntryChargePaise() != null ? String.valueOf(e.getEarlyEntryChargePaise() / 100.0) : "",
                    e.getKeyLossChargePaise()    != null ? String.valueOf(e.getKeyLossChargePaise()    / 100.0) : "",
                    e.getCreatedAt()             != null ? e.getCreatedAt().toString()                         : ""
                ));
            }
            w.flush();
        } catch (Exception e) {
            getServletContext().log("Failed to export enquiries", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Export failed");
        }
    }

    private static String csv(String s) {
        if (s == null) return "";
        if (s.contains(",") || s.contains("\"") || s.contains("\n") || s.contains("\r")) {
            return "\"" + s.replace("\"", "\"\"") + "\"";
        }
        return s;
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getPathInfo();
        if (path != null && path.endsWith("/billing")) {
            String reference = path.substring(1, path.length() - "/billing".length());
            saveBilling(req, resp, reference);
            return;
        }
        if (path == null || !path.endsWith("/status")) {
            JsonSupport.error(resp, HttpServletResponse.SC_NOT_FOUND, "Unknown action");
            return;
        }
        String reference = path.substring(1, path.length() - "/status".length());
        if (reference.isBlank()) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing enquiry reference");
            return;
        }

        Map<String, String> body;
        try {
            body = JsonSupport.MAPPER.readValue(req.getInputStream(), Map.class);
        } catch (Exception e) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Invalid request body");
            return;
        }
        String status = body.getOrDefault("status", "").trim();
        if (!VALID_STATUSES.contains(status)) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST,
                    "Status must be one of " + VALID_STATUSES);
            return;
        }

        // Block confirmation if the time slot conflicts with another confirmed booking
        if ("CONFIRMED".equals(status)) {
            Enquiry enquiry;
            try {
                enquiry = dao.findByReference(reference);
            } catch (Exception e) {
                getServletContext().log("Conflict check: failed to look up enquiry", e);
                JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not look up enquiry");
                return;
            }
            if (enquiry == null) {
                JsonSupport.error(resp, HttpServletResponse.SC_NOT_FOUND, "No enquiry with that reference");
                return;
            }
            if (enquiry.getStartDatetime() != null && enquiry.getEndDatetime() != null) {
                boolean conflict;
                try {
                    conflict = dao.hasConflict(enquiry.getRentalType(), enquiry.getStartDatetime(), enquiry.getEndDatetime(), reference);
                } catch (Exception e) {
                    getServletContext().log("Conflict check failed", e);
                    JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not check availability");
                    return;
                }
                if (conflict) {
                    JsonSupport.error(resp, HttpServletResponse.SC_CONFLICT,
                            "This time slot overlaps with an existing confirmed booking " +
                            "(including the 1-hour cleaning gap). Cannot confirm.");
                    return;
                }
            }
        }

        // When cancelling a CONFIRMED booking: create a refund record if advance was paid
        if ("CANCELLED".equals(status)) {
            try {
                Enquiry enquiry = dao.findByReference(reference);
                if (enquiry != null && "CONFIRMED".equals(enquiry.getStatus())) {
                    long advancePaid = paymentDao.getTotalPaidPaise(reference, "ADVANCE");
                    if (advancePaid > 0) {
                        refundDao.create(reference, enquiry.isMuhurtham(), advancePaid);
                    }
                }
            } catch (Exception e) {
                getServletContext().log("Could not create refund record for cancellation", e);
            }
        }

        try {
            boolean updated = dao.updateStatus(reference, status);
            if (!updated) {
                JsonSupport.error(resp, HttpServletResponse.SC_NOT_FOUND, "No enquiry with that reference");
                return;
            }
            JsonSupport.write(resp, HttpServletResponse.SC_OK, Map.of("reference", reference, "status", status));
        } catch (Exception e) {
            getServletContext().log("Failed to update enquiry status", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not update status");
        }
    }

    @SuppressWarnings("unchecked")
    private void saveBilling(HttpServletRequest req, HttpServletResponse resp, String reference)
            throws IOException {
        if (reference.isBlank()) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing enquiry reference");
            return;
        }
        Map<String, Object> body;
        try {
            body = JsonSupport.MAPPER.readValue(req.getInputStream(), Map.class);
        } catch (Exception e) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Invalid request body");
            return;
        }

        Double elecUnits = null;
        Double gasKg = null;
        Long decorPaise = null;
        Long earlyEntryPaise = null;
        Long keyLossPaise = null;

        try {
            Object eu = body.get("elecUnits");
            if (eu != null) elecUnits = ((Number) eu).doubleValue();
            Object gk = body.get("gasKg");
            if (gk != null) gasKg = ((Number) gk).doubleValue();
            Object dp = body.get("decorationChargePaise");
            if (dp != null) decorPaise = ((Number) dp).longValue();
            Object ee = body.get("earlyEntryChargePaise");
            if (ee != null) earlyEntryPaise = ((Number) ee).longValue();
            Object kl = body.get("keyLossChargePaise");
            if (kl != null) keyLossPaise = ((Number) kl).longValue();
        } catch (ClassCastException e) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Invalid billing values");
            return;
        }

        try {
            boolean updated = dao.updateBilling(reference, elecUnits, gasKg, decorPaise, earlyEntryPaise, keyLossPaise);
            if (!updated) {
                JsonSupport.error(resp, HttpServletResponse.SC_NOT_FOUND, "No enquiry with that reference");
                return;
            }
            JsonSupport.write(resp, HttpServletResponse.SC_OK,
                    Map.of("reference", reference, "billingUpdated", true));
        } catch (Exception e) {
            getServletContext().log("Failed to save billing", e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not save billing");
        }
    }
}
