# 4S Malini Mahal — Complete Project Reference

> This file is the single source of truth for the project.
> Claude updates this file after every significant action.
> Last updated: 2026-06-20

---

## 1. What Is This Project

**4S Malini Mahal** is a banquet hall booking and management system built for a real hall.
It lets customers browse the hall, submit booking enquiries, pay the advance online, and download a receipt.
The hall owner/admin manages all bookings, payments, gallery, terms, and blocked dates through an admin portal.

---

## 2. How the System Works (Big Picture)

```
Customer (browser)
      │
      ▼
Ember.js SPA  ──────────────────────────────────────────────────
(served from Tomcat ROOT at localhost:8080/)                   │
      │                                                        │
      │  REST API calls to /malinimahal/api/...               │
      ▼                                                        │
Java Servlets (malinimahal.war)                                │
(Tomcat context /malinimahal at localhost:8080/malinimahal/)   │
      │                                                        │
      ├──▶ PostgreSQL 17 (localhost:5432, DB: malinimahal)    │
      │                                                        │
      ├──▶ Razorpay API (payment gateway)                     │
      │                                                        │
      └──▶ WhatsApp Business API (OTP + notifications)        │
                                                               │
Admin (browser) ───────────────────────────────────────────────
(same SPA, /admin route, OTP-protected)
```

---

## 3. Software Used

