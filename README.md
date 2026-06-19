# 4S Malini Mahal — Booking & Management System

Booking and management system for **4S Malini Mahal**, a mini banquet hall in
Thiruthangal, Sivakasi.

## Project structure

```
4s Malini Mahal/
├── backend/      Java Servlets (Jakarta EE 10) on Tomcat 10, builds to a WAR
└── frontend/     Ember.js + Tailwind CSS single-page app
```

## Tech stack

| Layer        | Technology                         |
|--------------|------------------------------------|
| Frontend     | Ember.js, Tailwind CSS             |
| Backend      | Java 17 Servlets (Jakarta 6.0)     |
| App server   | Apache Tomcat 10.1                  |
| Build        | Apache Maven                       |
| Database     | PostgreSQL 17                      |

> **Important:** Tomcat 10 uses the `jakarta.*` namespace, **not** `javax.*`.
> All servlet imports are `jakarta.servlet.*` and the API dependency is
> `jakarta.servlet:jakarta.servlet-api:6.0.0`.

## Backend — build & run

```sh
# 1. Create the database and tables (once)
psql -U postgres -c "CREATE DATABASE malinimahal;"
psql -U postgres -d malinimahal -f backend/db/schema.sql

# 2. Set the DB password (either edit backend/src/main/resources/application.properties
#    or, preferred, set environment variables):
#    DB_URL, DB_USER, DB_PASSWORD

# 3. Build the WAR
cd backend
mvn clean package
#    -> backend/target/malinimahal.war

# 4. Deploy: copy the WAR into Tomcat and start it
copy target\malinimahal.war "%CATALINA_HOME%\webapps\"
"%CATALINA_HOME%\bin\startup.bat"

# App is then at:  http://localhost:8080/malinimahal/api/health
```

Health check should return `{"status":"ok","database":"up"}`.

### API endpoints

| Method | Path                                  | Purpose                                        |
|--------|---------------------------------------|------------------------------------------------|
| GET    | `/api/health`                         | Health + DB connectivity check                 |
| POST   | `/api/enquiries`                      | Submit an enquiry, returns a reference         |
| GET    | `/api/enquiries/{ref}`                | Track an enquiry by its reference              |
| GET    | `/api/availability?date=yyyy-MM-dd`   | Public availability (AVAILABLE/UNDER_ENQUIRY/UNAVAILABLE) |
| POST   | `/api/admin/login`                    | Admin login (starts a session)                 |
| POST   | `/api/admin/logout`                   | Admin logout                                   |
| GET    | `/api/admin/me`                       | Current admin (401 if not logged in)           |
| GET    | `/api/admin/enquiries`                | List all enquiries (admin)                     |
| POST   | `/api/admin/enquiries/{ref}/status`   | Update an enquiry's status (admin)             |
| GET    | `/api/admin/blocked-dates`            | List blocked dates (admin)                     |
| POST   | `/api/admin/blocked-dates`            | Block a date (admin)                           |
| DELETE | `/api/admin/blocked-dates/{date}`     | Unblock a date (admin)                         |

**Admin auth:** session-based, with PBKDF2-hashed passwords. The first admin is
seeded on startup from `ADMIN_USERNAME` (default `admin`) and `ADMIN_PASSWORD`
environment variables — set `ADMIN_PASSWORD` before first launch or no admin is
created. (WhatsApp OTP can be layered on later without changing the rest.)
The admin UI is at `/admin`.

Example create:

```sh
curl -X POST http://localhost:8080/malinimahal/api/enquiries \
  -H "Content-Type: application/json" \
  -d '{"customerName":"Test","mobile":"9876543210","eventDate":"2026-08-15","eventType":"Wedding","rentalType":"FULL_DAY"}'
```

## Frontend — run

```sh
cd frontend
npm install      # first time only
npm start        # dev server at http://localhost:4200
```

## Local tooling (installed)

JDK 17 · Maven 3.9.16 (`C:\tools\apache-maven-3.9.16`) ·
Tomcat 10.1.55 (`C:\tools\apache-tomcat-10.1.55`, `CATALINA_HOME`) ·
PostgreSQL 17 (service `postgresql-x64-17`, port 5432) ·
Node 24 LTS · Ember CLI 7
