# School SaaS Platform

A multi-app school management ecosystem built with Flutter and Firebase. The platform connects schools, teachers, students, and parents through six purpose-built applications, with an automated SMS gateway for attendance notifications.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    HQ Master Control (Desktop)                   │
│          Manages all schools, billing, broadcasts           │
└──────────────────────────┬──────────────────────────────────┘
                           │ Firebase (Firestore + Realtime DB)
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼──────┐  ┌──────▼──────┐  ┌─────▼──────────┐
   │  School App │  │  SMS Sender │  │  Teacher App   │
   │  (Desktop)  │  │  (Android)  │  │  (Mobile)      │
   └─────────────┘  └─────────────┘  └────────────────┘
          │                                │
   ┌──────▼──────┐                  ┌──────▼──────┐
   │ Student App │                  │  Parent App │
   │  (Mobile)   │                  │  (Mobile)   │
   └─────────────┘                  └─────────────┘
```

---

## Applications

| App | Platform | Description |
|---|---|---|
| `HQ_Lib` | Flutter Web / Desktop | Master control panel — manages all schools, billing, broadcasts, and SMS templates |
| `School_Lib` | Flutter Desktop | Per-school admin panel — attendance, classes, students, teachers, fees, documents |
| `lib_Teacher_App` | Flutter Mobile | Teacher portal — attendance marking, homework, tests, chat, timetable |
| `Student_Lib` | Flutter Mobile | Student portal — homework, tests, notices, leave requests, chat |
| `Parent_Lib` | Flutter Mobile | Parent portal — multi-child monitoring, homework, tests, teacher chat |
| `SMS_Lib` | Flutter Android | Background SMS gateway — sends automated attendance alerts via local SIM |

---

## Feature Matrix

| Feature | HQ | School | Teacher | Student | Parent | SMS |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Attendance tracking | — | ✓ | ✓ | — | — | ✓ |
| PDF attendance reports | — | ✓ | — | — | — | — |
| Classes & sections | — | ✓ | ✓ | — | — | — |
| Student management | — | ✓ | — | — | — | — |
| Teacher management | — | ✓ | — | — | — | — |
| Homework | — | — | ✓ | ✓ | ✓ | — |
| Tests & results | — | — | ✓ | ✓ | ✓ | — |
| Timetable | — | ✓ | ✓ | — | — | — |
| Notice board | — | ✓ | ✓ | ✓ | ✓ | — |
| Leave requests | — | ✓ | — | ✓ | ✓ | — |
| Fee management | — | ✓ | — | — | — | — |
| Document storage | — | ✓ | — | — | — | — |
| In-app chat | — | — | ✓ | ✓ | ✓ | — |
| Cross-class chat requests | — | — | — | ✓ | — | — |
| School billing / subscriptions | ✓ | — | — | — | — | — |
| Broadcast messages | ✓ | — | — | — | — | — |
| SMS template management | ✓ | — | — | — | — | ✓ |
| Multi-school management | ✓ | — | — | — | — | — |
| Feature flags per school | ✓ | ✓ | — | — | — | — |
| App lock / PIN | — | ✓ | — | — | — | — |
| Auto-updater | — | ✓ | — | — | — | — |
| Dark / light theme | — | ✓ | ✓ | ✓ | ✓ | — |
| Privacy consent flow | — | — | ✓ | ✓ | ✓ | — |
| Multi-child switching | — | — | — | — | ✓ | — |

---

## Detailed App Descriptions

### HQ Master Control (`HQ_Lib`)

The top-level admin panel. Runs as a Flutter Web or Desktop app with a dark-themed sidebar UI.

- **School Dashboard** — searchable list of all registered schools, status indicators, add/edit/deactivate
- **Billing** — manage each school's subscription, wallet balance, and payment history
- **Broadcast** — send a notification or notice board message to any school's users
- **SMS Templates** — create and manage the message templates used by the SMS Sender app
- **Global Settings** — platform-wide configuration

---

### School Admin App (`School_Lib`)

A Flutter Desktop application installed at each school. Supports admin (full access) and section logins (scoped to a single section).

**Core modules (all toggle-able via feature flags set by HQ):**

- **Attendance** — mark daily attendance (present / absent / late) per class, view session history, export PDF reports with colour-coded status columns
- **Classes & Sections** — create and manage classes within sections
- **Students** — add students with roll numbers, parent phone, and auto-generated login credentials for the Student and Parent apps
- **Teachers** — add teachers with assigned classes and generated credentials for the Teacher app
- **Timetable** — build and publish per-teacher weekly timetables
- **Notice Board** — post school-wide announcements
- **Tests** — create tests and record marks per student
- **Leaves** — review and approve student and teacher leave requests
- **Fee Management** *(optional feature)* — track fee collection per student
- **Documents** *(optional feature)* — store and share class-level documents
- **Settings** — app lock (PIN protection), theme, HQ messages, notification preferences

Other features: auto-updater that checks for new versions from HQ, local desktop notifications, session validation against Firestore on every launch.

**Firestore structure:**
```
schools/{schoolId}/
  sections/{sectionId}/
    classes/{classId}/
      students/
      teachers/
    teachers/
    attendance_sessions/
    timetables/
    homework/
    tests/
    notices/
    leaves/
    fee_records/
    documents/
