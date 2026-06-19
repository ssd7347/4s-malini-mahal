package com.malinimahal.db;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Minimal PostgreSQL connection helper.
 *
 * Configuration is read from {@code application.properties} on the classpath,
 * and any value can be overridden by an environment variable (handy for
 * deployment where you do not want secrets in a file):
 *
 *   DB_URL, DB_USER, DB_PASSWORD
 *
 * NOTE: This uses DriverManager (one connection per call) to keep the scaffold
 * dependency-light. Before real load, swap in a connection pool (e.g. HikariCP)
 * -- left out deliberately so we add it together when needed.
 */
public final class Database {

    private static final String url;
    private static final String user;
    private static final String password;

    static {
        Properties props = new Properties();
        try (InputStream in = Database.class.getClassLoader()
                .getResourceAsStream("application.properties")) {
            if (in != null) {
                props.load(in);
            }
        } catch (Exception e) {
            throw new ExceptionInInitializerError(e);
        }
        url = env("DB_URL", props.getProperty("db.url"));
        user = env("DB_USER", props.getProperty("db.user"));
        password = env("DB_PASSWORD", props.getProperty("db.password"));

        // Explicitly load the driver so it registers with DriverManager.
        // In a servlet container the JDBC driver lives in WEB-INF/lib, which
        // DriverManager's automatic ServiceLoader scan does not always see.
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            throw new ExceptionInInitializerError(e);
        }
    }

    private Database() {
    }

    private static String env(String key, String fallback) {
        String v = System.getenv(key);
        return (v != null && !v.isBlank()) ? v : fallback;
    }

    /** Caller is responsible for closing the returned connection (use try-with-resources). */
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(url, user, password);
    }
}
