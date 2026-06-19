package com.malinimahal.notification;

import jakarta.mail.*;
import jakarta.mail.internet.*;

import java.util.Properties;
import java.util.logging.Logger;

public class EmailSender {

    private static final Logger LOG = Logger.getLogger(EmailSender.class.getName());

    private static final String HOST;
    private static final String PORT;
    private static final String USERNAME;
    private static final String PASSWORD;
    private static final String FROM;

    static {
        HOST     = System.getenv("EMAIL_SMTP_HOST");
        String p = System.getenv("EMAIL_SMTP_PORT");
        PORT     = (p != null && !p.isBlank()) ? p : "587";
        USERNAME = System.getenv("EMAIL_USERNAME");
        PASSWORD = System.getenv("EMAIL_PASSWORD");
        FROM     = System.getenv("EMAIL_FROM");
    }

    public static boolean isConfigured() {
        return HOST != null && !HOST.isBlank()
            && USERNAME != null && !USERNAME.isBlank()
            && PASSWORD != null && !PASSWORD.isBlank();
    }

    public static boolean send(String to, String subject, String htmlBody) {
        if (!isConfigured()) {
            LOG.warning("EmailSender: not configured, skipping.");
            return false;
        }
        try {
            Properties props = new Properties();
            props.put("mail.smtp.host", HOST);
            props.put("mail.smtp.port", PORT);
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.starttls.enable", "true");

            Session session = Session.getInstance(props, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(USERNAME, PASSWORD);
                }
            });

            String from = (FROM != null && !FROM.isBlank()) ? FROM : USERNAME;
            MimeMessage msg = new MimeMessage(session);
            msg.setFrom(new InternetAddress(from));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            msg.setSubject(subject, "UTF-8");
            msg.setContent(htmlBody, "text/html; charset=UTF-8");

            Transport.send(msg);
            LOG.info("Email sent to " + to);
            return true;
        } catch (Exception e) {
            LOG.warning("Email send failed to " + to + ": " + e.getMessage());
            return false;
        }
    }
}
