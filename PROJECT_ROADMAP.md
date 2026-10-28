# EDU Advising: Status and Roadmap

Status as of **28 Oct 2026**. For the team (Anamur, Hasibur, Sumi, Tarin) and
for any AI assistant working on this repository.

**Sources of truth, in this order:**
1. `EDU_Advising_Plan.md`: the agreed requirements (cited below as "Plan §N").
   The team changed two rules after the plan was written, see §2.4 ("Changes to the plan").
2. This file: what is built, what is left, how to run it, and the open decisions.
3. The code itself.

Status labels:
- **DONE**: built and checked.
- **PARTIAL**: built, with a stated gap.
- **TODO**: not started.
- **DECISION**: the team must decide; do not guess.

---

## 0. Snapshot

| Phase | What | Due (Plan §1) | Status |
|---|---|---|---|
| 0 | Tooling and project setup | n/a | DONE |
| 1 | Real university data in the app | n/a | DONE (4 lab sections have no time, see Phase 1) |
| 2 | Frontend, all screens on dummy data (Plan §17 Phase A) | **01 Nov 2026** | DONE |
| 3 | Frontend wrap-up before submission | **01 Nov 2026** | IN PROGRESS: code done; phone test, data spot-check and screenshots remain (§3) |
| 4 | Backend: Firebase, database, CRUD (Plan §17 Phase B) | **13 Dec 2026** | TODO (nothing started) |
| 5 | Report, demo video, viva (Plan §17 Phase C) | **12-13 Dec 2026** | TODO |

Facts from the plan (Plan §1, §13):
- Flutter frontend; Firebase backend (Auth, Firestore, Cloud Functions, FCM, Storage).
- Advising is the only main module.
- No live payment gateway. No separate Dean login: Dr. MK signs in as an instructor.

### Where we stand (28 Oct 2026)

- Every screen of the plan exists and runs on dummy data (`MockApiService`).
- `flutter analyze`: no issues. `flutter test`: **71 tests pass**.
- A release APK is built: `dist/EDU-Advising.apk` (universal, Android 7.0+, ARM 32/64-bit and x86_64), rebuilt on 28 Oct from the merged code. **It has not been installed on a real phone yet.**
- The project is on GitHub: `https://github.com/HasibOp/edu_advising` (branch `main`). All work up to 28 Oct is pushed.

### Pending work, in order

| # | Work | Who | Why it matters |
|---|---|---|---|
| 1 | Install `dist/EDU-Advising.apk` on at least two real Android phones and run the phone test script (§3.1) | TBD | Nothing was tested on a real device. This is the biggest open risk before 01 Nov |
| 2 | Pull the latest `main` on every laptop before working (`git pull`) | Everyone | Two laptops changed the code on 26-28 Oct; work from one copy |
| 3 | Spot-check routine, exam routine and offer list against the source PDFs, semesters 4, 10 and 11 (§3.2) | TBD | Plan §19 requires it |
| 4 | Fill the 4 lab sections that have no time (§Phase 1) | TBD | They show "TBA" |
| 5 | Take a screenshot of every screen for the report (§3.3) | TBD | Plan §17 step 12 |
| 6 | Answer the open decisions (§ Open decisions) | Team | Special consideration for students, faculty contact data, task owners |
| 7 | Backend (Phase 4) | TBD | Due 13 Dec |
| 8 | Report, video, viva (Phase 5) | All four | Due 12-13 Dec |

---

## 1. Run, test and build

### This laptop (where the work of 26-27 Oct was done)

| Item | Location |
|---|---|
| Project | `H:\Project\edu_advising` |
| Flutter 3.47.8 | `C:\flutter` |
| Android SDK | `D:\Android\Sdk` (Android Studio moved it here from `C:\Users\User\AppData\Local\Android\sdk` on 27 Oct) |
| JDK | `D:\Android Studio\jbr` (use this one; the copy in `C:\Program Files\Android\Android Studio` is broken) |
| Android Studio | `D:\Android Studio` |

`android/local.properties` is machine-specific and not in git. On this laptop it must say `sdk.dir=D:\\Android\\Sdk`. If Android Studio moves the SDK again, fix that line.

The other laptop (where Phase 0 was done) had the SDK at `C:\AndroidSdk` and the project on `E:`; the notes in Phase 0 come from there.

### Everyday commands

```
cd H:\Project\edu_advising
flutter pub get
flutter analyze            # must say: No issues found
flutter test               # must say: All tests passed (71 tests)
flutter run -d chrome      # quickest way to look at the app
flutter run -d <phone>     # USB phone with USB debugging on
```

To serve the web build without a debugger: `flutter build web --release`, then serve `build/web`.

### Build the Android APK

PowerShell (the JDK and SDK paths are the ones above):

