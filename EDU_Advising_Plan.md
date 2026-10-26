# EDU Advising — Complete Project Plan

> A single, self-contained plan for building the **EDU Advising** mobile app (course project CSE 464, East Delta University).
> It carries everything decided so far in the planning chat: rules, roles, features, screens, database tables, backend logic, data files, tech stack, timeline and testing.
> Build order and a beginner-friendly step list are at the end (Sections 17–18).

---

## 1. Project at a glance

| Item | Value |
|---|---|
| App name | **EDU Advising** |
| Course | CSE 464 — Mobile App Development Project Course (instructor: Promila Haque) |
| University | East Delta University (EDU), Chattogram, Bangladesh |
| Semester | Fall 2026 |
| Type | Student-portal-style **mobile app** where **Advising** is the one main module |
| Frontend | **Flutter** (Dart) |
| Backend | **Firebase**: Auth, Cloud Firestore, Cloud Functions, Cloud Messaging (FCM), Storage |
| Faculty decision | The course faculty chose **EDU Advising** as the project (TutorNest, the second proposal idea, is dropped) |
| Team (max 4) | 233007912 Mohammad Hasibur Rashid · 233008612 Muhammad Anamur Rashid · 233018712 Jannatul Nayeem Sumi · 233019012 Tarin Sultana Ishpa |
| Owner / lead | Anam (Muhammad Anamur Rashid) — builds the whole frontend |

### Deadlines (from the course outline)
| Date | Deliverable |
|---|---|
| 10/10/2026 | Proposal (PPTX + video ≤ 10 min, every member speaks) — already submitted/prepared |
| **01/11/2026** | **Frontend** (all main screens on dummy data, Advising polished) |
| 12/12/2026 | Demo video + PDF report (ER diagram, flow, screenshots, self-evaluation) |
| **13/12/2026** | **Backend, database, CRUD, viva** |

### Problem being solved
Today advising starts with a **Google Form**, then students are **called one by one** by faculty; section choice depends on who is called first, and prerequisite/clearance checks are done by hand. EDU Advising makes it **self-service**: the student sees clearance, picks a semester section with live seat counts, confirms, and the **server** guarantees no two students take the same last seat.

### Scope decisions (the user trimmed the project on purpose)
- **Advising only** is the heart. Everything else (profile, classes, routine, etc.) is small and supports it.
- No slot booking, no preference form, no faculty gatekeeping for regular advising.
- No announcements/post-class features, no advisee list, no breaking waitlist order.
- No separate Staff role. No separate Dean login. No live payment gateway.
- No Bangla-language-centred features (project is not about the Bangla language).

---

## 2. Roles and exact permissions

Four roles. **One login page** for everyone; the account decides which menu appears. The login screen follows the university portal structure: Username, Password, Role selector (Student / Instructor / Administrator).

| Role | Can do | Cannot do |
|---|---|---|
| **Student** | Own profile; clearance check; regular advising (select sections/courses, Select all, Confirm); My Classes; class routine; exam routine; course offer list; prerequisite checker; faculty directory; notices; FAQ chatbot; Extra-course **request** (with reason) and **withdraw while pending**; download current screen as PDF | **Drop regular courses** (never). Add/drop extra courses directly. Choose a second section after locking one |
| **Instructor (Faculty)** | Search any student by ID; see clearance (read-only); **add or drop directly, no request**, for **their own courses** (also extra courses); approve/reject extra-course requests for own courses; change seats of own sections; view own classes | Add/drop other faculty's courses; advise a **Not cleared** student; give clearance |
| **Dean** (Dr. MK) | **No separate login.** Dr. MK logs in as Instructor and the **Dean surface** appears automatically. Everything an Instructor can do, plus: add/drop **any** course for any student (including extra courses), change seats of **every** course, **advise without clearance** (bypass is logged), see all requests, see the audit log | — |
| **Administrator** | **Clearance list**: all students as Cleared / Special consideration / Not cleared with **Give clearance / Revoke** buttons; open/close the **Regular advising** window and the **Extra course** window; manage notices, FAQs, and course/section data; view audit log | Advise students; the payment data itself is checked **outside** the app |