| Software | Version | Purpose | How Used |
|---|---|---|---|
| Java JDK | 17 | Backend runtime | All servlet/DAO code compiled and run on JDK 17 |
| Apache Tomcat | 10.1.55 | Web server | Hosts the backend WAR (`/malinimahal`) and the frontend static files (`ROOT`) |
| PostgreSQL | 17 | Database | Stores all data — bookings, customers, payments, gallery, etc. Windows service `postgresql-x64-17` |
| Apache Maven | 3.9.16 | Backend build | Compiles Java, packages `malinimahal.war`. Located at `C:\tools\apache-maven-3.9.16\` |
| Node.js | 24 LTS | Frontend runtime | Required to run Ember CLI and npm. Located at `C:\Program Files\nodejs\` |
| npm | (with Node) | Package manager | Installs Ember dependencies |
| Ember.js | 7.0.0 | Frontend framework | SPA framework. Strict mode `.gjs` files with Glimmer components |
| Embroider | latest | Ember build pipeline | Modern Ember build system using Vite under the hood |
| Vite | (via Embroider) | Bundler | Bundles the frontend JS/CSS into `dist/` |
| Glimmer | (with Ember) | Component model | All UI components are `.gjs` files using `@tracked`, `@action`, `@service` |
| Tailwind CSS | v4 | Styling | Utility-first CSS. Stone/rose palette for main site; amber palette for amenities |
| Jakarta Servlet API | 6.0 | Servlet spec | The API the Java servlets implement. "provided" scope — Tomcat supplies it |
| PostgreSQL JDBC | 42.7.4 | DB driver | Java connects to PostgreSQL through this driver |
| Jackson Databind | 2.18.2 | JSON library | Serializes Java objects to/from JSON for REST API responses |
| Jackson JSR310 | 2.18.2 | Java time support | Lets Jackson handle `LocalDate`, `OffsetDateTime` as ISO strings |
| Eclipse Angus Mail | 2.0.3 | Email (Jakarta Mail) | Used for email notifications to the hall owner |
| Razorpay | (REST API) | Payment gateway | Accepts UPI, cards, net banking. Test mode active |
| WhatsApp Business API | (REST) | OTP + notifications | Sends OTP codes for login; notifies owner on new booking |
| ngrok | free plan | Temporary public URL | Tunnels localhost:8080 to internet for testing |
| Git | — | Version control | All code versioned locally on `master` branch |
| IntelliJ IDEA | 2025.2 | IDE | Development environment |
| Claude Code | — | AI assistant | Used to build the entire project |

---

## 4. Directory Structure

```
C:\Users\sivas\Desktop\4s Malini Mahal\
│
├── frontend/                          # Ember.js SPA
│   ├── app/
│   │   ├── components/                # All UI components (.gjs files)
│   │   │   ├── nav-bar.gjs            # Navigation bar (desktop + mobile)
│   │   │   ├── home-page.gjs          # Landing page
│   │   │   ├── gallery-grid.gjs       # Photo/video gallery with lightbox
│   │   │   ├── amenities-page.gjs     # 8 amenity cards with gold icons
│   │   │   ├── enquiry-form.gjs       # Booking form → redirects to /payment on submit
│   │   │   ├── my-bookings.gjs        # "Your Bookings" section on home page (logged-in only)
│   │   │   ├── login-form.gjs         # OTP login (WhatsApp)
│   │   │   ├── payment-page.gjs       # Razorpay payment page
│   │   │   ├── admin-portal.gjs       # Full admin dashboard
│   │   │   ├── clock-time-picker.gjs  # Custom time picker
│   │   │   ├── date-picker-calendar.gjs # Custom date picker
│   │   │   └── admin-calendar.gjs     # Admin calendar view
│   │   ├── templates/                 # Route templates
│   │   │   ├── amenities.gjs
│   │   │   ├── payment.gjs
│   │   │   └── ...
│   │   ├── routes/                    # Ember route files
│   │   │   ├── booking.js             # Public (no login wall)
│   │   │   ├── gallery.js             # Public
│   │   │   ├── login.js               # Redirects if already logged in
│   │   │   ├── admin.js               # Requires admin role
│   │   │   └── payment.js             # Public (accessed via Pay Link)
│   │   ├── services/
│   │   │   ├── auth.js                # Auth state (isLoggedIn, user, returnTo)
│   │   │   └── language.js            # Tamil/English toggle
│   │   ├── utils/
│   │   │   └── api.js                 # apiUrl() — resolves backend base URL at runtime
│   │   └── router.js                  # All SPA routes
│   ├── dist/                          # Built output (deployed to Tomcat ROOT)
│   └── package.json
│
├── backend/                           # Java Maven WAR project
│   ├── src/main/java/com/malinimahal/
│   │   ├── auth/
│   │   │   ├── OtpServlet.java         # /api/auth/* (OTP send/verify, logout, me)
│   │   │   ├── SchemaInitializer.java  # Creates all DB tables on startup
│   │   │   └── WhatsAppSender.java     # Sends OTP via WhatsApp API
│   │   ├── enquiry/
│   │   │   ├── EnquiryServlet.java     # POST /api/enquiries
│   │   │   ├── EnquiryDao.java         # DB operations for enquiries
│   │   │   └── Enquiry.java            # Enquiry model class
│   │   ├── payment/
│   │   │   ├── PaymentServlet.java     # /api/payments/* (create-order, verify, invoice)
│   │   │   ├── PaymentDao.java         # DB operations for payments
│   │   │   └── Payment.java            # Payment model class
│   │   ├── admin/
│   │   │   ├── AdminEnquiryServlet.java # /api/admin/enquiries/* (list, status change, billing)
│   │   │   ├── AuthFilter.java          # Protects all /api/admin/* routes
│   │   │   └── ...                      # Other admin servlets
│   │   ├── gallery/
│   │   │   └── GalleryServlet.java      # /api/gallery — photo/video CRUD
│   │   ├── media/
│   │   │   └── MediaServlet.java        # /api/media/:filename — file serving
│   │   ├── receipt/
│   │   │   └── ReceiptServlet.java      # /api/receipts/:ref — PDF receipt
│   │   ├── terms/
│   │   │   └── ...                      # Terms & Conditions management
│   │   ├── refund/
│   │   │   └── ...                      # Refund tracking
│   │   ├── notification/
│   │   │   └── ...                      # Notification log + retry scheduler
│   │   ├── db/
│   │   │   └── Database.java           # getConnection() via DriverManager
│   │   └── web/
│   │       ├── JsonSupport.java         # Jackson helpers (write, error)
│   │       └── CorsFilter.java          # CORS headers for API
│   └── pom.xml
│
└── PROJECT_DOCS.md                    # This file
```

---

## 5. Database Tables

All tables are created automatically by `SchemaInitializer.java` on every Tomcat startup (`CREATE TABLE IF NOT EXISTS`).

| Table | Purpose |
|---|---|
| `customers` | Registered users (mobile number + role) |
| `auth_otps` | OTP codes (6-digit, 5 min TTL) |
| `enquiries` | Booking requests with status, dates, rental type |
| `payments` | Razorpay payment records (PENDING → SUCCESS / FAILED) |
| `muhurtham_dates` | Auspicious dates (no hourly rental, 0% cancellation refund) |
| `terms_versions` | Hall T&C documents (English + Tamil) |
| `terms_acceptances` | Records when a customer accepted T&C before paying |
| `refunds` | Refund records created when a CONFIRMED booking is cancelled |
| `notification_log` | Log of WhatsApp/email notifications sent |
| `blocked_dates` | Dates the admin has fully blocked (no bookings) |

---

## 6. Key URLs

| URL | What It Is |
|---|---|
| `http://localhost:8080/` | Main website (home page) |
| `http://localhost:8080/gallery` | Photo & video gallery |
| `http://localhost:8080/amenities` | Amenities page (8 cards) |
| `http://localhost:8080/booking` | Booking enquiry form |
| `http://localhost:8080/login` | OTP login page |
| `http://localhost:8080/admin` | Admin portal |
| `http://localhost:8080/payment/:reference` | Customer payment page |
| `http://localhost:8080/receipt/:reference` | Booking receipt / download |
| `http://localhost:8080/malinimahal/api/...` | All backend REST API endpoints |
| `https://poise-rehydrate-barn.ngrok-free.dev` | Public ngrok URL (while ngrok is running) |
| `http://localhost:4040` | ngrok local dashboard |

