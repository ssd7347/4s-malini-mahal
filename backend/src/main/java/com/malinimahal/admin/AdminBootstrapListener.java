package com.malinimahal.admin;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

/**
 * On startup, seeds the first admin user if none exists. Username/password come
 * from the ADMIN_USERNAME / ADMIN_PASSWORD environment variables (defaults:
 * "admin" / a value you must set). This avoids ever committing a password.
 */
@WebListener
public class AdminBootstrapListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        try {
            AdminDao dao = new AdminDao();
            if (dao.count() > 0) {
                return;
            }
            String username = envOrDefault("ADMIN_USERNAME", "admin");
            String password = System.getenv("ADMIN_PASSWORD");
            if (password == null || password.isBlank()) {
                sce.getServletContext().log(
                        "No admin user exists and ADMIN_PASSWORD is not set — skipping admin seed. "
                        + "Set ADMIN_PASSWORD and restart to create the first admin.");
                return;
            }
            dao.create(username, PasswordHasher.hash(password));
            sce.getServletContext().log("Seeded initial admin user '" + username + "'.");
        } catch (Exception e) {
            sce.getServletContext().log("Failed to seed admin user", e);
        }
    }

    private static String envOrDefault(String key, String fallback) {
        String v = System.getenv(key);
        return (v != null && !v.isBlank()) ? v : fallback;
    }
}