```
cd H:\Project\edu_advising
$env:JAVA_HOME = "D:\Android Studio\jbr"
$env:ANDROID_HOME = "D:\Android\Sdk"
$env:Path = "$env:JAVA_HOME\bin;C:\flutter\bin;$env:Path"
flutter build apk --release
```

- Output: `build/app/outputs/flutter-apk/app-release.apk`. This **one** file contains ARM 32-bit, ARM 64-bit and x86_64 code, so it installs on any Android 7.0+ phone. Copy it to `dist/EDU-Advising.apk` (the folder is ignored by git).
- Smaller per-phone files: `flutter build apk --release --split-per-abi` (use `app-arm64-v8a-release.apk` for nearly every modern phone).
- The first build took about 8 minutes. Gradle installed SDK Platform 34 and CMake into `D:\Android\Sdk` by itself; that is normal.
- The APK is signed with the debug key. That is fine for sharing and demos, not for Google Play.

### Install on a phone

1. Copy `dist/EDU-Advising.apk` to the phone (USB cable, Google Drive, WhatsApp).
2. Open it on the phone. Allow "install from unknown sources" if asked.
3. Open **EDU Advising**.

Or with a cable: `adb install -r dist\EDU-Advising.apk` (`adb` is in `D:\Android\Sdk\platform-tools`).

### Demo accounts (any non-empty password works)

| Role | Username | What it shows |
|---|---|---|
| Student | `233000001` | Semester 10, cleared, not advised yet. The main demo student |
| Student | `233000002` | Already enrolled in Section 2 (locked) |
| Student | `233000003` | Special consideration (paid enough) |
| Student | `233000004` | **Not cleared** (advising locked) |
| Student | `233000005` | Failed CSE 327: prerequisite blocks CSE 443 and CSE 463 |
| Student | `233000006` | Semester 11, cleared |
| Student | `233000007` | Semester 7, special consideration, has a pending extra request |
| Student | `233000008` | Semester 4, cleared, has a rejected request |
| Student | `233000009` | Special consideration, **not enough paid** (not cleared) |
| Student | `233000010` | Semester 2, cleared |
| Student | `233000011` | Semester 9, pending extra request |
| Student | `233000012` | On the waitlist for CSE 443.1 |
| Instructor | `TRINA` | Ms. Trina Chakroborty, teaches CSE 463 and CSE 225 |
| Instructor | `MRA` | Teaches CSE 211 |
| Instructor (Dean) | `Dr. MK` | Dean tools appear automatically |
| Administrator | `admin` | Clearance list, windows, notices, FAQ, courses, audit log |

The data lives in memory: closing the app resets everything.

### Commit and push

Everything up to 28 Oct is on GitHub. Always `git pull` before you start, then:

```
git status
git add -A
git commit -m "What you changed"
git pull
git push
```

`dist/` and `build/` are ignored, so the APK is not pushed. Share the APK by cable or Drive.

---

## Phase 0: Setup (DONE)

- Flutter 3.47.8 stable. Android licences accepted.
- Android build fixes, all in `android/gradle.properties`:
  - `kotlin.incremental=false`: on the first laptop the project was on E: and the pub cache on C:, which breaks Kotlin caches on Windows.
  - Gradle limited to 2.5 GB of memory (`-Xmx2560m`), because that laptop has 8 GB RAM.
- `android/app/src/main/AndroidManifest.xml`:
  - `INTERNET` permission.
  - A `<queries>` entry so the portal links open in a browser.
- `android/app/build.gradle.kts`: `minSdk` comes from Flutter (24 = Android 7.0), release builds use the debug signing key.
- Launcher icon: the EDU seal, generated from `resources/logo`.
- Fonts: Poppins is bundled in `assets/fonts` (OFL licence), so the app looks the same offline.

## Phase 1: University data (DONE, with data gaps)

Source documents live in `resources/`. `tool/generate_data.py` turns them into Dart files. Re-run it if a document changes:

```
python tool/generate_data.py
```

| File | Content | Source | Status |
|---|---|---|---|
| `lib/data/offer_data.dart` (`kOffer`) | 11 semesters, courses, titles, credits, sections and seats (including split labs such as PHY 102.1 + .11) | CSE Course Offer List & Section Structures, Fall 2026 (.md) | DONE |
| `lib/data/routine_data.dart` (`kRoutine`, `kDays`) | 667 class slots (theory and lab, CSE and EEE), Saturday to Thursday | CSE & EEE All Semesters, Fall 2026 Routine (.docx) | DONE |
| `lib/data/exam_data.dart` (`kExam`) | CSE final exams, Day 1-8, semesters 1-11 | same .docx, exam table | DONE |
| `lib/data/faculty_data.dart` (`kFaculty`) | 55 faculty, full name and short form | same .docx, faculty table | DONE |
| `lib/data/misc_data.dart` | 37 prerequisite entries (`kPrereq`), 6 notices, 14 FAQs | `kPrereq` from the official course catalog (team photo, 27 Oct 2026); notices and FAQs are hand-written | DONE |
| `lib/data/demo_data.dart` | 12 dummy students (233000001-233000012) and their accounts | invented on purpose (Plan §9: no real student IDs or names) | DONE |