---

## 7. Environment Variables (Required at Tomcat Startup)

| Variable | Value | Purpose |
|---|---|---|
| `CATALINA_HOME` | `C:\tools\apache-tomcat-10.1.55` | Tomcat home |
| `ADMIN_PASSWORD` | `Admin@123` | Password to access the admin portal |
| `DB_PASSWORD` | `A3Hf7@g+` | PostgreSQL password (never written to any file) |
| `RAZORPAY_KEY_ID` | `rzp_test_T3YE39oVfOovoV` | Razorpay publishable key (test mode) |
| `RAZORPAY_KEY_SECRET` | *(secret — do not write here)* | Razorpay signing secret (NEVER commit or share) |

---

## 8. How to Start Everything

### Step 1 — Start PostgreSQL
PostgreSQL runs as a Windows service. It usually auto-starts. If not:
```powershell
Start-Service postgresql-x64-17
```

### Step 2 — Start Tomcat (with all env vars)
Open PowerShell and run:
```powershell
$env:CATALINA_HOME       = "C:\tools\apache-tomcat-10.1.55"
$env:ADMIN_PASSWORD      = "Admin@123"
$env:DB_PASSWORD         = "A3Hf7@g+"
$env:RAZORPAY_KEY_ID     = "rzp_test_T3YE39oVfOovoV"
$env:RAZORPAY_KEY_SECRET = "YOUR_SECRET_HERE"
& "C:\tools\apache-tomcat-10.1.55\bin\startup.bat"
```

### Step 3 — (Optional) Start ngrok for public access
```powershell
ngrok http 8080
# Public URL: https://poise-rehydrate-barn.ngrok-free.dev
```

### Step 4 — Stop Tomcat
```powershell
$env:CATALINA_HOME = "C:\tools\apache-tomcat-10.1.55"
& "C:\tools\apache-tomcat-10.1.55\bin\shutdown.bat"
```

---

## 9. How to Build and Deploy

### Build the Frontend
```powershell
$env:PATH = "C:\Program Files\nodejs;" + $env:PATH
cd "C:\Users\sivas\Desktop\4s Malini Mahal\frontend"
npm run build
Copy-Item -Recurse -Force ".\dist\*" "C:\tools\apache-tomcat-10.1.55\webapps\ROOT\"
```

### Build the Backend
```bash
cd "C:/Users/sivas/Desktop/4s Malini Mahal/backend"
/c/tools/apache-maven-3.9.16/bin/mvn -q package -DskipTests
cp "target/malinimahal.war" "C:/tools/apache-tomcat-10.1.55/webapps/malinimahal.war"
```
Tomcat hot-deploys the WAR automatically (~5 seconds). No restart needed for backend changes.

---

## 10. Features Built

### Public (no login required)
- **Home page** — hero section, hall intro, CTA. When logged in, shows **"Your Bookings"** section with all past bookings (status, pay/invoice/WhatsApp links).
- **Gallery** — photo and video grid with lightbox viewer. Arrow key navigation. Videos play inline.
- **Amenities** — 8 cards: AC Hall, Elevator, Parking, Bride & Groom Rooms, 24-Hour Service, Fire Safety, Professional Audio, Unmatched Service. Gold circular icons on cream cards. Bilingual (EN/TA).
- **Booking form** — customer fills all details (name, date, rental type, function, time slot, message). No login wall to browse.

### Authentication
- **WhatsApp OTP** — 6-digit OTP sent via WhatsApp. 5-minute TTL.
- **Session-based** — cookie session maintained by Tomcat.
- **Admin role** — separate role on the `customers` table. Protected by `AuthFilter.java`.
- **Bilingual** — login form available in Tamil and English.