Notes
- A faculty member does advising for a student **only after** checking clearance (search student ID → clearance page → proceed only if Cleared or Special consideration).
- Dean advising bypasses clearance; **every bypass is written to the audit log**.
- Faculty is identified by `users.role = "instructor"`; Dean is `users.isDean = true` (set for Dr. MK only). The Dean surface is shown when `isDean` is true.

---

## 3. Student flow (the main story)

1. **Login** → role routed to the correct home.
2. **Home**: profile card, a big highlighted **Advising** card, account summary, notices.
3. **Menu → Advising** opens **Accounts Clearance check** first (clearance is *inside* Advising; there is no separate Finance section required).
4. **Clearance page**: shows status — **Cleared / Special consideration / Not cleared** — and the remark.
   - Cleared → button **Proceed to Advising**.
   - Special consideration → proceed allowed.
   - Not cleared → advising locked; page shows what to do and links (below).
   - Page also shows "advising not done / done" status so the student knows whether they have already advised.
5. **Window check**: regular advising must be open (Administrator switch).
6. **Regular advising**: pick the student's own semester → list of **sections** (A, B, C … each with live seats like `12/40`) → open a section → its **courses** appear with **checkboxes** and a **Select all** button.
7. Student ticks courses (no auto-skip of already-passed courses; the student decides) → **Confirm / Enroll selected** → one all-or-nothing server transaction.
8. **Section lock**: as soon as the student has any course in one section, **all other sections become view-only**. If they drop everything (done by faculty/Dean), the lock clears.
9. If the section is **full** → **Join waitlist** (ordered by server timestamp); when a seat frees, the first waiting student is auto-enrolled.
10. **My Classes** (Menu → Classes) lists what the student enrolled in.
11. Student can view **Class routine**, **Exam routine**, **Offer list**, **Prerequisite checker**, **Faculty directory**, **Notices**, **FAQ chatbot**, and **download the current screen as PDF**.

### Clearance page links (real university pages)
- Advising Information Portal — `advising.eastdelta.edu.bd`
- E-payment Portal — `epayment.eastdelta.edu.bd`
- Bank Deposit Slip Upload — Google Form (URL to be filled by the team)
Open with `url_launcher`.

### Clearance rules
```
dues == 0                                   -> CLEARED (AUTO)
specialConsideration && paid >= requiredAmt -> CLEARED (PAID)
specialConsideration && paid <  requiredAmt -> NOT_CLEARED
Administrator clicks Give clearance         -> CLEARED (ADMIN_OVERRIDE)
Administrator clicks Revoke                 -> NOT_CLEARED
Dean advising                               -> clearance check skipped, bypass logged
```
Three states shown to users: **Cleared · Special consideration · Not cleared**. The Administrator sees the whole list and can change it; everyone sees the result in the clearance checker. The **payment data is checked outside the app** (no gateway).

---

## 4. Extra course (inside Advising, separate tab)

