# EDU Advising: Status and Roadmap

Status as of **26 Oct 2026**. For the team (Anamur, Hasibur, Sumi, Tarin) and
for any AI assistant working on this repository.

**Sources of truth, in this order:**
1. `EDU_Advising_Plan.md`: the agreed requirements (cited below as "Plan §N").
2. This file: what is built, what is left, and the open decisions.
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
| 1 | Real university data in the app | n/a | DONE |
| 2 | Frontend, all screens on dummy data (Plan §17 Phase A) | **01 Nov 2026** | DONE, with gaps listed in §2.4 |
| 3 | Frontend wrap-up before submission | **01 Nov 2026** | DONE in code (27 Oct 2026); phone test, PDF spot-check and screenshots remain, see §3 |
| 4 | Backend: Firebase, database, CRUD (Plan §17 Phase B) | **13 Dec 2026** | TODO (nothing started) |
| 5 | Report, demo video, viva (Plan §17 Phase C) | **12-13 Dec 2026** | TODO |

Facts from the plan (Plan §1, §13):
- Flutter frontend; Firebase backend (Auth, Firestore, Cloud Functions, FCM, Storage).
- Advising is the only main module.
- No live payment gateway. No separate Dean login: Dr. MK signs in as an instructor.

---

## Phase 0: Setup (DONE)

- Flutter 3.47.8 stable, Android SDK at `C:\AndroidSdk`, Android licences accepted.
- Android build fixes, all in `android/gradle.properties`:
  - `kotlin.incremental=false`: the project is on E: and the pub cache on C:, which breaks Kotlin caches on Windows.
  - Gradle limited to 2.5 GB of memory (`-Xmx2560m`), because the dev laptop has 8 GB RAM.
- `android/local.properties` points to the real SDK.
- `android/app/src/main/AndroidManifest.xml`:
  - `INTERNET` permission.
  - A `<queries>` entry so the portal links open in a browser.
- Launcher icon: the EDU seal, generated from `resources/logo`.

## Phase 1: University data (DONE, one review needed)

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
| `lib/data/misc_data.dart` | 38 prerequisite entries (`kPrereq`), 6 notices, 13 FAQs | `kPrereq` from the official course catalog (team photo, 27 Oct 2026); notices and FAQs are hand-written | DONE; two catalog entries not copied, see §2.4 |
| `lib/data/demo_data.dart` | 12 dummy students (233000001-233000012) and their accounts | invented on purpose (Plan §9: no real student IDs or names) | DONE |

Notes:
- The plan says "573 slots". The current routine file gives 667 because it includes EEE slots and slots with per-cell times. Trust the generator, not the number in the plan.
- Section number = the number after the dot: `CSE 443.3` is Section 3.
- Typo fixed in the source: Semester 10 Section 7 listed `CSE 466.6`; it is treated as `CSE 466.7`.
- Sections with no routine slot are shown as "Time TBA": the project courses CSE 242, 342, 464, 466 and Section 5 of Semester 1.

---

## Phase 2: Frontend (DONE, see gaps in §2.4)

Architecture (Plan §14):
- Screens call providers (`lib/providers/`), and providers call `ApiService` (`lib/services/api_service.dart`, 40 methods; `enrollSelected`, `staffAdvise` and `createExtraRequest` take `acceptConflicts`).
- The app currently uses `MockApiService`: in-memory data that enforces the plan's rules.

Verification run on 26 Oct 2026:
- `flutter analyze`: no issues.
- `flutter test`: 48 tests pass (27 Oct 2026).
- Release APK installed on an Android 17 emulator (x86_64). Checked by hand there: login, clearance, Select all, Confirm, routine, PDF share.

### 2.1 Student (Plan §7, student items 1-17)

| # | Screen | Status | File |
|---|---|---|---|
| 1 | Login with role selector | DONE | `screens/login/login_screen.dart` |
| 2 | Home: profile card, Advising card, account summary, notices | DONE | `screens/student/home_screen.dart` |
| 3 | Profile | PARTIAL: photo upload is a placeholder (needs Firebase Storage) | `screens/student/profile_screen.dart` |
| 4 | Menu: Advising, Classes, Reports & Transcripts, Finance, Communication, Reference | DONE | `screens/student/menu_screen.dart` |
| 5 | Advising: clearance check, in the official portal's wording, with links | DONE | `screens/advising/clearance_screen.dart` |
| 6 | Regular advising: sections with seats, checkboxes, Select all, Confirm, section lock | DONE | `screens/advising/advising_screen.dart`, `section_courses_screen.dart` |
| 7 | Waitlist status (join, position, leave) | DONE | same files |
| 8 | Extra course: vacant sections, request with required reason, status, Withdraw | DONE | `screens/advising/extra_course_tab.dart` |
| 9 | My Classes (no Drop button) | DONE | `screens/classes/my_classes_screen.dart` |
| 10 | Class routine: My routine or any semester/section, labs included | DONE | `screens/classes/class_routine_screen.dart` |
| 11 | Exam routine Day 1-8; PDF one semester at a time | DONE | `screens/classes/exam_routine_screen.dart` |
| 12 | Offer list: searchable, live seats | DONE | `screens/classes/offer_list_screen.dart` |
| 13 | Prerequisite checker | DONE (data PARTIAL, see Phase 1) | `screens/reference/prereq_checker_screen.dart` |
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
| 5 | Seat change: at least current enrolment, at most room capacity | DONE (room capacity is an assumption, see §2.4) | `section_detail_screen.dart` |
| 6 | Dean panel: stats, seats of any section, audit log | DONE | `screens/staff/dean_panel_screen.dart` |