### Booking Flow
1. Customer fills the form → clicks **Book Now**
2. If not logged in → form data saved to `sessionStorage` → redirected to login
3. After OTP verification → returned to booking page → **auto-submits** the saved form data
4. Booking is created with status **AWAITING_PAYMENT** (no admin approval needed)
5. Frontend immediately redirects to **`/payment/:reference`**
6. Customer pays via Razorpay → booking moves to **CONFIRMED**
7. Customer can download invoice and WhatsApp-notify the hall from the payment page
8. Logged-in customers can view all their bookings on the **home page** ("Your Bookings" section)

### Admin Portal (`/admin`)
- **Enquiries table** — all bookings, newest first, with status dropdown
- **Status change** — NEW → UNDER_ENQUIRY → AWAITING_PAYMENT → CONFIRMED → COMPLETED / DECLINED / REJECTED / CANCELLED
- **Conflict detection** — prevents double-booking when confirming (checks time overlap including gaps)
- **Billing entry** — after event: electricity units, gas kg, extra charges
- **Pay Link** — appears on AWAITING_PAYMENT bookings; opens customer payment page
- **Gallery management** — upload photos and videos, YouTube links, drag reorder
- **Blocked dates** — block entire dates from being booked
- **Muhurtham dates** — auspicious dates (no hourly rental; 0% refund if cancelled)
- **Terms & Conditions** — create/version T&C in English and Tamil
- **Refunds** — tracks refund records for cancelled CONFIRMED bookings
- **Notification log** — history of all WhatsApp/email notifications

### Payment Gateway (Razorpay)
- Booking is created with status **AWAITING_PAYMENT** automatically (no admin step)
- Customer is redirected to `/payment/:reference` immediately after form submit
- Admin can also view and share the **Pay Link** from the admin portal
- Customer opens `/payment/:reference`:
  - Sees booking summary and amount
  - Reads and accepts T&C (checkbox)
  - Clicks **Pay Now** → Razorpay popup (UPI / cards / net banking)
- On successful payment:
  - Razorpay signature verified server-side (HMAC-SHA256)
  - Booking auto-promoted to **CONFIRMED**
  - Payment record saved in DB
- Test card: `4111 1111 1111 1111`, any future date, any CVV

### Receipt / Invoice
- `/receipt/:reference` — downloadable PDF receipt after booking submission
- `/invoice/:reference` — full invoice with billing breakdown

### Bilingual Support
- Full Tamil and English throughout: nav, booking form, login, amenities
- Language toggle in the nav bar

---

## 11. Rental Types and Pricing

| Type | Price | Details |
|---|---|---|
| Full Day | ₹35,000 advance (₹32,000 rent + ₹3,000 security) | Entry 3 PM day before, exit 2 PM on event day |
| Half Day | ₹23,000 | Any 6–8 hour window |
| Hourly | ₹3,000/hr | 2–4 hours. Not available on Muhurtham dates |

---

## 12. Booking Status Flow

```
AWAITING_PAYMENT  ← set automatically when customer submits booking
 └─▶ CONFIRMED (payment received via Razorpay)
      └─▶ COMPLETED (event done, billing settled)
 └─▶ DECLINED  (admin declines)
 └─▶ REJECTED  (admin rejects)
 └─▶ CANCELLED (cancelled after confirmation)
```

> Admin can still manually change status to any value via the admin portal.
> The old `NEW → UNDER_ENQUIRY` flow is no longer used for new bookings.

---

## 13. API Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/api/auth/otp/send` | Send OTP to mobile via WhatsApp |
| POST | `/api/auth/otp/verify` | Verify OTP, create session |
| POST | `/api/auth/logout` | Clear session |
| GET | `/api/auth/me` | Get current logged-in user |
| POST | `/api/enquiries` | Submit a booking enquiry (creates with AWAITING_PAYMENT status) |
| GET | `/api/enquiries/my` | Get logged-in customer's own bookings (requires session) |
| GET | `/api/availability?date=...` | Check date availability |
| GET | `/api/gallery` | List gallery items |
| GET | `/api/media/:filename` | Serve uploaded media files |
| GET | `/api/receipts/:reference` | Download PDF receipt |
| GET | `/api/terms/current` | Get active T&C version |
| POST | `/api/payments/create-order` | Create Razorpay order |
| POST | `/api/payments/verify` | Verify payment signature |
| GET | `/api/payments/invoice/:ref` | Get invoice data |
| GET | `/api/admin/enquiries` | List all enquiries (admin) |
| POST | `/api/admin/enquiries/:ref/status` | Change enquiry status (admin) |
| POST | `/api/admin/enquiries/:ref/billing` | Enter billing charges (admin) |
| GET/POST/DELETE | `/api/admin/blocked-dates` | Manage blocked dates |
| GET/POST/DELETE | `/api/admin/muhurtham` | Manage muhurtham dates |
| GET/POST | `/api/admin/gallery` | Gallery CRUD (admin) |
| GET/POST | `/api/admin/terms/*` | Terms management |
| GET | `/api/admin/refunds` | List refunds |
| GET | `/api/admin/notification-log` | Notification history |

