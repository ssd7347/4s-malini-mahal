# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -q
COPY src ./src
RUN mvn package -q -DskipTests

# ── Stage 2: Run ────────────────────────────────────────────────────────────
FROM tomcat:10.1-jdk17-temurin

# Remove Tomcat's default example webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the built WAR
COPY --from=build /app/target/malinimahal.war /usr/local/tomcat/webapps/malinimahal.war

# All secrets (DB_URL, DB_USER, DB_PASSWORD, ADMIN_PASSWORD,
# RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, OWNER_EMAIL,
# EMAIL_SMTP_HOST, EMAIL_USERNAME, EMAIL_PASSWORD, EMAIL_FROM)
# are injected as environment variables from Koyeb — not hardcoded here.

EXPOSE 8080
CMD ["catalina.sh", "run"]