### 2.3 Administrator (Plan §7)

| # | Screen | Status | File |
|---|---|---|---|
| 1 | Clearance list: search, filter, Give, Revoke, Special | DONE | `screens/admin/clearance_list_screen.dart` |
| 2 | Windows: Regular advising and Extra course on/off, open and close dates | DONE | `screens/admin/windows_screen.dart` |
| 3-4 | Notices manager, FAQ manager | DONE | `screens/admin/content_manager_screen.dart` |
| 5 | Courses/sections manager | DONE (sections opened or closed as whole groups) | `screens/admin/courses_manager_screen.dart` |
| 6 | Audit log viewer | DONE | `screens/common/audit_log_screen.dart` |

### 2.4 Gaps, assumptions and deviations (be honest about these in the viva)

**Gaps:**
- **PDF export** exists on 9 screens:
  - My Classes, Class routine, Exam routine, Offer list
  - Transcript, Finance
  - Section roster, Clearance list, Audit log

  Plan §7 says "any list screen". These have no PDF button: Notice board, Faculty directory, Requests, FAQ, Prerequisite checker.
- **Login accepts any password.** Real authentication is Phase 4.
- **Notifications are in-app only.** Push notifications (FCM) are Phase 4.
- **Profile photo** is a placeholder.

**Team answers (27 Oct 2026)**:
- **No credit limit.** (First set to 21, then removed by the team on 27 Oct 2026: the real limit depends on the faculty, so the app does not check it.) This changes Plan §5, which lists a credit limit step.
- Room capacity: **theory 35, lab 28** (`AppConfig`). CSE 112 is seeded with 30 seats, so its seats cannot be set back to 30 once changed.
- Group number: **6**; the group has no name.
- Prerequisites come from the course catalog photo. **CSE 464 and CSE 466 have no prerequisite**: the photo names courses (CSE 445, CSE 227) that exist nowhere, and the team chose to skip them.
- **Clashes only warn.** If courses clash in class time, or two final exams fall on the same day, the app shows a "Clash found" alert. The user can go back, or press "Take anyway" and keep the courses. The check runs on regular advising, staff advising and extra requests; approval of an extra request does not repeat it (the student already accepted). Prerequisites, clearance, windows, section lock and full seats still block.
- Staff advising and extra-request approval **respect the windows** (§2.4).
- PDF stays on the 9 screens.

**Assumptions** (not in the plan or the documents; change them if the team knows better):
- Seat usage is **simulated** (Plan §9). Semester 10 Section 1 is full on purpose, to show the waitlist.
- Special consideration: the Administrator marks it (Plan §21 item 1, default).
- Faculty cannot override prerequisites (Plan §21 item 2, default).

**Deviations and behaviour the plan does not specify:**
- Section groups are named **Section 1..n**, as in the real offer list, not A/B/C as in the plan's examples.
- Faculty and Dean advising (`staffAdvise`) checks the window: regular courses need the Regular window, other-semester (extra) courses need the Extra window. The Dean skips clearance, not the window.
- Approving an extra request needs the Extra window open. Rejecting is always allowed.
- Staff drops are not tied to a window.
- The Upload Deposit Form button opens the real Bank Deposit Slip Upload form (`AppLinks.uploadDepositForm`).
- The 50-request concurrency test now uses 35 seats, the largest legal room size, instead of the plan's 40.

### 2.5 Testing checklist (Plan §19)