`misc_data.dart` is hand-written and may be edited. The four generated files must not be edited by hand.

Notes:
- The plan says "573 slots". The current routine file gives 667 because it includes EEE slots and slots with per-cell times. Trust the generator, not the number in the plan.
- Section number = the number after the dot: `CSE 443.3` is Section 3.
- Typo fixed in the source: Semester 10 Section 7 listed `CSE 466.6`; it is treated as `CSE 466.7`.
- **Sections with no class time ("TBA")**:
  - Project courses: CSE 242, 342, 464, 466 and Section 5 of Semester 1.
  - **Four second lab parts that the routine .docx does not list:** EEE 112.6, CSE 212.6, EEE 214.8 and CSE 312.5. This is a gap in the source document; check it (§3.2).
- **Split labs**: 114 course sections have two or three parts (for example PHY 102.1 with 24 seats plus PHY 102.11 with 8 seats). A student is placed in the first part that still has a seat. Often both parts run at the same time in different rooms.
- Prerequisites: courses with a blank prerequisite cell in the catalog (labs, for example) have none. CSE 464 and CSE 466 have none by decision (the catalog names CSE 445 and CSE 227, which exist nowhere).
- Seat usage in the demo is simulated; room capacity is theory 35, lab 28.

---

## Phase 2: Frontend (DONE)

Architecture (Plan §14):
- Screens call providers (`lib/providers/`), and providers call `ApiService` (`lib/services/api_service.dart`, 41 methods; `updatePhoto` added on 28 Oct). `enrollSelected`, `staffAdvise`, `createExtraRequest` and `joinWaitlist` take `acceptConflicts`; a clash throws `ConflictException`.
- The app currently uses `MockApiService`: in-memory data that enforces the plan's rules.
- Reference data (courses, routine, exams, faculty, prerequisites) is read through `lib/services/catalog.dart`.
- App settings (room capacity, Dean short form, links) are in `lib/utils/app_config.dart`.

### 2.0 Business rules as built

| Area | What the app does |
|---|---|
| Login | Role selector (Student / Instructor / Admin); the username must match the role; any non-empty password works until Phase 4 |
| Clearance | Dues 0 -> Cleared (auto). Special consideration and paid at least the required amount -> Special consideration. Otherwise Not cleared. The Administrator can Give, Revoke or mark Special. Cleared and Special can advise; Not cleared cannot |
| Windows | The Administrator switches Regular advising and Extra course on or off. Both students and staff are blocked when a window is off. Dates are shown to students but not enforced |
| Regular advising | Own semester only. Pick one section, tick courses or press **Select all**, **Confirm**. All or nothing. After the first course the other sections are view-only (section lock). A full drop by faculty or the Dean clears the lock |
| Order of checks | clearance -> window -> section lock -> prerequisite -> seat. Then clashes (class time, exam day) as a **warning**. There is no credit limit |
| Clash alert | A "Clash found" dialog lists each clash. **Go back** saves nothing; **Take anyway** keeps the courses. Applies to regular advising, staff advising, extra requests and joining a waitlist. Approving an extra request does not warn again |
| Waitlist | Join when a section is full; order by request time; the first student is enrolled when a seat frees (drop or seat increase), even if the course clashes |
| Drops | Students never drop regular courses. Faculty drop their own courses, the Dean any. Not tied to a window |
| Extra course | Other semesters' vacant sections. Request needs a reason; one add and one drop request per course; Withdraw only while Pending; no expiry. Faculty or Dean approve or reject; approval needs the Extra window; rejecting is always possible |
| Seat change | At least the current enrolment, at most the room capacity (theory 35, lab 28). Faculty own sections, the Dean all |
| Dean | Advises without clearance (bypass written to the audit log), any course, sees all requests and the audit log |
| Audit log | Enrol, drop, add/drop by faculty, Dean bypass, clearance changes, window changes, seat changes, request decisions, notices, FAQ and course changes |

### 2.1 Student (Plan §7, student items 1-17)

