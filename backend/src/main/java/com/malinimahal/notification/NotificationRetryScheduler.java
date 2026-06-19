package com.malinimahal.notification;

import com.malinimahal.enquiry.Enquiry;
import com.malinimahal.enquiry.EnquiryDao;
import com.malinimahal.notification.NotificationDao.NotificationRetry;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;

@WebListener
public class NotificationRetryScheduler implements ServletContextListener {

    private static final Logger LOG = Logger.getLogger(NotificationRetryScheduler.class.getName());
    private static final int MAX_ATTEMPTS = 3;

    private ScheduledExecutorService scheduler;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "notification-retry");
            t.setDaemon(true);
            return t;
        });
        // First run after 5 minutes, then every 5 minutes
        scheduler.scheduleAtFixedRate(this::runRetries, 5, 5, TimeUnit.MINUTES);
        LOG.info("NotificationRetryScheduler started.");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null) {
            scheduler.shutdownNow();
        }
    }

    private void runRetries() {
        NotificationDao notifDao  = new NotificationDao();
        EnquiryDao      enquiryDao = new EnquiryDao();
        try {
            List<NotificationRetry> due = notifDao.findDueRetries(MAX_ATTEMPTS);
            if (due.isEmpty()) return;
            LOG.info("Retry scheduler: processing " + due.size() + " due notification(s).");
            for (NotificationRetry retry : due) {
                try {
                    Enquiry enquiry = enquiryDao.findByReference(retry.enquiryRef());
                    if (enquiry == null) {
                        LOG.warning("Retry: enquiry not found for ref=" + retry.enquiryRef());
                        continue;
                    }
                    NotificationPayload payload = new NotificationPayload(enquiry);
                    OwnerNotifier.retryChannel(retry.id(), retry.channel(), payload);
                } catch (Exception e) {
                    LOG.warning("Retry failed for logId=" + retry.id() + ": " + e.getMessage());
                }
            }
        } catch (Exception e) {
            LOG.warning("NotificationRetryScheduler runRetries error: " + e.getMessage());
        }
    }
}