---

## 14. Git Checkpoints

| Commit | Description |
|---|---|
| Checkpoint 1 | Full working system with conflict detection |
| Checkpoint 2 | Video file upload in gallery |
| Checkpoint 3 | Gallery lightbox refactor (native DOM, self-correcting position) |
| Checkpoint 4 | Fix lightbox arrow navigation |
| Checkpoint 5 | Amenities page, public gallery/booking, post-login auto-submit, admin status fix |
| Checkpoint 6 | Direct-to-payment booking flow, Your Bookings on home page, remove Track Booking nav |

---

## 15. Known Quirks and Fixes

### Dev Environment
1. **Stale PATH** — Claude Code shells don't see `node`/`mvn`. Must prepend:
   `$env:PATH = "C:\Program Files\nodejs;" + $env:PATH`
   Use full path for Maven: `/c/tools/apache-maven-3.9.16/bin/mvn`

2. **Windows Developer Mode** — Embroider+Vite needs symlinks. Developer Mode must be enabled (enabled 2026-06-17).

3. **Ember config env** — The app sees `environment = 'production'` even in dev. API base URL is resolved at runtime in `frontend/app/utils/api.js` using `window.location.port`, NOT from build-time config.

4. **ngrok free plan** — One fixed static domain: `poise-rehydrate-barn.ngrok-free.dev`. Domain doesn't change between restarts.

### Bugs Fixed
- **Lightbox arrow navigation** (Checkpoint 4) — `_closeLightbox()` nulled `_lightboxIndex` before new lightbox read it. Fixed by capturing index before closing.
- **Post-login redirect to home** (Checkpoint 5) — `login-form.gjs` cleared `auth.returnTo = null` before reading `returnToRoute` getter. Fixed by capturing route first.
- **Admin status change HTTP 500** (Checkpoint 5) — `AdminEnquiryServlet` called `dao.hasConflict()` with 3 args but method signature changed to 4 args (added `rentalType`). Fixed by passing `enquiry.getRentalType()`.

### Checkpoint 6 New Files
- `frontend/app/components/my-bookings.gjs` — "Your Bookings" section component on home page. Shows reference, date, function, status badge, Pay Now / Invoice / WhatsApp links for each booking. Fetches from `/api/enquiries/my`.

---

## 16. Security Rules (Never Break These)

- PostgreSQL password `A3Hf7@g+` → **only** as transient `$env:DB_PASSWORD` env var. Never written to any file.
- Admin password `Admin@123` → **only** as `$env:ADMIN_PASSWORD` env var at Tomcat startup. Never committed.
- `RAZORPAY_KEY_SECRET` → **never** sent to frontend. Only `RAZORPAY_KEY_ID` goes in the create-order response.
- Customer passwords → stored as PBKDF2 hashes. Never plain text.
- ngrok authtoken → treat as sensitive credential.

---

## 17. Testing the Payment Flow

### Quick flow (as customer):
1. Go to `/booking` → fill in form → click **Book Now**
2. If not logged in → OTP login → auto-returns and submits
3. Immediately redirected to `/payment/MM-xxxxx`
4. Accept T&C → click **Pay Now**
5. Razorpay test popup → use test card: `4111 1111 1111 1111` · any future expiry · any CVV
6. Payment succeeds → booking moves to **Confirmed**
7. Download invoice / WhatsApp notify from payment page

### Via admin (legacy pay-link flow):
1. Log in as admin at `/admin`
2. Find any booking → status must be **AWAITING_PAYMENT**
3. Click the yellow **Pay Link** button → opens `/payment/MM-xxxxx` in new tab
4. Follow same steps above

---

*This file is maintained by Claude and updated after every significant change to the project.*
