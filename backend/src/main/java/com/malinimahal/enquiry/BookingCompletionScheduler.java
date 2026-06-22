package com.malinimahal.enquiry;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@WebListener
public class BookingCompletionScheduler implements ServletContextListener {

    private ScheduledExecutorService scheduler;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        scheduler = Executors.newSingleThreadScheduledExecutor();
        // Run 1 minute after startup, then every 15 minutes
        scheduler.scheduleAtFixedRate(this::autoComplete, 1, 15, TimeUnit.MINUTES);
        sce.getServletContext().log("BookingCompletionScheduler started.");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null) scheduler.shutdownNow();
    }

    private void autoComplete() {
        try {
            EnquiryDao dao = new EnquiryDao();
            List<String> refs = dao.findReferencesForAutoComplete();
            for (String ref : refs) {
                dao.updateStatus(ref, "COMPLETED");
            }
            if (!refs.isEmpty()) {
                System.out.println("[BookingCompletionScheduler] Auto-completed " + refs.size() + " booking(s): " + refs);
            }
        } catch (Exception e) {
            System.err.println("[BookingCompletionScheduler] Error: " + e.getMessage());
        }
    }
}