| Checklist item | Covered by | Status |
|---|---|---|
| Select all + Confirm, all or none | `advising_flow_test.dart`: "select all + confirm ...", "enrolment is all-or-nothing ..." | DONE (API level; the Select all button is exercised in the widget test) |
| Section lock; a full drop clears it | "select all + confirm ...", "a full drop clears the section lock" | DONE |
| No Drop button for students | code only (`my_classes_screen.dart`) | NOT TESTED |
| Extra request rules | "extra request: one per course, withdraw while pending ...", "approving an extra request needs the extra window ..." | PARTIAL: no test for "reason required" or "status replaces the button" |
| Faculty own / Dean any / bypass logged | three tests in `advising_flow_test.dart` | DONE |
| Not cleared blocks advising; Give/Revoke | "not cleared students cannot advise; admin Give ...", "Revoke makes a cleared student Not cleared ..." | DONE |
| Clash alert (class time, exam day); accepting keeps the course; going back saves nothing; no credit limit | `advising_flow_test.dart` (4 clash tests, "there is no credit limit"), `widget_smoke_test.dart` (alert and "Take anyway" / "Go back" on the real screens), `advising_rules_test.dart` | DONE |
| Closed window blocks actions | "closed windows block advising and extra requests", "staff advising respects the advising windows" | DONE |
| Data matches the PDFs (11 semesters, exams Day 1-8) | `data_test.dart` checks structure | PARTIAL: no comparison with the PDFs; a person must spot-check |
| PDF is one semester only | code only | NOT TESTED |
| Concurrency: 50 requests, 40 seats, exactly 40 succeed; double tap safe | `concurrency_test.dart`, "a duplicate tap cannot enrol twice" | DONE for the **mock** only (35 seats); must be repeated on Firestore in Phase 4 |
| Dark-mode inputs readable | `themeMode: light` plus explicit input colours | NOT TESTED |

Known issues from the old demo (Plan §20), all avoided:
- The Select all method is called `selectAll`.
- Exams exist for semesters 1-11.
- Lab slots are included in the routine.
- Input text colours are explicit.
- No faculty short form appears beside the section in course selection.

---

## Phase 3: Frontend wrap-up, due 01 Nov 2026 (TODO)

| # | Task | Owner | Done when |
|---|---|---|---|
| 3.1 | Install `app-arm64-v8a-release.apk` on at least two real phones and run the demo flow for every role | TBD | No crash; screenshots saved |
| 3.2 | ~~Check `kPrereq`~~ DONE 27 Oct 2026 from the catalog photo; CSE 464 and CSE 466 have none by decision | n/a | n/a |
| 3.3 | Spot-check the routine, exam routine and offer list in the app against the source PDFs: at least semesters 4, 10 and 11 (Plan §19) | TBD | Mismatches fixed in `resources/` and regenerated |
| 3.4 | ~~Bank Deposit Slip form link~~ DONE 27 Oct 2026 | n/a | n/a |
| 3.5 | ~~DECISION: staff advising and approval respect the windows~~ DONE: yes, implemented and tested | n/a | n/a |
| 3.6 | ~~DECISION: PDF screens~~ DONE: keep the 9 screens | n/a | n/a |
| 3.7 | Optional: add tests for "reason required" and "no Drop button" (Revoke is done) | TBD | Tests pass |
| 3.8 | Take screenshots of every screen for the report (Plan §17 step 12) | TBD | Folder of screenshots |
| 3.9 | Recommended (not in the plan): put the project on GitHub so all four members share one copy. The folder is not a git repository yet | TBD | Repository created; everyone can pull |