```

---

### Teacher App (`lib_Teacher_App`)

Flutter mobile app for teachers. Login uses the credentials generated by the School app.

- **Class Selection** — teacher sees only the classes they are assigned to
- **Attendance** — mark attendance for each student in a class; offline queue syncs when back online
- **Homework** — post homework assignments to a class
- **Tests** — create tests and enter marks per student
- **Notice Board** — view school notices
- **Timetable** — view personal timetable; badge shown when updated by admin
- **Chat** — direct messaging with students and parents; cross-class chat requests
- **Account** — profile management, theme toggle, logout

---

### Student App (`Student_Lib`)

Flutter mobile app for students. Uses credentials auto-generated when the school admin adds the student.

- **Homework** — view assigned homework with due dates and details
- **Tests** — view upcoming tests and past results
- **Notices** — school announcements
- **Leave Requests** — submit and track leave requests
- **Chat** — message teachers directly; request cross-class chats with students in other classes
- **Privacy consent** — GDPR-style consent screen on first launch, with full privacy policy

---

### Parent App (`Parent_Lib`)

Flutter mobile app for parents. Supports monitoring **multiple children** with a drawer-based switcher.

- **Multi-child** — add multiple children (each with separate credentials); switch between them from the sidebar drawer
- **Homework** — view child's current homework
- **Tests** — view child's test schedule and results
- **Notices** — school announcements
- **Leave Requests** — submit leave requests on behalf of the child
- **Teacher Chat** — list of the child's teachers with direct messaging
- **App tour** — onboarding walkthrough on first launch
- **Privacy consent** — shown after the tour, before the home screen

---

### SMS Sender App (`SMS_Lib`)

A headless Android app that runs a persistent **background service** to send attendance SMS alerts via the device's physical SIM card. No third-party SMS API required.

- **Login** — authenticates with the school's credentials to bind the device to a school
- **SIM selection** — choose which SIM slot to use on dual-SIM devices; shown once after login
- **Background service** — polls Firebase for pending SMS requests and dispatches them using the device SIM, even when the app is killed
- **Rate limiter** — enforces hard limits (90 / 15 min, 200 / hr, 500 / 24 hr) with a 10-second inter-message delay to avoid carrier blocking
- **Real-time listener** — Firestore `onSnapshot` triggers a send cycle immediately when a new pending request arrives (no waiting for the next timer tick)
- **Template engine** — message text is composed from the templates configured in the HQ app
- **Dashboard** — shows queue status, sent / failed counts, current SIM label, and service toggle

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) — all six apps |
| Database | Firebase Firestore (School, Teacher, Student, Parent, SMS) |
| Realtime DB | Firebase Realtime Database (Teacher, Student, Parent) |
| Authentication | Firebase Auth (HQ, Student, Parent) + custom credential login (School, Teacher) |
| Storage | Firebase Storage (profile images, documents) |
| Background tasks | `flutter_background_service` (SMS app) |
| Local notifications | `flutter_local_notifications` (SMS), `local_notifier` (School desktop) |
| PDF generation | `pdf` package (School attendance reports) |
| Auto-update | Custom `AutoUpdaterService` (School desktop) |
| Local persistence | `shared_preferences` (all apps) |
| SMS dispatch | `telephony` / native channel (SMS app) |

---

## Project Structure

Each app is a standalone Flutter project with a common `lib/` layout:

```
lib/
├── main.dart                  # Entry point, Firebase init, session restore
├── app_theme.dart             # Light/dark theme definitions
├── backend_config.dart        # Backend URL config (image proxy etc.)
├── firebase_credentials.dart  # Firebase project keys (Student, Parent)
├── models/
│   └── models.dart            # Shared data models
├── screens/                   # UI screens
└── services/                  # Firebase and business logic services
```

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.x
- A Firebase project with **Firestore**, **Realtime Database**, **Auth**, and **Storage** enabled
- `google-services.json` placed in `android/app/` for each mobile app
- `GoogleService-Info.plist` in `ios/Runner/` for each iOS target

### Firebase credentials

**Student and Parent apps** use `lib/firebase_credentials.dart` — fill in:
```dart
const kApiKey            = 'your-api-key';
const kAppIdAndroid      = 'your-android-app-id';
const kAppIdIos          = 'your-ios-app-id';
const kMessagingSenderId = 'your-sender-id';
const kProjectId         = 'your-project-id';
const kStorageBucket     = 'your-bucket';
const kIosBundleId       = 'your.bundle.id';
```

**School and HQ apps** use inline `FirebaseOptions` in `main.dart` — replace the placeholder values.

**SMS app** uses `lib/firebase_options.dart` generated by `flutterfire configure`.

### Run

```bash
# Any individual app — navigate to its root directory first
cd School_App   # or Teacher_App, Student_App, Parent_App, SMS_App, HQ_App
flutter pub get
flutter run
```

The School app targets **Desktop** (Windows / macOS / Linux). All others target **Android / iOS**. The SMS app is Android-only (requires physical SIM access).

---

## Feature Flags

HQ controls which modules are available in each school's School app. Flags are stored in Firestore under `schools/{schoolId}/features` and cached locally in `SharedPreferences`.

| Key | Default | Description |
|---|:---:|---|
| `FEATURE_ATTENDANCE` | ✓ | Daily attendance marking and reports |
| `FEATURE_CLASSES` | ✓ | Class management |
| `FEATURE_STUDENTS` | ✓ | Student roster |
| `FEATURE_TEACHERS` | ✓ | Teacher roster |
| `FEATURE_TIMETABLE` | ✓ | Weekly timetable builder |
| `FEATURE_NOTICES` | ✓ | Notice board |
| `FEATURE_TESTS` | ✓ | Test scheduling and marks |
| `FEATURE_LEAVES` | ✓ | Leave management |
| `FEATURE_FEE_MANAGEMENT` | ✗ | Fee collection tracking |
| `FEATURE_DOCUMENTS` | ✗ | Class document storage |

Disabling a feature from HQ **permanently deletes** its Firestore data for that school.

---

## SMS Rate Limits

The SMS Sender app enforces the following limits to prevent carrier blocking:

| Window | Limit |
|---|---|
| 15 minutes | 90 messages |
| 1 hour | 200 messages |
| 24 hours | 500 messages |

A mandatory 10-second delay is applied between each message regardless of rate-limit status.

---

## Contributing

1. Fork the repository and create a feature branch.
2. Keep app-specific changes inside the relevant app's directory.
3. Shared data models that affect multiple apps should be updated consistently across all affected `models.dart` files.
4. Open a pull request describing the change and which apps are affected.

---

## License

This project is proprietary. All rights reserved.