| # | Screen | Status | File |
|---|---|---|---|
| 1 | Login with role selector | DONE | `screens/login/login_screen.dart` |
| 2 | Home: profile card, Advising card, account summary, notices | DONE | `screens/student/home_screen.dart` |
| 3 | Profile | DONE: photo from gallery or camera (`image_picker`), kept in memory until Firebase Storage (Phase 4) | `screens/student/profile_screen.dart` |
| 4 | Menu: Advising, Classes, Reports & Transcripts, Finance, Communication, Reference | DONE | `screens/student/menu_screen.dart` |
| 5 | Advising: clearance check, in the official portal's wording, with links | DONE | `screens/advising/clearance_screen.dart` |
| 6 | Regular advising: sections with seats, checkboxes, Select all, Confirm, section lock | DONE | `screens/advising/advising_screen.dart`, `section_courses_screen.dart` |
| 7 | Waitlist status (join, position, leave) | DONE | same files |
| 8 | Extra course: vacant sections, request with required reason, status, Withdraw | DONE | `screens/advising/extra_course_tab.dart` |
| 9 | My Classes (no Drop button) | DONE | `screens/classes/my_classes_screen.dart` |
| 10 | Class routine: My routine or any semester/section, labs included, week grid or day list | DONE | `screens/classes/class_routine_screen.dart` |
| 11 | Exam routine Day 1-8; PDF one semester at a time | DONE | `screens/classes/exam_routine_screen.dart` |
| 12 | Offer list: searchable, live seats | DONE | `screens/classes/offer_list_screen.dart` |
| 13 | Prerequisite checker | DONE | `screens/reference/prereq_checker_screen.dart` |
| 14 | Faculty directory | DONE (email, phone and position show "Not provided") | `screens/reference/faculty_directory_screen.dart` |
| 15 | Notice board, plus notification bell with unread badge | DONE | `screens/common/notice_board_screen.dart`, `notifications_screen.dart` |
| 16 | FAQ chatbot, keyword matching (Plan §16 step 1) | DONE | `screens/common/faq_chatbot_screen.dart` |
| 17 | Transcript and Finance summary (dummy data) | DONE | `screens/reports/` |

### 2.2 Instructor and Dean (Plan §7)

| # | Screen | Status | File |
|---|---|---|---|
| 1 | Instructor home: My courses (from the routine) | DONE | `screens/staff/my_courses_screen.dart` |
| 2 | Student search, clearance, "Start advising for this student" | DONE (clearance shown on the same screen, not a separate page) | `screens/staff/student_search_screen.dart` |
| 3 | Add/drop: faculty own courses, Dean any course; Dean bypass logged | DONE | `screens/staff/staff_advise_screen.dart`, `section_detail_screen.dart` |
| 4 | Requests inbox: Approve or Reject with comment | DONE | `screens/staff/requests_screen.dart` |
| 5 | Seat change: at least current enrolment, at most room capacity | DONE | `section_detail_screen.dart` |
| 6 | Dean panel: stats, seats of any section, audit log | DONE | `screens/staff/dean_panel_screen.dart` |

### 2.3 Administrator (Plan §7)

| # | Screen | Status | File |
|---|---|---|---|
| 1 | Clearance list: search, filter, Give, Revoke, Special | DONE | `screens/admin/clearance_list_screen.dart` |
| 2 | Windows: Regular advising and Extra course on/off, open and close dates | DONE | `screens/admin/windows_screen.dart` |
| 3-4 | Notices manager, FAQ manager | DONE | `screens/admin/content_manager_screen.dart` |
| 5 | Courses/sections manager | DONE (sections opened or closed as whole groups) | `screens/admin/courses_manager_screen.dart` |
| 6 | Audit log viewer | DONE | `screens/common/audit_log_screen.dart` |

### 2.4 Decisions, gaps and assumptions (be honest about these in the viva)

**Changes to the plan (team decisions, 27 Oct 2026):**
- **No credit limit.** Plan §5 lists a credit-limit step; the team removed it because the real limit depends on the faculty. The app never checks credits.
- **Clashes only warn** (Plan §5 had "time clash" as a block). The student may still take the courses. The new exam-day check is also a warning.

**Other team answers (27 Oct 2026):**
- Room capacity: theory **35**, lab **28** (`AppConfig`). CSE 112 is seeded with 30 seats, so once changed its seats cannot be set back to 30.
- Group number: **6**; the group has no name.
- Prerequisites come from the course catalog photo. CSE 464 and CSE 466 have none.
- Staff advising and extra-request approval respect the windows.
- PDF export: first kept on 9 screens; on **28 Oct** extended to every list screen (14), as Plan §7 says.
- The Bank Deposit Slip Upload form link is set (`AppLinks.uploadDepositForm`).

**Gaps:**
- **PDF export** is on every list screen (14):
  - My Classes, Class routine, Exam routine, Offer list
  - Transcript, Finance
  - Notice board, Faculty directory, FAQ, Prerequisite checker (added 28 Oct)
  - Section roster, Requests (added 28 Oct), Clearance list, Audit log