How to produce the build:
```
flutter build apk --release --split-per-abi
```
The phone APK is `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.

---

## Phase 4: Backend, due 13 Dec 2026 (TODO, nothing started)

Current state:
- No Firebase packages in `pubspec.yaml`.
- No `firebase.json`, `firestore.rules`, `functions/` or `google-services.json`.
- No `ApiService` implementation other than `MockApiService`.

**Goal (Plan §11, §17 Phase B):** a `FirebaseApiService implements ApiService`, with the same 40 methods, plugged into `main.dart`. Screens and providers must not need changes.

Work in the plan's order:

| Step | Work | ApiService methods | Plan | Done when |
|---|---|---|---|---|
| 4.1 | Create the Firebase project, run `flutterfire configure`, add packages (`firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `firebase_messaging`, `firebase_storage`) | n/a | §13 | App starts with Firebase initialised |
| 4.2 | Auth and roles: `users` collection with `role` and `isDean` | `login` | §10.1, §15 | Real passwords; wrong role is rejected |
| 4.3 | Seed Firestore from `kOffer`, `kRoutine`, `kExam`, `kFaculty`, `kPrereq` and the demo students | n/a | §10.2-10.5, §10.13-10.14 | Collections match the Dart data |
| 4.4 | Students, clearance, transcript, finance | `fetchStudent(s)`, `updateContact`, `fetchTranscript`, `fetchFinance`, `setClearance` | §3, §10.2, §10.8-10.9 | Clearance rules as in Plan §3 |
| 4.5 | **Advising core**: one transaction; validation order clearance, window, lock, prerequisite, seat; then class-time and exam-day clashes, which throw `ConflictException` unless `acceptConflicts` is true; no credit limit; enrollment ID `{studentId}_{sectionId}` | `fetchSections`, `fetchEnrollments`, `enrollSelected` | §5, §6, §10.5-10.6 | **Concurrency test on Firestore: 50 requests, 35 seats (largest legal room), exactly 35** |
| 4.6 | Waitlist ordered by server timestamp; promotion inside the drop transaction | `fetchWaitlist`, `fetchSectionWaitlist`, `joinWaitlist`, `leaveWaitlist` | §6, §10.7 | First in line is enrolled when a seat frees |
| 4.7 | Faculty and Dean tools; Dean bypass written to the audit log | `staffAdvise`, `staffDrop`, `changeSeats`, `fetchSectionEnrollments` | §2, §11 | Permission matrix (Plan §15) holds |
| 4.8 | Extra-course requests, one per course (doc ID `{studentId}_{courseCode}_{kind}`) | `createExtraRequest`, `withdrawExtraRequest`, `decideExtraRequest`, `fetchMyRequests`, `fetchRequestsFor` | §4, §10.11 | Withdraw only while Pending |
| 4.9 | Windows and the Administrator's course tools | `fetchWindows`, `updateWindows`, `saveCourse`, `deleteCourse`, `addSectionGroup`, `deleteSectionGroup` | §10.12 | Closing a window blocks actions immediately |
| 4.10 | Notices and push notifications (FCM) | `fetchNotices`, `saveNotice`, `deleteNotice`, `fetchReadNoticeIds`, `markNoticeRead`, `fetchNotifications`, `markNotificationsRead` | §10.15, §11 triggers | Push on new notice, request decided, waitlist promotion |
| 4.11 | FAQ (the keyword bot already works; optional LLM step through a Cloud Function, never a key in the app) | `fetchFaqs`, `saveFaq`, `deleteFaq` | §16 | Admin edits show up in the bot |
| 4.12 | Security Rules: clients never write `enrolled`, `lockedSection` or `clearanceStatus` | n/a | §12 | Rules tested with the emulator suite |
| 4.13 | Audit log for every action listed in Plan §10.17 | `fetchAuditLogs` | §10.17 | Dean and admin can read it; only functions write it |
| 4.14 | Profile photo upload (Storage) | `updateContact`, or a new method | §10.1 | Photo shows on Profile |

Notes for Phase 4:
- If the Blaze plan is not available, use the plan's fallback (Plan §11): client-side Firestore transactions, Security Rules, and waitlist promotion inside the drop transaction.
- `MockApiService` documents the expected behaviour of each method; read it before writing the Firebase version.
- Indexes needed: Plan §10, "Indexes you will need".

---

## Phase 5: Report, demo video, viva, due 12-13 Dec 2026 (TODO)

From Plan §17 Phase C and the course outline (Plan §1):

| # | Deliverable | Content | Due |
|---|---|---|---|
| 5.1 | PDF report | Problem, roles, ER diagram (Plan §10 relationships), flow, screenshots, tech stack, concurrency testing, self-evaluation; group name (unknown, Plan §21 item 6) | 12 Dec 2026 |
| 5.2 | Demo video | 10 minutes or less; every member speaks | 12 Dec 2026 |
| 5.3 | Viva preparation | Why a transaction, how seats are protected, how roles are enforced, clearance logic (Plan §17 Phase C) | 13 Dec 2026 |

---

## Open decisions (do not guess: ask the team)

Answered on 27 Oct 2026: no credit limit, CSE 464/466 without prerequisite, clashes only warn, room capacities 35 and 28, staff advising and approval respect the windows, PDF on 9 screens, deposit form link, group number 6 (no name).

1. Real faculty emails, phones and positions (Plan §21 item 3).
2. Who owns which Phase 3, 4 and 5 task: the plan names only Anamur, as frontend lead.

## Rules for AI assistants on this repository

- Requirements come from `EDU_Advising_Plan.md`. Do not add features, roles or rules that are not there; if something is unclear, list it under "Open decisions" and ask.
- Never put real student IDs or names in the app (Plan §9). Use the dummy IDs `233000001`-`233000012`.
- Do not edit the generated files `offer_data.dart`, `routine_data.dart`, `exam_data.dart` and `faculty_data.dart` by hand. Change `resources/` and run `python tool/generate_data.py`.
- Screens must not call Firebase directly. Everything goes through `ApiService`.
- After a change, run `flutter analyze` and `flutter test`. Report real results; do not claim a test passed without running it.
- Update this file when a task changes status.
- The dev laptop has 8 GB RAM. Prefer `flutter run` on a USB phone or `-d chrome` over the emulator.
