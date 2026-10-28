# EDU Advising (Flutter frontend)

Course advising app for East Delta University (CSE 464 project, Fall 2026).
Students, instructors, the Dean and the Administrator share one app; the
account decides which screens appear. This is the **frontend phase**: every
screen works on in-memory dummy data behind `ApiService`, ready to be switched
to Firebase in the backend phase.

**What is done and what is left, phase by phase: see [PROJECT_ROADMAP.md](PROJECT_ROADMAP.md).**

## Run it

```bash
flutter pub get
flutter run                 # phone over USB, or an emulator
flutter run -d chrome       # quick check in the browser
flutter test                # 40 tests: rules, data, concurrency, every screen
flutter build apk --release # installable APK in build/app/outputs/flutter-apk/
```

## Demo accounts (any password)

| Role | Username | What it shows |
|---|---|---|
| Student | `233000001` | Semester 10, cleared, not advised yet (best for the demo) |
| Student | `233000002` | Already enrolled in Section 2, other sections view-only |
| Student | `233000003` | Special consideration |
| Student | `233000004` | Not cleared (red remark, advising locked) |
| Student | `233000005` | Failed CSE 327, prerequisite block on CSE 443 / CSE 463 |
| Student | `233000012` | On the waitlist for the full CSE 443.1 |
| Instructor | `TRINA` | Teaches CSE 463 / CSE 225, has a pending request |
| Instructor (Dean) | `Dr. MK` | Dean tab: any course, clearance bypass, audit log |
| Administrator | `admin` | Clearance list, windows, notices, FAQ, courses, audit log |

Students `233000001`-`233000012` are dummy people. Any faculty short form from
the routine (e.g. `MRA`, `JHJ`) can log in as an instructor. The login screen
lists all demo accounts; tap one to fill the form.

## Where the data comes from

| File | Source |
|---|---|
| `lib/data/offer_data.dart` (`kOffer`) | CSE Course Offer List & Section Structures - Fall 2026 |
| `lib/data/routine_data.dart` (`kRoutine`, 667 slots incl. labs) | CSE & EEE All Semesters - Fall 2026 Routine |
| `lib/data/exam_data.dart` (`kExam`) | same routine file, exam table (Day 1-8) |
| `lib/data/faculty_data.dart` (`kFaculty`, 55 faculty) | same routine file, faculty table |
| `lib/data/misc_data.dart` | hand-written: prerequisites, notices, FAQ - **please check `kPrereq`** |
| `lib/data/demo_data.dart` | dummy students and their accounts |

The first four are generated: put new documents in `resources/pdfs/` and run
`python tool/generate_data.py`. A section is the number after the dot:
`CSE 443.3` is Section 3. Seat usage is simulated (Semester 10 Section 1 is
full on purpose, to show the waitlist).

## Structure

```
lib/
  data/        generated university data + demo seed data
  models/      AppUser, Student, Course/CourseSection, ClassSlot, Enrollment,
               WaitlistEntry, ExtraRequest, portal records (notices, audit, ...)
  services/    ApiService (interface), MockApiService (in-memory backend),
               Catalog (routine/exam/faculty lookups), AdvisingRules
  providers/   Auth, Advising (student), Staff (instructor/Dean), Admin, Notification
  screens/
    login/     one login page with role selector
    student/   shell (Home | Menu), home, menu, profile
    advising/  clearance check -> Regular | Extra course | Waitlist, section picker
    classes/   my classes, class routine (by section / mine), exam routine, offer list
    reports/   transcript, finance
    reference/ prerequisite checker, faculty directory
    common/    notice board, notifications, FAQ chatbot, audit log
    staff/     instructor + Dean: my courses, roster, student search, advise, requests, Dean panel
    admin/     clearance list, windows, notices & FAQ, courses & sections
  widgets/     top bar (gold line, bell, logout), badges, routine grid, cards
  utils/       theme (plan colours), config & links, PDF export, FAQ matcher
tool/generate_data.py   rebuilds lib/data from resources/pdfs
```

## Rules implemented (plan sections 3-6)

- Validation order: clearance -> window -> section lock -> prerequisite ->
  credit limit (18) -> time clash -> seat. Enrolment is all-or-nothing.
- Enrolment ID `{studentId}_{sectionId}`: a double tap cannot enrol twice.
- Section lock: after the first regular course, other sections are view-only;
  dropping everything clears it.
- Full section -> waitlist ordered by server time; a freed seat (drop or seat
  increase) promotes the first student automatically.
- Students never drop regular courses. Faculty add/drop their own courses
  directly; the Dean any course, also without clearance (logged as DEAN_BYPASS).
  A closed window stops faculty adding courses and approving requests; the
  Dean can still act (logged).
- Extra course: request with a reason, one per course, withdraw only while
  Pending, faculty or Dean approves (enrols as EXTRA) or rejects.
- Administrator: Give / Revoke / Special clearance, Regular and Extra windows.
- Seat change: not below current enrolment, not above room capacity
  (room sizes are not in the documents: theory 45, lab 30 assumed).
- `test/concurrency_test.dart`: 50 parallel requests on a 40-seat section ->
  exactly 40 succeed. Run the same test against Firestore later.

## Backend phase: what to replace

Screens only talk to providers, and providers only talk to `ApiService`
(`lib/services/api_service.dart`).

1. Create `FirebaseApiService implements ApiService` (Auth, Firestore
   transactions / Cloud Functions). Every model has `toJson`/`fromJson`.
2. Seed Firestore from `kOffer`, `kRoutine`, `kExam`, `kFaculty`, `kPrereq`.
3. In `main.dart`, replace `MockApiService()` with the Firebase service.
4. Throw `ApiException('message')` for errors the user should see.
5. `updatePhoto` should upload to Firebase Storage and save the download
   URL as `photoUrl` (the mock keeps a `data:` URL in memory).
6. Fill in `AppLinks.uploadDepositForm` in `lib/utils/app_config.dart` with the
   real Bank Deposit Slip form link.

## Notes

- `android/gradle.properties` sets `kotlin.incremental=false` (the project is on
  E: and the pub cache on C:, which breaks Kotlin caches on Windows) and limits
  Gradle to 2.5 GB of memory for 8 GB laptops.
- The previous version of the frontend is saved in
  `backup/frontend_before_plan_rebuild_2026-10-26.zip`.