- **Login accepts any password.** Real authentication is Phase 4.
- **Notifications are in-app only.** Push notifications (FCM) are Phase 4.
- **Profile photo** is kept in memory only (`updatePhoto` stores a `data:` URL), so it is lost when the app restarts, until Firebase Storage (Phase 4, step 4.14).
- **Special consideration**: only the Administrator can mark it. Students cannot apply in the app (Plan §21 item 1 default; the team will say later if a student "Apply" button is wanted).

**Assumptions** (not in the plan or the documents; change them if the team knows better):
- Seat usage is **simulated** (Plan §9). Semester 10 Section 1 is full on purpose, to show the waitlist.
- Faculty cannot override prerequisites (Plan §21 item 2, default).
- Section groups are named **Section 1..n**, as in the real offer list, not A/B/C as in the plan's examples.
- Exam clash = two courses whose final exams have the same day number (Day 1-8). The exam list has no times.
- The 50-request concurrency test uses 35 seats, the largest legal room, instead of the plan's 40.

**Review notes (27 Oct 2026, full cross-check; the fixes are in the code):**
- Split labs: the course tile shows the time of the part the student would get; "By section" lists every part; classes that overlap in the weekly grid sit side by side.
- A student promoted from the waitlist is enrolled even if the course clashes; the clash alert is shown when joining the waitlist.
- Layout: rows wrap instead of overflowing on 360 px phones and with large fonts.
- The Administrator's open and close dates are checked for order (opening before closing).

### 2.5 Tests (66, all passing on 27 Oct 2026)

| File | Tests | What it covers |
|---|---|---|
| `test/advising_rules_test.dart` | 14 | Clearance rules, time parsing, clash and exam-clash logic, FAQ matcher, prerequisites, room capacity, grid lanes |
| `test/advising_flow_test.dart` | 23 | Login, Select all + Confirm, section lock, waitlist (including clashes), drops, Dean bypass, windows, extra requests, seat changes, clash warnings, no credit limit, profile photo |
| `test/concurrency_test.dart` | 1 | 50 parallel requests, 35 seats, exactly 35 succeed |
| `test/data_test.dart` | 6 | Offer list, routine, exams, faculty, prerequisites |
| `test/widget_smoke_test.dart` | 12 | Every role's screens at phone size, the clash alert and its two buttons, split-lab routine, no Drop button, reason required, one-semester PDF, dark-mode inputs |
| `test/layout_test.dart` | 15 | Every role's screens at 360x740, 320x568 and 360x740 with 1.3x font; fails on any overflow |

Plan §19 checklist:

| Checklist item | Covered by | Status |
|---|---|---|
| Select all + Confirm, all or nothing | `advising_flow_test.dart`; the Select all button in `widget_smoke_test.dart` and `layout_test.dart` | DONE |
| Section lock; a full drop clears it | "select all + confirm ...", "a full drop clears the section lock" | DONE |
| No Drop button for students | "student 233000002 has courses but no Drop button"; the API refuses student drops (tested) | DONE |
| Extra request rules | "extra request: one per course, withdraw while pending ...", "approving an extra request needs the extra window ...", "extra request cannot be sent without a reason" | DONE (status replacing the button is code only) |
| Faculty own / Dean any / bypass logged | three tests in `advising_flow_test.dart` | DONE |
| Not cleared blocks advising; Give/Revoke | "not cleared students cannot advise ...", "Revoke makes a cleared student Not cleared ..." | DONE |
| Clash alert (class time, exam day); accepting keeps the course; going back saves nothing; no credit limit | `advising_flow_test.dart`, `widget_smoke_test.dart`, `advising_rules_test.dart` | DONE |
| Closed window blocks actions | "closed windows block advising and extra requests", "staff advising respects the advising windows" | DONE |
| Data matches the PDFs (11 semesters, exams Day 1-8) | `data_test.dart` checks structure | PARTIAL: a person must spot-check (§3.2) |
| PDF is one semester only | "exam routine PDF needs one semester" (button disabled on All) | DONE |
| Concurrency: 50 requests, exactly as many as seats; double tap safe | `concurrency_test.dart`, "a duplicate tap cannot enrol twice" | DONE for the **mock** only; must be repeated on Firestore in Phase 4 |
| Works on a real phone | n/a | **NOT TESTED** (§3.1) |
| Dark-mode inputs readable | "inputs stay readable when the phone is in dark mode" | DONE |

Known issues from the old demo (Plan §20), all avoided:
- The Select all method is called `selectAll`.
- Exams exist for semesters 1-11.
- Lab slots are included in the routine.
- Input text colours are explicit.
- No faculty short form appears beside the section in course selection.

---

