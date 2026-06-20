package com.malinimahal.notification;

import com.malinimahal.auth.SmsSender;
import com.malinimahal.auth.WhatsAppSender;
import com.malinimahal.enquiry.Enquiry;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.concurrent.CompletableFuture;
import java.util.logging.Logger;

public class OwnerNotifier {

    private static final Logger LOG = Logger.getLogger(OwnerNotifier.class.getName());
    private static final int MAX_ATTEMPTS  = 3;
    private static final int RETRY_MINUTES = 5;

    private static final String OWNER_MOBILE;
    private static final String OWNER_EMAIL;
    private static final String WA_ENABLED;

    static {
        OWNER_MOBILE = System.getenv("OWNER_MOBILE");
        OWNER_EMAIL  = System.getenv("OWNER_EMAIL");
        WA_ENABLED   = System.getenv("WA_ENABLED");
    }

    private static final NotificationDao dao = new NotificationDao();

    /** Called after successful advance payment. */
    public static void notifyAsync(Enquiry saved) {
        sendAsync(new NotificationPayload(saved), saved.getReference());
    }

    /** Called after the customer reschedules a confirmed booking. */
    public static void notifyRescheduleAsync(Enquiry rescheduled, LocalDate oldDate) {
        sendAsync(NotificationPayload.forReschedule(rescheduled, oldDate), rescheduled.getReference());
    }

    /** Called after the customer cancels a booking. */
    public static void notifyCancellationAsync(Enquiry cancelled) {
        sendAsync(NotificationPayload.forCancellation(cancelled), cancelled.getReference());
    }

    private static void sendAsync(NotificationPayload payload, String enquiryRef) {
        CompletableFuture.runAsync(() -> {
            sendChannel("whatsapp", enquiryRef, payload);
            sendChannel("sms",      enquiryRef, payload);
            sendChannel("email",    enquiryRef, payload);
        }).exceptionally(ex -> {
            LOG.warning("OwnerNotifier async task error: " + ex.getMessage());
            return null;
        });
    }

    /** Called by the retry scheduler for a previously-failed log entry. */
    static void retryChannel(long logId, String channel, NotificationPayload payload) {
        try {
            int priorAttempts = dao.getAttempts(logId);
            doSend(logId, channel, payload, priorAttempts);
        } catch (Exception e) {
            LOG.warning("OwnerNotifier retryChannel logId=" + logId + " channel=" + channel + ": " + e.getMessage());
        }
    }

    private static void sendChannel(String channel, String enquiryRef, NotificationPayload payload) {
        if (!isChannelEnabled(channel)) return;
        try {
            long logId = dao.insertPending(enquiryRef, channel);
            doSend(logId, channel, payload, 0);
        } catch (Exception e) {
            LOG.warning("OwnerNotifier failed to start channel=" + channel + " ref=" + enquiryRef + ": " + e.getMessage());
        }
    }

    private static void doSend(long logId, String channel, NotificationPayload payload, int priorAttempts) {
        boolean ok = false;
        String error = null;
        try {
            ok = switch (channel) {
                case "whatsapp" -> WhatsAppSender.send(OWNER_MOBILE, payload.toMessageText());
                case "sms"      -> SmsSender.sendNotification(OWNER_MOBILE, payload.toMessageText());
                case "email"    -> EmailSender.send(OWNER_EMAIL, payload.toEmailSubject(), payload.toEmailHtml());
                default         -> { LOG.warning("Unknown notification channel: " + channel); yield false; }
            };
        } catch (Exception e) {
            error = e.getMessage();
        }

        try {
            if (ok) {
                dao.markSent(logId);
                LOG.info("Notification sent: channel=" + channel + " logId=" + logId);
            } else {
                int totalAttempts = priorAttempts + 1;
                boolean canRetry  = totalAttempts < MAX_ATTEMPTS;
                OffsetDateTime nextRetry = canRetry ? OffsetDateTime.now().plusMinutes(RETRY_MINUTES) : null;
                dao.markFailed(logId, error != null ? error : "send returned false", nextRetry);
                LOG.warning("Notification failed (attempt " + totalAttempts + ")"
                    + (canRetry ? ", will retry in " + RETRY_MINUTES + " min" : ", permanently failed")
                    + ": channel=" + channel + " logId=" + logId);
            }
        } catch (Exception ex) {
            LOG.warning("Could not update notification_log logId=" + logId + ": " + ex.getMessage());
        }
    }

    private static boolean isChannelEnabled(String channel) {
        return switch (channel) {
            case "whatsapp" -> "true".equalsIgnoreCase(WA_ENABLED)
                               && OWNER_MOBILE != null && !OWNER_MOBILE.isBlank();
            case "sms"      -> SmsSender.isConfigured()
                               && OWNER_MOBILE != null && !OWNER_MOBILE.isBlank();
            case "email"    -> EmailSender.isConfigured()
                               && OWNER_EMAIL != null && !OWNER_EMAIL.isBlank();
            default         -> false;
        };
    }
}
