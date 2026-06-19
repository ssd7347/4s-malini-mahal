package com.malinimahal.receipt;

import com.malinimahal.enquiry.Enquiry;
import com.malinimahal.enquiry.EnquiryDao;
import com.malinimahal.payment.PaymentDao;
import com.malinimahal.terms.TermsVersion;
import com.malinimahal.terms.TermsVersionDao;
import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

@WebServlet(urlPatterns = "/api/receipts/*")
public class ReceiptServlet extends HttpServlet {

    private final EnquiryDao      enquiryDao = new EnquiryDao();
    private final PaymentDao      paymentDao = new PaymentDao();
    private final TermsVersionDao termsDao   = new TermsVersionDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getPathInfo();
        if (path == null || path.length() <= 1) {
            JsonSupport.error(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing booking reference");
            return;
        }
        String reference = path.substring(1).trim().toUpperCase();

        try {
            Enquiry e = enquiryDao.findByReference(reference);
            if (e == null) {
                JsonSupport.error(resp, HttpServletResponse.SC_NOT_FOUND, "Booking not found");
                return;
            }

            long advancePaidPaise = 0;
            try {
                advancePaidPaise = paymentDao.getTotalPaidPaise(reference, "ADVANCE");
            } catch (Exception ignore) { /* non-fatal */ }

            String termsEnglish = null;
            String termsTamil   = null;
            try {
                TermsVersion tv = termsDao.findActive();
                if (tv != null) {
                    termsEnglish = tv.getEnglishText();
                    termsTamil   = tv.getTamilText();
                }
            } catch (Exception ignore) { /* non-fatal */ }

            Map<String, Object> receipt = new LinkedHashMap<>();
            receipt.put("reference",        e.getReference());
            receipt.put("customerName",     e.getCustomerName());
            receipt.put("mobile",           e.getMobile());
            receipt.put("eventDate",        e.getEventDate()      != null ? e.getEventDate().toString()      : null);
            receipt.put("rentalType",       e.getRentalType());
            receipt.put("functionType",     e.getFunctionType());
            receipt.put("startDatetime",    e.getStartDatetime()  != null ? e.getStartDatetime().toString()  : null);
            receipt.put("endDatetime",      e.getEndDatetime()    != null ? e.getEndDatetime().toString()    : null);
            receipt.put("status",           e.getStatus());
            receipt.put("muhurtham",        e.isMuhurtham());
            receipt.put("createdAt",        e.getCreatedAt()      != null ? e.getCreatedAt().toString()      : null);
            receipt.put("advancePaidPaise", advancePaidPaise);
            receipt.put("termsEnglish",     termsEnglish);
            receipt.put("termsTamil",       termsTamil);

            JsonSupport.write(resp, HttpServletResponse.SC_OK, receipt);
        } catch (Exception ex) {
            getServletContext().log("Receipt generation failed for " + reference, ex);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not generate receipt");
        }
    }
}