## Phase 3: Frontend wrap-up, due 01 Nov 2026 (IN PROGRESS)

| # | Task | Owner | Status | Done when |
|---|---|---|---|---|
| 3.1 | Install `dist/EDU-Advising.apk` on at least two real phones and run the phone test script below | TBD | **TODO** | No crash; notes and screenshots saved |
| 3.2 | Spot-check the routine, exam routine and offer list in the app against the source PDFs: at least semesters 4, 10 and 11 (Plan §19). Also check the 4 lab sections with no time (Phase 1) | TBD | **TODO** | Mismatches fixed in `resources/` and regenerated |
| 3.3 | Take screenshots of every screen for the report (Plan §17 step 12) | TBD | **TODO** | Folder of screenshots |
| 3.4 | Commit and push the work of 26-28 Oct (§1) | Hasibur | **DONE** (28 Oct) | `git log` on GitHub shows it |
| 3.5 | Optional: tests for "reason required" and "no Drop button" | - | **DONE** (28 Oct) | Tests pass |
| 3.6 | Optional: a student "Apply for special consideration" button, if the team wants it | Team | DECISION | Decision recorded here |
| - | Prerequisites from the catalog, deposit form link, staff windows, PDF screens, credit limit, clash alerts, layout fixes | - | DONE (27 Oct) | - |
| - | Project on GitHub | - | DONE | `HasibOp/edu_advising` |

### 3.1 Phone test script

Run it once per phone. Note anything that looks wrong or crashes, with a screenshot.

**Student `233000001` (the main demo)**
1. Login screen looks right; the Student / Instructor / Admin buttons and the demo list fit the screen.
2. Home -> **Start advising** -> clearance page says Cleared -> **Proceed to Advising**.
3. Open **Section 3** -> **Select all** -> **Confirm** -> confirm again -> "Advising confirmed". Go back: the other sections say **VIEW ONLY**.
4. Menu -> every page opens: Course offer list, My classes, Class routine, Exam routine, Transcript, Finance summary, Notice board, FAQ chatbot, Prerequisite checker, Faculty directory.
5. **Exam-day clash alert**: Advising -> Extra course -> Semester 9 -> search `CSE 327` -> **Request** on the first section shown (for example CSE 327.1) -> reason Retake -> Send. Expected: "Clash found: Exam day: CSE 327 and CSE 439 are both on Day 1". Press **Go back** (nothing sent), then repeat and press **Take anyway** (request sent, shows Pending).
6. **Class-time clash alert**: Extra course -> Semester 11 -> `CSE 435.2` -> Request. Expected: "Class time: CSE 435.2 and CSE 463.3 both meet on Saturday 3:00 - 4:30".
7. **Withdraw** the pending request.
8. Class routine -> By section -> Semester 2 -> check that both PHY 102.1 and PHY 102.11 appear; try the week grid and the day list.
9. Download a PDF (My Classes, Exam routine for one semester): the share sheet opens and the PDF looks right.
10. Profile: edit contact details (phone must be 11 digits starting with 01). Notification bell opens.
11. FAQ chatbot: ask "is there a credit limit" and "section is full".
12. Rotate the phone; turn on a large system font. Nothing should be cut off.

**Student `233000004`**: Advising is locked, red remark, the Proceed button is disabled.
**Student `233000012`**: Advising -> Waitlist tab shows position #1 for CSE 443.1.
**Student `233000005`**: Section 3 shows "Prerequisite not passed: CSE 327" and Confirm fails with nothing enrolled.

**Instructor `TRINA`**
1. My courses lists her sections; open one (roster, change seats, PDF).
2. Requests tab: approve one request (the student gets enrolled as Extra).
3. Students tab -> search `233000001` -> Start advising: she can add and drop only her own courses.

**Dean `Dr. MK`**
1. Dean panel opens; audit log shows entries.
2. Students -> `233000004` (Not cleared) -> "Dean bypass" banner -> add a course; the audit log shows a bypass entry.

**Administrator `admin`**
1. Clearance list: Give clearance to `233000004`; Revoke someone; Special.
2. Windows: switch Regular advising off, then log in as a student: enrolling is blocked. Switch it back on.
3. Content: add a notice (a student sees it with a NEW badge); edit an FAQ.
4. Courses: open and close a section; add a course.
5. Audit log lists every change you made.

---

## Phase 4: Backend, due 13 Dec 2026 (TODO, nothing started)

Current state:
- No Firebase packages in `pubspec.yaml`.
- No `firebase.json`, `firestore.rules`, `functions/` or `google-services.json`.
- No `ApiService` implementation other than `MockApiService`.

**Goal (Plan §11, §17 Phase B):** a `FirebaseApiService implements ApiService`, with the same methods, plugged into `main.dart`. Screens and providers must not need changes.