- Tab **Extra course** sits beside **Regular advising**, opens only after the regular deadline **when the Administrator opens the Extra-course window**.
- Idea: "open credit" — after everyone's advising, if seats are vacant, students may take courses from junior/senior semester sections.
- Students **cannot add/drop extra courses themselves.** They view vacant-seat sections and send a **request** to the course faculty **and the Dean**.
- **A request carries a reason** (required): *Retake, Grade improvement, Required for graduation, Schedule problem, Other* plus an optional comment. (It is a request with a reason, not just an email/comment.)
- **One request per course**: a student can send only one add request (and one drop request) for the same course; the button is replaced by the request **status**.
- **Withdraw**: allowed **only while the request is Pending**; withdrawing frees the course to be requested again. Withdraw exists **only** for extra-course requests.
- **No expiry** on requests (decided: don't auto-expire).
- Faculty **or** Dean can **Approve / Reject** (with optional comment). On approval the system enrolls/drops the student (type `EXTRA`).
- In course selection, show **only the section** next to the course (e.g. `CSE 321.2`), **no faculty short form**, also on the Extra course tab (decided).
- Statuses: `PENDING → APPROVED/REJECTED → ENROLLED`, or `WITHDRAWN`.

### Drop rules (important)
- **A student cannot drop a regular course. Only faculty (own courses) or the Dean (any) can drop it.**
- For extra courses a student can only **request** a drop.

---

## 5. Validation order (enrol transaction)

`clearance → phase/window → section lock (regular phase) → prerequisite → credit limit → time clash → seat (→ faculty approval for extra)`

- **Prerequisite checker** page: pick a course → shows its prerequisites vs the student's transcript. Data is in `misc_data.dart` (`kPrereq`).
- The system does **not** block already-completed courses in regular advising (the student decides); prerequisites/credit/time-clash still validate.
- Routine merging: a course and its lab/section slots are shown together under one section label.

---

## 6. Concurrency (the main technical highlight)

- **Server timestamp** decides order (never phone time).
- Enrol = **one Firestore transaction**: `if enrolled < capacity -> enrolled + 1 and create enrollment, else full`.
- **Idempotency**: enrollment document ID = `{studentId}_{sectionId}`; a retry or double tap cannot enrol twice.
- **Section lock** is enforced **server-side in the same transaction** (`students.lockedSection`). Select all is **one all-or-nothing batch**.
- Per-section counter fields (avoid a single hot document if sections grow).
- Waitlist promotion happens inside the drop transaction (Cloud Function optional; fallback if the Blaze plan is unavailable).
- **Test**: a script fires 50 simultaneous requests at a 40-seat section → **exactly 40 succeed**.

---

## 7. All screens (build list)

Own visual design using the university-logo colours; structure only is borrowed from the Orbund portal (use the real university logo image in the app).

### Layout
Login → **Top bar** (university name, notification bell with badge, logout; thin gold line underneath) → **Home** (profile card, Advising highlight, account summary, notices) → **Bottom tabs: Home, Menu only** → **Menu** (grouped): *Communication, Classes, Reports & Transcripts, Finance, Advising, Reference*. Advising opens from Menu. "My Profile" is reached from the Home profile card (not from the Menu).

### Student screens
1. Login
2. Home
3. Profile (fields: name, ID, phone, email, DOB, present/permanent address, father/mother name, emergency contact, photo)
4. Menu
5. Advising → Clearance check
6. Advising → Regular (semester → sections with seats → courses with checkboxes, Select all, Confirm)
7. Advising → Waitlist status
8. Advising → Extra course (vacant sections, request sheet with reason, request list with status and Withdraw)
9. **My Classes** (what I enrolled in)
10. Class routine (weekly grid, labs included; one-section view)
11. Exam routine (day-wise Day 1–8; all semesters; single-semester **PDF download**, not all semesters)
12. Course **Offer list** (nicely formatted, searchable, sections and seats)
13. Prerequisite checker
14. Faculty directory (search by name or short form)
15. Notice board
16. FAQ chatbot
17. Transcript, Finance summary (basic supporting pages; dummy data)

### Instructor / Dean screens
1. Instructor home (My courses)
2. **Student search** by ID → clearance page → "Start advising for this student" → same section/course picker
3. Add/Drop for own courses (Dean: any course)
4. Requests inbox (Approve/Reject)
5. Seat change (own sections; Dean: all) — not above room capacity, not below current enrolment
6. Dean panel (extra tools, all requests, audit log)

### Administrator screens
1. **Clearance list** (search, filter by Cleared / Special / Not cleared, Give / Revoke)
2. **Windows** (Regular advising ON/OFF, Extra course ON/OFF)
3. Notices manager
4. FAQ manager
5. Courses/Sections manager (CRUD)
6. Audit log viewer

### PDF
Any list screen can be saved as a PDF (`pdf` + `printing` packages in Flutter). Routine/exam PDF is **one semester at a time**.

---

## 8. Visual design

| Token | Hex | Use |
|---|---|---|
| Deep maroon | `#5E1236` | **Login screen only** (and logo areas) |
| Primary maroon | `#861A4C` | Buttons, titles, links, active tab |
| Gold | `#C9A24B` | Thin line under top bar only |
| Tint | `#F6E7EE` | Inputs, chips, Advising card (with maroon edge) |
| Background | `#F7F4F5` | App background behind cards |
| Text | `#2A1A22` | Body text |
| Success | `#2E7D4F` | Cleared / open |
| Danger | `#C0392B` | Not cleared / full / blocked |
| Warning | `#B7791F` | Special consideration / pending / few seats |

Rules: login = dark maroon with a white card; **all other screens white** (the user explicitly disliked a heavy maroon background on page 2). Inputs must keep visible text colour in dark mode.

---

## 9. Real data included (Fall 2026)

Five Dart data files already generated from the working demo:

| File | Variable | Content |
|---|---|---|
| `offer_data.dart` | `kOffer` | Semesters 1–11. Per semester: `n` (number of sections), `c` (courses `[code, title, credit]`), `s` (per course → list per section of `[[sectionNo, capacity], ...]`) |
| `routine_data.dart` | `kRoutine`, `kDays` | **573** class slots incl. labs: `[day, type, time, room, "COURSE.section", facultyShort]`; days Sat–Thu |
| `exam_data.dart` | `kExam` | Per semester: `[[dayNo, courseCode], ...]`, Day 1–8 |
| `faculty_data.dart` | `kFaculty` | **55** faculty `[fullName, shortForm]`. Email/phone/position/department = "Not provided" for now |
| `misc_data.dart` | `kPrereq`, `kNotices`, `kFaq` | Prerequisites map, sample notices, FAQ keyword answers |

Source PDFs (in the old account/chat): CSE Course Offer List – Section Structures – Fall 2026; CSE Semester 10 Fall 2026 Routine; CSE–EEE All Semesters Fall 2026 Routine; CSE 242.6 Final Project Report (old web project); Mobile App Development Project Course outline.
Seat usage in the demo is **simulated**. Demo clearance IDs: `233000001`–`233000012` (dummy).
Use **dummy** students; do **not** put real student IDs/names from portal screenshots in the app.

The working interactive HTML demo (reference for behaviour) was published as a Claude artifact; keep the data files as the source of truth when rebuilding in Flutter.

---

## 10. Database design (Cloud Firestore)

Use these **collections** (they are the "tables"). `id` is the document ID. Server timestamps (`FieldValue.serverTimestamp()`) for all `createdAt/updatedAt`.

### 10.1 `users`
| Field | Type | Notes |
|---|---|---|
| id (uid) | string | Firebase Auth uid |
| role | string | `student` / `instructor` / `admin` |
| isDean | bool | true only for Dr. MK |
| name | string | |
| email | string | |
| phone, phoneVisible | string, bool | |
| shortName | string | faculty short form (e.g. `Dr. MK`) |
| dept, position | string | |
| photoUrl | string | Storage URL |

### 10.2 `students`
| Field | Type | Notes |
|---|---|---|
| id (studentId) | string | e.g. `233008612` |
| uid | string | link to `users` |
| name, batch, dept | string | |
| semesterNo | int | 1–11 |
| cgpa, creditsDone | number | |
| lockedSection | string? | set on first enrol, null when empty |
| clearanceStatus | string | `CLEARED` / `SPECIAL` / `NOT_CLEARED` |
| clearanceType | string | `AUTO` / `PAID` / `ADMIN_OVERRIDE` |
| specialConsideration | bool | |
| requiredAmount | number | |
| advisingDone | bool | shown on clearance page |
| phone, email, dob, presentAddress, permanentAddress, fatherName, motherName, emergencyContact, photoUrl | | profile fields |

### 10.3 `courses`
`code` (id), `title`, `credits`, `dept`

### 10.4 `prerequisites`
`courseCode`, `requiredCourseCode`, `minGrade` (seed from `kPrereq`)

### 10.5 `sections` (seed from `kOffer`)
`id` (`CSE421_A`), `courseCode`, `sectionNo`, `semesterNo`, `sectionGroup` (A/B/C — the group a student locks to), `facultyId`, `capacity`, `enrolled`, `room`, `days`, `startTime`, `endTime`, `semester` (`Fall 2026`)

### 10.6 `enrollments`
ID = `{studentId}_{sectionId}`. Fields: `studentId`, `sectionId`, `courseCode`, `type` (`REGULAR` / `EXTRA`), `status` (`ENROLLED` / `DROPPED`), `createdAt` (server), `byUid` (who did it), `droppedBy`, `droppedAt`

### 10.7 `waitlist`
`studentId`, `sectionId`, `createdAt` (server; defines order), `position`

### 10.8 `transcripts`
`studentId`, `courseCode`, `semester`, `grade`, `gradePoint` (used by the prerequisite checker)

### 10.9 `payments` (recorded by Accounts, no gateway)
`studentId`, `amount`, `type`, `txnId`, `verifiedBy`, `date`

### 10.10 `clearanceStatus` / `clearanceRequests`
`clearanceRequests`: `studentId`, `comment`, `status`, `decidedBy`, `createdAt`

### 10.11 `extraRequests`
| Field | Notes |
|---|---|
| id | auto |
| studentId, sectionId, courseCode | |
| kind | `ADD` / `DROP` |
| reason | `Retake`, `Grade improvement`, `Required for graduation`, `Schedule problem`, `Other` |
| comment | optional |
| status | `PENDING`, `APPROVED`, `REJECTED`, `ENROLLED`, `WITHDRAWN` |
| decidedBy, facultyComment | |
| createdAt | server |
Constraint: **one ADD and one DROP request per student per course** (use doc ID `{studentId}_{courseCode}_{kind}`; withdrawing deletes/flags it so it can be requested again).

### 10.12 `advisingWindows` / `settings`
`settings/windows`: `regularOpen` (bool), `extraOpen` (bool), `semester`, `opensAt`, `closesAt`

### 10.13 `classRoutines` / `routineSlots` (seed from `kRoutine`)
`day`, `type` (T/L), `time`, `room`, `course`, `section`, `facultyShort`, `semesterNo`

### 10.14 `examRoutines` (seed from `kExam`)
`semesterNo`, `examType`, `dayNo`, `courseCode`, `room`

### 10.15 `notices`
`title`, `body`, `category`, `pinned`, `attachmentUrl`, `createdBy`, `createdAt`, plus per-user read tracking for the unread badge

### 10.16 `faqs`
`question`, `answer`, `category`, `keywords[]`

### 10.17 `auditLogs`
`actorId`, `actorRole`, `action`, `targetId`, `before`, `after`, `reason`, `bypassedClearance` (bool), `timestamp` (server)
Logged actions: ENROLL, DROP, ADD_BY_FACULTY, DROP_BY_FACULTY, DEAN_BYPASS, CLEARANCE_GIVEN, CLEARANCE_REVOKED, WINDOW_OPEN/CLOSE, SEAT_CHANGE, REQUEST_APPROVED/REJECTED.

### Relationships (ER summary)
- `students` 1—N `enrollments` N—1 `sections` N—1 `courses`
- `sections.facultyId` → `users` (instructor)
- `students` 1—N `extraRequests` N—1 `sections`
- `students` 1—N `waitlist` N—1 `sections`
- `students` 1—N `transcripts`; `courses` 1—N `prerequisites`
- `auditLogs.actorId` → `users`
- `settings` is a global single document

### Indexes you will need
- `enrollments`: `studentId` + `status`; `sectionId` + `status`
- `waitlist`: `sectionId` + `createdAt` (ascending)
- `extraRequests`: `sectionId` + `status`; `studentId` + `status`
- `sections`: `semesterNo` + `courseCode`
- `auditLogs`: `timestamp` descending

---

## 11. Backend logic (Cloud Functions, Node.js)

Callable functions (all check `request.auth` and the caller's role server-side):

| Function | Who | What it does |
|---|---|---|
| `enrollSelected({sectionId, courseCodes[]})` | student | Transaction: check window → clearance → section lock → prereq → credit limit → time clash → capacity; create enrollments with ID `{studentId}_{sectionId}`; `enrolled+1`; set `lockedSection`; write audit. All-or-nothing |
| `facultyAdvise({studentId, ...})` | instructor/dean | Same as above for another student; faculty can only touch own courses, Dean any; Dean skips clearance and logs bypass |
| `facultyDrop({studentId, sectionId})` | instructor/dean | Drop; `enrolled-1`; clear `lockedSection` if empty; promote waitlist; audit |
| `joinWaitlist`, `leaveWaitlist` | student | Add/remove with server timestamp |
| `createExtraRequest({sectionId, kind, reason, comment})` | student | Enforce one-per-course and window open |
| `withdrawExtraRequest(requestId)` | student | Only if `PENDING` |
| `decideExtraRequest({requestId, approve, comment})` | instructor/dean | Approve → enrol/drop with type `EXTRA`; Reject → status; audit |
| `setClearance({studentId, status})` | admin | Give/Revoke; audit |
| `setWindow({regularOpen, extraOpen})` | admin | Toggle windows; audit |
| `changeSeats({sectionId, capacity})` | instructor (own) / dean (all) | Not above room capacity, not below current enrolment |
| `faqAnswer({question})` | any | Step 1 keyword match; Step 2 optional LLM restricted to FAQ text through the function (no key in the app) |

Triggers: on notice create → FCM push; on request decided → FCM push to student; on waitlist promotion → FCM push.
Fallback if the Blaze plan is not available: implement client-side Firestore transactions + Security Rules, and do waitlist promotion inside the drop transaction.

### Sample enrol transaction (pseudocode)
```
runTransaction:
  window = get settings/windows; require regularOpen
  student = get students/{id}; require clearance ok (or caller isDean)
  require student.lockedSection in [null, sectionGroupOfRequest]
  for each course:
     section = get sections/{courseSection}
     require prerequisites met, no time clash, credit <= limit
     require section.enrolled < section.capacity   // else join waitlist
     require enrollments/{studentId_sectionId} not exists   // idempotent
  create enrollments; section.enrolled += 1; student.lockedSection = group
  write auditLogs
```

---

## 12. Security Rules (outline)

- Read/write only when `request.auth != null`.
- `students/{id}`: a student reads **only their own** document; instructor/dean/admin read any; **clients never write** `enrolled`, `lockedSection`, `clearanceStatus` — only Cloud Functions (Admin SDK) do.
- `sections`: everyone signed in can **read**; no client writes (seats change only through functions).
- `enrollments`: student reads their own; faculty reads for their sections; no client writes.
- `extraRequests`: student creates/reads own; instructor reads for own courses; dean reads all; status changes only via functions.
- `settings`: read for all; write only admin (via function).
- `auditLogs`: read admin/dean; write only functions.
- `notices`, `faqs`: read all; write admin.

---

## 13. Tech stack and packages

| Layer | Choice |
|---|---|
| Frontend | Flutter (Dart), Material 3 |
| State management | Provider (simple for beginners) or Riverpod |
| Backend | Firebase Cloud Functions (Node.js) |
| Database | Cloud Firestore |
| Auth | Firebase Auth (email/password) + role stored in `users` |
| Storage | Firebase Storage (profile photo) |
| Notifications | Firebase Cloud Messaging |
| UI design | Figma (optional) |
| Packages | `firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `firebase_messaging`, `firebase_storage`, `provider`, `pdf`, `printing`, `url_launcher`, `intl`, `google_fonts` (optional) |

Payments: **recorded by Accounts only** (no gateway); bKash/Nagad sandbox = future scope.

---

## 14. Suggested Flutter folder structure

```
lib/
  main.dart
  app_theme.dart              // colours from Section 8
  data/                       // the 5 generated data files (Section 9)
    offer_data.dart  routine_data.dart  exam_data.dart
    faculty_data.dart  misc_data.dart
  models/                     // Student, Section, Course, Enrollment, ExtraRequest ...
  services/                   // mock_service.dart now; firebase_service.dart later
  providers/                  // AuthProvider, AdvisingProvider, ...
  screens/
    login/        home/       menu/       profile/
    advising/     (clearance, regular, waitlist, extra_course)
    classes/      (my_classes, routine, exam_routine, offer_list)
    reference/    (prereq_checker, faculty_directory, notices, faq_chatbot)
    staff/        (student_search, add_drop, requests, seats, dean_panel)
    admin/        (clearance_list, windows, notices, faqs, courses, audit_log)
  widgets/                    // SectionCard, SeatBadge, StatusChip, TimetableGrid ...
  utils/                      // pdf_export.dart, validators.dart
```
**Tip:** in the frontend phase put all logic behind `services/mock_service.dart` using the data files and in-memory state. In the backend phase replace it with `firebase_service.dart`; screens do not change.

---

## 15. Role-based navigation (who sees what)

```
Login → read users/{uid}.role
  student    → Student shell (Home, Menu)
  instructor → Instructor shell (My courses, Student search, Requests)
               + Dean panel if isDean == true
  admin      → Admin shell (Clearance list, Windows, Notices, FAQs, Courses, Audit log)
```

Permission matrix

| Task | Student | Faculty | Dean | Admin |
|---|---|---|---|---|
| Do advising | own, if cleared | for others, own courses only | any course, no clearance needed | no |
| Drop a course | **no** | own courses | any | no |
| Extra course | request / withdraw while pending | approve/reject (own) | approve/reject | no |
| Clearance | view | view student's | bypass | give / revoke |
| Windows ON/OFF | no | no | no | yes |
| Change seats | no | own sections | all | no |

---

## 16. FAQ chatbot (bonus)
- FAQ-only: rules, deadlines, fees, clearance, waitlist.
- Admin manages `faqs` (question, answer, category).
- Step 1: keyword/fuzzy match (free, offline). Step 2 (if time): LLM restricted to the FAQ text through a Cloud Function.
- No answer found → "Please contact the Accounts/Academic office". Personal data is never exposed to the bot.

---

## 17. Build order and timeline

### Phase A — Frontend (due **01 Nov 2026**), dummy data only
1. Install Flutter, Android Studio, VS Code; `flutter doctor`.
2. Create the project; add theme (Section 8); copy the 5 data files into `lib/data/`.
3. Login screen (dark maroon + white card), role picker → go to the role's home.
4. Home + Menu + bottom tabs (Home, Menu).
5. **Advising (polish this most)**: clearance page → semester/sections with seats → courses with checkboxes + Select all → Confirm → section lock behaviour (in memory) → full section → Join waitlist.
6. My Classes, Class routine grid, Exam routine, Offer list, Prerequisite checker, Faculty directory, Notices.
7. Extra course tab (request sheet with reason, request list, Withdraw while pending).
8. Student profile, Transcript, Finance (simple, dummy).
9. Instructor screens (student search, add/drop, requests, seats) and Dean extras.
10. Admin screens (clearance list, windows, notices, FAQs).
11. PDF download of the current screen.
12. Test every screen on an emulator/phone; screenshots for the report.

### Phase B — Backend (due **13 Dec 2026**; report + video **12 Dec**)
Order: Auth & roles → seed Firestore with the data files → Student/Clearance → **Advising core + concurrency test** → Waitlist → Faculty/Dean tools → Extra-course requests → Windows/Admin → Notices/FCM → FAQ chatbot → Security Rules → audit log.

### Phase C — Report, video, viva (by 12–13 Dec)
Report PDF: problem, roles, ER diagram, flow, screenshots, tech stack, concurrency testing, self-evaluation. Demo video (≤10 min, every member speaks). Prepare viva answers for: why transaction, how seats are protected, how roles are enforced, clearance logic.

---

## 18. Beginner learning path (for building this yourself)

1. Dart basics: variables, `List`, `Map`, classes, functions (1 day).
2. Flutter widgets: `Scaffold`, `Column`, `Row`, `ListView`, `Card`, `TextField`, `ElevatedButton` (1–2 days).
3. Navigation (`Navigator.push` / named routes) and bottom navigation bar.
4. State: `StatefulWidget` first, then `Provider`.
5. Read local Dart data (`kOffer`, `kRoutine`, ...) and show it in a `ListView`.
6. Build screens in this order: Login → Home → Advising (the heart) → everything else.
7. Later: Firebase setup (`flutterfire configure`), Auth, Firestore reads, then Cloud Functions.

---

## 19. Testing checklist

- Select all selects every course in the section; Confirm enrols all or none.
- After enrolling in one section, other sections are view-only; a full drop clears the lock.
- A student has **no** Drop button on regular courses.
- Extra request: one per course; button replaced by status; Withdraw only while Pending; reason required.
- Faculty can add/drop only for own courses; Dean can for any; Dean works without clearance and the bypass is logged.
- Not-cleared student cannot advise; Administrator Give/Revoke changes it everywhere.
- Closed window blocks regular/extra actions.
- Routine, exam routine and offer list match the PDFs (11 semesters; exam Day 1–8 includes semesters 4+).
- PDF downloads one semester's routine, not all.
- **Concurrency**: 50 parallel enrol requests on a 40-seat section → exactly 40 succeed; duplicate tap never double-enrols.
- Dark-mode inputs stay readable.

---

## 20. Known issues from the earlier demo (don't repeat)
- A helper named `all()` clashed with `document.all` so **Select all** did nothing → use a distinct name (`selectAll`).
- Exam routine for semesters 4+ was initially missing → verify all 11 semesters.
- Lab slots were missing from the routine at first (column parsing) → 573 slots with labs now.
- Input text invisible in dark mode → force explicit text colour.
- Faculty short form was shown beside the section in course selection → removed (show only section).

---

## 21. Open items / notes
1. Special consideration: pre-marked by the admin, or student applies? (default: admin marks/changes it in the clearance list).
2. Whether faculty can override a prerequisite with a reason (default: no).
3. Real faculty emails/phones/positions → add to `kFaculty` / `users` when available.
4. Final URL of the Bank Deposit Slip Upload form.
5. The proposal deadline (10/10/2026) has passed; the faculty already chose EDU Advising.
6. Group name is unknown; add it to the report/video.

---

## 22. Original proposal deck summary (for reference)
18-slide PPTX (maroon theme) covering EDU Advising + TutorNest; speaking order: 1 Anamur (slides 1–5), 2 Hasibur (6–8), 3 Tarin (9–12), 4 Sumi (13–18). TutorNest (tutor marketplace from the CSE 242.6 web project: roles Visitor/Student/Tutor/Admin; entities User, Category, TutorProfile, Booking, Review; Gemini assistant) is **not** being built because EDU Advising was selected.
