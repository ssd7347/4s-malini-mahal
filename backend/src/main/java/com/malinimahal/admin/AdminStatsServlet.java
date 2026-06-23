package com.malinimahal.admin;

import com.malinimahal.enquiry.EnquiryDao;
import com.malinimahal.web.JsonSupport;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.time.YearMonth;
import java.time.ZoneId;
import java.util.Map;

/**
 * GET /api/admin/stats?month=YYYY-MM
 * Returns bookings count, billing collected, and occupancy rate for the given month.
 */
@WebServlet("/api/admin/stats")
public class AdminStatsServlet extends HttpServlet {

    private final EnquiryDao dao = new EnquiryDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String month = req.getParameter("month");
        if (month == null || !month.matches("\\d{4}-\\d{2}")) {
            month = YearMonth.now(ZoneId.of("Asia/Kolkata")).toString();
        }
        try {
            Map<String, Object> stats = dao.statsForMonth(month);
            JsonSupport.write(resp, HttpServletResponse.SC_OK, stats);
        } catch (Exception e) {
            getServletContext().log("Failed to fetch stats for month " + month, e);
            JsonSupport.error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not load stats");
        }
    }
}