Work in the plan's order:

| Step | Work | ApiService methods | Plan | Done when |
|---|---|---|---|---|
| 4.1 | Create the Firebase project, run `flutterfire configure`, add packages (`firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `firebase_messaging`, `firebase_storage`) | n/a | §13 | App starts with Firebase initialised |
| 4.2 | Auth and roles: `users` collection with `role` and `isDean` | `login` | §10.1, §15 | Real passwords; wrong role is rejected |
| 4.3 | Seed Firestore from `kOffer`, `kRoutine`, `kExam`, `kFaculty`, `kPrereq` and the demo students | n/a | §10.2-10.5, §10.13-10.14 | Collections match the Dart data |
| 4.4 | Students, clearance, transcript, finance | `fetchStudent(s)`, `updateContact`, `fetchTranscript`, `fetchFinance`, `setClearance` | §3, §10.2, §10.8-10.9 | Clearance rules as in Plan §3 |
| 4.5 | **Advising core**: one transaction; validation order clearance, window, lock, prerequisite, seat; then class-time and exam-day clashes, which throw `ConflictException` unless `acceptConflicts` is true; **no credit limit**; enrollment ID `{studentId}_{sectionId}`; place the student in the first part of a split lab that has a seat | `fetchSections`, `fetchEnrollments`, `enrollSelected` | §5, §6, §10.5-10.6 | **Concurrency test on Firestore: 50 requests, 35 seats (largest legal room), exactly 35** |
| 4.6 | Waitlist ordered by server timestamp; promotion inside the drop transaction, **accepting clashes**; `joinWaitlist` warns on clashes | `fetchWaitlist`, `fetchSectionWaitlist`, `joinWaitlist`, `leaveWaitlist` | §6, §10.7 | First in line is enrolled when a seat frees |
| 4.7 | Faculty and Dean tools; Dean bypass written to the audit log; staff advising checks the windows | `staffAdvise`, `staffDrop`, `changeSeats`, `fetchSectionEnrollments` | §2, §11 | Permission matrix (Plan §15) holds |
| 4.8 | Extra-course requests, one per course (doc ID `{studentId}_{courseCode}_{kind}`); approval needs the Extra window, rejecting does not; creating a request warns on clashes, approving does not | `createExtraRequest`, `withdrawExtraRequest`, `decideExtraRequest`, `fetchMyRequests`, `fetchRequestsFor` | §4, §10.11 | Withdraw only while Pending |
| 4.9 | Windows and the Administrator's course tools | `fetchWindows`, `updateWindows`, `saveCourse`, `deleteCourse`, `addSectionGroup`, `deleteSectionGroup` | §10.12 | Closing a window blocks actions immediately |
| 4.10 | Notices and push notifications (FCM) | `fetchNotices`, `saveNotice`, `deleteNotice`, `fetchReadNoticeIds`, `markNoticeRead`, `fetchNotifications`, `markNotificationsRead` | §10.15, §11 triggers | Push on new notice, request decided, waitlist promotion |
| 4.11 | FAQ (the keyword bot already works; optional LLM step through a Cloud Function, never a key in the app) | `fetchFaqs`, `saveFaq`, `deleteFaq` | §16 | Admin edits show up in the bot |
| 4.12 | Security Rules: clients never write `enrolled`, `lockedSection` or `clearanceStatus` | n/a | §12 | Rules tested with the emulator suite |
| 4.13 | Audit log for every action listed in Plan §10.17 | `fetchAuditLogs` | §10.17 | Dean and admin can read it; only functions write it |
| 4.14 | Profile photo upload (Storage): upload the bytes, store the download URL in `photoUrl` | `updatePhoto` | §10.1 | Photo shows on Profile after a restart |

Notes for Phase 4:
- If the Blaze plan is not available, use the plan's fallback (Plan §11): client-side Firestore transactions, Security Rules, and waitlist promotion inside the drop transaction.
- `MockApiService` documents the expected behaviour of each method; read it before writing the Firebase version. The tests in `test/advising_flow_test.dart` and `test/concurrency_test.dart` can be pointed at the new service: they are the acceptance tests.
- Indexes needed: Plan §10, "Indexes you will need".
- Screens only know `ApiService` and `ApiException` / `ConflictException`. Keep the user-facing messages the same.

---

## Phase 5: Report, demo video, viva, due 12-13 Dec 2026 (TODO)

From Plan §17 Phase C and the course outline (Plan §1):

| # | Deliverable | Content | Due |
|---|---|---|---|
| 5.1 | PDF report | Problem, roles, ER diagram (Plan §10 relationships), flow, screenshots, tech stack, concurrency testing, self-evaluation; **group 6** (no group name) | 12 Dec 2026 |
| 5.2 | Demo video | 10 minutes or less; every member speaks | 12 Dec 2026 |
| 5.3 | Viva preparation | Why a transaction, how seats are protected, how roles are enforced, clearance logic, why clashes only warn and there is no credit limit (Plan §17 Phase C) | 13 Dec 2026 |

---

## Open decisions (do not guess: ask the team)

Answered on 27 Oct 2026 (recorded in §2.4): no credit limit, CSE 464/466 without prerequisite, clashes only warn, room capacities 35 and 28, staff advising and approval respect the windows (Dean included, confirmed 28 Oct), PDF on 9 screens (changed to all 14 on 28 Oct), deposit form link, group number 6 (no name).

1. **Special consideration for students**: should a student be able to apply in the app, with the Administrator approving? Today only the Administrator marks it. The team said it will answer later.
2. Real faculty emails, phones and positions (Plan §21 item 3). Until then the directory shows "Not provided".
3. The 4 lab sections with no time in the routine (EEE 112.6, CSE 212.6, EEE 214.8, CSE 312.5): what are their class times?
4. Should the Administrator's open and close dates switch the windows automatically in Phase 4, or stay informational?
5. Who owns which Phase 3, 4 and 5 task: the plan names only Anamur, as frontend lead.

## Known minor issues (not fixed, low priority)

- The course and notice forms in the Administrator screens do not block a double tap on Save.
- Notifications refresh at login and after certain actions, not continuously.
- The FAQ bot matches keywords inside words (for example "pay" inside "payment"); fine for the demo.
- A seat change on a split lab changes the first part only.
- `kPrereq` has no entry for courses the offer list never uses (for example CSE 445, CSE 227).

## Change log

**26 Oct 2026**: Phases 0-2 finished: data generated, all screens, `MockApiService`, 33 tests; release APK checked on an Android 17 emulator.

**27 Oct 2026** (this work session):
- Applied the team's answers: deposit form link, prerequisites from the catalog photo, room capacity 35 / 28, group 6, staff advising and approval respect the windows.
- Removed the credit limit and the CSE 464 / CSE 466 prerequisites.
- Class-time and exam-day clashes are now warnings with a "Take anyway" button (regular advising, staff advising, extra requests, waitlist).
- Full cross-check found and fixed: waitlist promotion lost a clashing student; split-lab times and "By section" routine; layout overflow on 360 px phones and large fonts (7 places); student search crash after leaving; open/close date order; misleading "project course" label; FAQ answer for credits.
- New tests: 33 -> 66 (clash logic, waitlist clashes, widget alert, split-lab routine, layout at three phone setups).
- Built `dist/EDU-Advising.apk` (universal, Android 7.0+). Not yet run on a device.
- Moved on this laptop: SDK now at `D:\Android\Sdk`; `android/local.properties` updated; Android Studio's JDK at `D:\Android Studio\jbr` used for builds.

**28 Oct 2026** (other laptop, `E:\edu_advising`):
- Merged the 27 Oct work from GitHub with the local work; kept the team's rules (windows block the Dean too, no credit limit, rooms 35 / 28).
- Profile photo: gallery or camera (`image_picker`), new `ApiService.updatePhoto`, shown on Profile and the Home card.
- PDF on the 5 remaining list screens: Notice board, Faculty directory, Requests, FAQ, Prerequisite checker.
- New tests: 66 -> 71 (photo, no Drop button, reason required, one-semester PDF, dark-mode inputs).
- Rebuilt the APK. Not yet run on a device.

## Rules for AI assistants on this repository

- Requirements come from `EDU_Advising_Plan.md` plus the team decisions in §2.4. Do not add features, roles or rules that are not there; if something is unclear, list it under "Open decisions" and ask.
- Never put real student IDs or names in the app (Plan §9). Use the dummy IDs `233000001`-`233000012`.
- Do not edit the generated files `offer_data.dart`, `routine_data.dart`, `exam_data.dart` and `faculty_data.dart` by hand. Change `resources/` and run `python tool/generate_data.py`.
- Screens must not call Firebase directly. Everything goes through `ApiService`.
- After a change, run `flutter analyze` and `flutter test`. Report real results; do not claim a test passed without running it.
- In widget tests, await `MockApiService` calls inside `tester.runAsync`; a plain `await` hangs because the mock uses timers.
- Do not claim the app works "on a phone" until the phone test script (§3.1) has been run on a device.
- Update this file when a task changes status.
- Build settings for this laptop are in §1 (SDK `D:\Android\Sdk`, JDK `D:\Android Studio\jbr`). Do not install a second JDK or SDK.
- The first laptop has 8 GB RAM. Prefer `flutter run` on a USB phone or `-d chrome` over the emulator.
