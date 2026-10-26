import '../data/demo_data.dart';
import '../data/misc_data.dart';
import '../models/app_user.dart';
import '../models/class_slot.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/extra_request.dart';
import '../models/portal.dart';
import '../models/student.dart';
import '../utils/app_config.dart';
import '../utils/formatters.dart';
import 'advising_rules.dart';
import 'api_service.dart';
import 'catalog.dart';

class _WaitItem {
  _WaitItem(this.id, this.studentId, this.sectionId, this.createdAt);
  final String id;
  final String studentId;
  final String sectionId;
  final DateTime createdAt;
}

/// In-memory backend for the frontend phase.
///
/// It enforces the same rules the Cloud Functions will: validation order,
/// all-or-nothing enrolment, section lock, idempotent enrolment IDs, waitlist
/// promotion and the audit log. Each call waits [latency] first and then runs
/// its read-check-write without any await, so concurrent calls behave like
/// server transactions (see test/concurrency_test.dart).
class MockApiService implements ApiService {
  MockApiService({
    this.latency = const Duration(milliseconds: 300),
    bool simulateSeats = true,
    bool seedDemo = true,
  }) {
    _seedSections(simulateSeats);
    if (seedDemo) {
      for (final d in kDemoStudents) {
        addDemoStudent(d);
      }
      _seedActivity();
    }
  }

  final Duration latency;
  final Catalog _catalog = Catalog.instance;

  final Map<String, Student> _students = {};
  final Map<String, List<TranscriptEntry>> _transcripts = {};
  final Map<String, FinanceSummary> _finance = {};
  final Map<String, CourseSection> _sections = {};
  final Map<String, Enrollment> _enrollments = {};
  final List<_WaitItem> _waitlist = [];
  final Map<String, ExtraRequest> _requests = {};
  final List<Notice> _notices = [];
  final Map<String, Set<String>> _readNotices = {};
  final List<Faq> _faqs = [];
  final List<AppNotification> _notifications = [];
  final List<AuditLog> _audit = [];
  AdvisingWindows _windows = AdvisingWindows(
    regularOpen: true,
    extraOpen: true,
    opensAt: DateTime(2026, 10, 20, 9),
    closesAt: DateTime(2026, 11, 5, 23, 59),
  );
  int _seq = 0;

  Future<void> _delay() => Future.delayed(latency);
  DateTime get _now => DateTime.now();
  String _nextId(String prefix) => '$prefix${++_seq}';

  // ---------------------------------------------------------------------
  // Seed data
  // ---------------------------------------------------------------------

  void _seedSections(bool simulateSeats) {
    for (final s in _catalog.offerSections()) {
      _sections[s.id] = simulateSeats
          ? s.copyWith(parts: [
              for (final p in s.parts) p.copyWith(enrolled: _simulatedSeats(s, p)),
            ])
          : s;
    }
  }

  /// Seats taken by students outside the demo, so the counts look real.
  /// Semester 10 Section 1 is full to show the waitlist.
  int _simulatedSeats(CourseSection s, SectionPart p) {
    if (s.semesterNo == 10 && s.groupNo == 1 && s.courseCode != 'CSE 466') {
      return p.capacity;
    }
    if (s.semesterNo == 10 && s.groupNo == 4 && s.courseCode == 'CSE 459') {
      return p.capacity - 2;
    }
    final hash = '${s.id}-${p.sectionNo}'.codeUnits.fold<int>(17, (h, c) => (h * 31 + c) & 0xffffff);
    return (p.capacity * (0.3 + (hash % 55) / 100)).floor();
  }

  static String _term(int termsBack) {
    const seasons = ['Spring', 'Summer', 'Fall'];
    final index = 2026 * 3 + 2 - termsBack;
    return '${seasons[index % 3]} ${index ~/ 3}';
  }

  static const List<(String, double)> _grades = [
    ('A+', 4.0), ('A', 3.75), ('A-', 3.5), ('B+', 3.25), ('B', 3.0), ('B-', 2.75), ('C+', 2.5),
  ];

  /// Registers a dummy student with transcript and finance. Public so tests
  /// can add their own students.
  void addDemoStudent(DemoStudent d) {
    final index = _students.length;
    final transcript = <TranscriptEntry>[];
    final seen = <String>{};
    for (var sem = 1; sem < d.semesterNo; sem++) {
      for (final c in _catalog.coursesOf(sem)) {
        if (!seen.add(c.code)) continue;
        final hash = '${d.id}${c.code}'.codeUnits.fold<int>(3, (h, u) => (h * 17 + u) & 0xffff);
        final grade = d.failed.contains(c.code) ? ('F', 0.0) : _grades[hash % _grades.length];
        transcript.add(TranscriptEntry(
          courseCode: c.code,
          title: c.title,
          credits: c.credits,
          semesterNo: sem,
          term: _term(d.semesterNo - sem),
          grade: grade.$1,
          gradePoint: grade.$2,
        ));
      }
    }
    final attempted = transcript.fold<double>(0, (s, t) => s + t.credits);
    final points = transcript.fold<double>(0, (s, t) => s + t.credits * t.gradePoint);
    final passedCredits =
        transcript.where((t) => t.passed).fold<double>(0, (s, t) => s + t.credits);

    final payments = <Payment>[];
    if (d.paid > 0) {
      final first = d.paid > 20000 ? (d.paid * 0.6).roundToDouble() : d.paid;
      payments.add(Payment(
        date: DateTime(2026, 9, 28 - index),
        amount: first,
        type: index.isEven ? 'E-payment' : 'Bank deposit',
        txnId: 'EP26${d.id.substring(5)}A',
        verifiedBy: 'Accounts Office',
      ));
      if (first < d.paid) {
        payments.add(Payment(
          date: DateTime(2026, 10, 14 + index % 5),
          amount: d.paid - first,
          type: 'E-payment',
          txnId: 'EP26${d.id.substring(5)}B',
          verifiedBy: 'Accounts Office',
        ));
      }
    }
    final finance = FinanceSummary(
      semesterFee: d.semesterFee,
      waiver: d.waiver,
      previousDues: d.previousDues,
      paid: d.paid,
      requiredAmount: d.requiredAmount,
      payments: payments,
    );
    final (status, type) = ClearanceRules.evaluate(
      dues: finance.dues,
      specialConsideration: d.specialConsideration,
      paid: d.paid,
      requiredAmount: d.requiredAmount,
    );
    final pick = index % kDemoFathers.length;
    _transcripts[d.id] = transcript;
    _finance[d.id] = finance;
    _students[d.id] = Student(
      id: d.id,
      name: d.name,
      semesterNo: d.semesterNo,
      batch: _term(d.semesterNo - 1),
      dept: 'CSE',
      cgpa: attempted == 0 ? 0 : double.parse((points / attempted).toStringAsFixed(2)),
      creditsDone: passedCredits,
      clearanceStatus: status,
      clearanceType: type,
      specialConsideration: d.specialConsideration,
      requiredAmount: d.requiredAmount,
      paidAmount: d.paid,
      dues: finance.dues,
      phone: '0181${d.id.substring(2)}',
      email: '${d.id}@eastdelta.edu.bd',
      dob: '${10 + index} ${['Jan', 'Mar', 'May', 'Jul', 'Sep', 'Nov'][index % 6]} ${2005 - d.semesterNo ~/ 3}',
      bloodGroup: kBloodGroups[index % kBloodGroups.length],
      presentAddress: 'House ${12 + index * 3}, Road ${index + 2}, ${kDemoAreas[pick]}',
      permanentAddress: 'Village Road ${index + 1}, ${kDemoHomeTowns[pick]}',
      fatherName: kDemoFathers[pick],
      motherName: kDemoMothers[pick],
      emergencyContact: '${kDemoFathers[pick]} (Father), 0171${d.id.substring(2)}',
    );
  }

  void _seedActivity() {
    final now = _now;
    const day = Duration(days: 1);

    // Tanvir is already enrolled in three courses of Semester 10 Section 2.
    final tanvir = _students['233000002']!;
    for (final code in ['CSE 443', 'CSE 463', 'CSE 439']) {
      _commit(tanvir, _sections[CourseSection.makeId(code, 10, 2)]!,
          EnrollmentType.regular, '233000002', now.subtract(day));
    }
    _log(_staffUser('233000002'), AuditAction.enroll, '233000002',
        'Enrolled in CSE 443.2, CSE 463.2, CSE 439.2', at: now.subtract(day));

    // Rumana waits for a seat in the full CSE 443.1.
    _waitlist.add(_WaitItem(_nextId('W'), '233000012',
        CourseSection.makeId('CSE 443', 10, 1), now.subtract(const Duration(hours: 5))));

    void request(String student, String code, int sem, int group, RequestReason reason,
        String comment, Duration ago,
        {RequestStatus status = RequestStatus.pending, String? by, String? reply}) {
      final s = _sections[CourseSection.makeId(code, sem, group)]!;
      final st = _students[student]!;
      final r = ExtraRequest(
        id: ExtraRequest.makeId(student, code, RequestKind.add),
        studentId: student,
        studentName: st.name,
        sectionId: s.id,
        sectionLabel: s.label,
        courseCode: code,
        title: s.title,
        semesterNo: sem,
        kind: RequestKind.add,
        reason: reason,
        comment: comment,
        status: status,
        createdAt: now.subtract(ago),
        decidedBy: by,
        facultyComment: reply,
        decidedAt: by == null ? null : now.subtract(ago ~/ 2),
      );
      _requests[r.id] = r;
    }

    request('233000007', 'CSE 225', 5, 6, RequestReason.gradeImprovement,
        'Got C+ last time, want to improve CGPA.', const Duration(hours: 20));
    request('233000011', 'CSE 459', 10, 3, RequestReason.requiredForGraduation,
        'Need this course to graduate next semester.', const Duration(hours: 30));
    request('233000006', 'CSE 215', 5, 2, RequestReason.gradeImprovement, '',
        const Duration(hours: 9));
    request('233000008', 'CSE 211', 3, 1, RequestReason.retake,
        'Retaking for a better grade.', const Duration(days: 2),
        status: RequestStatus.rejected,
        by: 'MRA',
        reply: 'Section 1 is reserved for Semester 3 students. Try Section 4.');

    for (final n in kNotices) {
      _notices.add(Notice(
        id: _nextId('N'),
        title: n.$1,
        body: n.$2,
        category: n.$3,
        pinned: n.$4,
        createdAt: now.subtract(Duration(days: n.$5, hours: 3)),
      ));
    }
    for (final f in kFaq) {
      _faqs.add(Faq(
        id: _nextId('F'),
        question: f.$1,
        answer: f.$2,
        category: f.$3,
        keywords: f.$4,
      ));
    }

    _notify('233000002', 'Advising confirmed',
        'You are enrolled in CSE 443.2, CSE 463.2 and CSE 439.2.', at: now.subtract(day));
    _notify('233000012', 'Joined waitlist',
        'You are #1 on the waitlist for CSE 443.1.',
        at: now.subtract(const Duration(hours: 5)));
    _notify('233000008', 'Extra course request rejected',
        'CSE 211.1: Section 1 is reserved for Semester 3 students. Try Section 4.',
        at: now.subtract(day));
    _notify('TRINA', 'New extra course request',
        'Arif Hossain (233000007) requested CSE 225.6.',
        at: now.subtract(const Duration(hours: 20)));

    final admin = _staffUser('admin');
    _log(admin, AuditAction.windowChange, 'settings/windows',
        'Regular advising window opened', at: now.subtract(const Duration(days: 5)));
    _log(admin, AuditAction.windowChange, 'settings/windows',
        'Extra course window opened', at: now.subtract(const Duration(days: 2)));
    _log(admin, AuditAction.clearanceSpecial, '233000003',
        'Special consideration granted', at: now.subtract(const Duration(days: 4)));
    _log(_staffUser('MRA'), AuditAction.requestRejected, '233000008_CSE211_ADD',
        'Rejected CSE 211.1 for 233000008', at: now.subtract(day));
  }

  /// Minimal user for seeded log lines.
  AppUser _staffUser(String id) {
    if (id == 'admin') {
      return const AppUser(id: 'admin', role: UserRole.admin, name: 'Administrator');
    }
    if (_students.containsKey(id)) {
      return AppUser(id: id, role: UserRole.student, name: _students[id]!.name);
    }
    return AppUser(id: id, role: UserRole.instructor, name: id, shortName: id);
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  Student _base(String id) {
    final s = _students[id];
    if (s == null) throw ApiException('No student found with ID $id.');
    return s;
  }

  /// Student with the derived lock/advising flags filled in.
  Student _view(String id) {
    final s = _base(id);
    final group = _lockedGroup(s);
    return s.copyWith(lockedGroup: () => group, advisingDone: group != null);
  }

  int? _lockedGroup(Student s) {
    for (final e in _enrollments.values) {
      if (e.studentId == s.id &&
          e.isActive &&
          e.type == EnrollmentType.regular &&
          e.semesterNo == s.semesterNo) {
        return e.groupNo;
      }
    }
    return null;
  }

  CourseSection _section(String id) {
    final s = _sections[id];
    if (s == null) throw const ApiException('That section no longer exists.');
    return s;
  }

  List<Enrollment> _active(String studentId) => _enrollments.values
      .where((e) => e.studentId == studentId && e.isActive)
      .toList();

  Set<String> _passed(String studentId) => {
        for (final t in _transcripts[studentId] ?? const <TranscriptEntry>[])
          if (t.passed) t.courseCode,
      };

  bool _owns(AppUser actor, CourseSection s) {
    if (actor.isDean) return true;
    final short = actor.shortName;
    if (short == null) return false;
    return s.parts.any((p) => _catalog.teaches(short, s.courseCode, p.sectionNo));
  }

  /// Faculty to notify about a section, plus the Dean.
  Set<String> _ownersOf(CourseSection s) {
    final ids = <String>{AppConfig.deanShortForm};
    for (final p in s.parts) {
      for (final short in _catalog.facultyFor(s.courseCode, p.sectionNo)) {
        final f = _catalog.facultyByShort(short);
        if (f != null) ids.add(f.shortForm);
      }
    }
    return ids;
  }

  void _notify(String userId, String title, String body, {DateTime? at}) {
    _notifications.add(AppNotification(
      id: _nextId('A'),
      userId: userId,
      title: title,
      body: body,
      createdAt: at ?? _now,
    ));
  }

  void _log(AppUser actor, AuditAction action, String target, String details,
      {bool bypassed = false, DateTime? at}) {
    _audit.add(AuditLog(
      id: _nextId('L'),
      actorId: actor.id,
      actorRole: actor.roleLabel,
      action: action,
      targetId: target,
      details: details,
      bypassedClearance: bypassed,
      timestamp: at ?? _now,
    ));
  }

  /// Takes one seat and writes the enrolment. No checks: callers validate.
  Enrollment _commit(Student student, CourseSection section, EnrollmentType type,
      String by, DateTime at) {
    final part = section.nextPart!;
    _sections[section.id] = section.copyWith(parts: [
      for (final p in section.parts)
        p.sectionNo == part.sectionNo ? p.copyWith(enrolled: p.enrolled + 1) : p,
    ]);
    final enrollment = Enrollment(
      id: Enrollment.makeId(student.id, section.id),
      studentId: student.id,
      sectionId: section.id,
      courseCode: section.courseCode,
      title: section.title,
      credits: section.credits,
      semesterNo: section.semesterNo,
      groupNo: section.groupNo,
      sectionNo: part.sectionNo,
      type: type,
      status: EnrollmentStatus.enrolled,
      createdAt: at,
      byUser: by,
    );
    _enrollments[enrollment.id] = enrollment;
    _waitlist.removeWhere((w) => w.studentId == student.id && w.sectionId == section.id);
    return enrollment;
  }

  /// Runs prerequisite -> seat -> clashes for all [sections], then enrols in
  /// all of them, or throws and changes nothing. Class-time and exam-day
  /// clashes throw a [ConflictException] unless [acceptConflicts] is true.
  List<Enrollment> _validateAndCommit(
    Student student,
    List<CourseSection> sections, {
    required String by,
    required bool checkLock,
    bool acceptConflicts = false,
  }) {
    if (sections.isEmpty) throw const ApiException('Select at least one course.');
    final active = _active(student.id);

    EnrollmentType typeOf(CourseSection s) =>
        s.semesterNo == student.semesterNo ? EnrollmentType.regular : EnrollmentType.extra;

    // Section lock (regular courses only).
    if (checkLock) {
      final groups = {
        for (final s in sections)
          if (typeOf(s) == EnrollmentType.regular) s.groupNo,
      };
      if (groups.length > 1) {
        throw const ApiException('Pick courses from one section only.');
      }
      final locked = _lockedGroup(student);
      if (groups.isNotEmpty && locked != null && groups.first != locked) {
        throw ApiException('Locked to Section $locked: other sections are view-only.');
      }
    }

    // Already taken.
    final taken = {for (final e in active) e.courseCode};
    final picked = <String>{};
    for (final s in sections) {
      if (taken.contains(s.courseCode)) {
        throw ApiException('${s.courseCode} is already in the course list.');
      }
      if (!picked.add(s.courseCode)) {
        throw ApiException('${s.courseCode} was selected twice.');
      }
    }

    // Prerequisites.
    final passed = _passed(student.id);
    for (final s in sections) {
      final missing = AdvisingRules.missingPrerequisites(s.courseCode, passed);
      if (missing.isNotEmpty) {
        throw ApiException('${s.label}: prerequisite ${missing.join(', ')} not passed.');
      }
    }

    // Seats.
    for (final s in sections) {
      if (_section(s.id).isFull) {
        throw ApiException('${s.label} is full. Join the waitlist for the next free seat.');
      }
    }

    // Clashes only warn. The user can accept them and enrol anyway.
    if (!acceptConflicts) {
      final conflicts = _conflictsOf(active, sections);
      if (conflicts.isNotEmpty) throw ConflictException(conflicts);
    }

    final at = _now;
    return [
      for (final s in sections) _commit(student, _section(s.id), typeOf(s), by, at),
    ];
  }

  /// Class-time and exam-day clashes of [sections] with the courses already
  /// taken and with each other.
  List<String> _conflictsOf(List<Enrollment> active, List<CourseSection> sections) {
    final existingSlots = <String, List<ClassSlot>>{
      for (final e in active) e.label: _catalog.slotsFor(e.courseCode, e.sectionNo),
    };
    final addSlots = <String, List<ClassSlot>>{
      for (final s in sections)
        Formatters.sectionLabel(s.courseCode, (s.nextPart ?? s.parts.first).sectionNo):
            _catalog.slotsFor(s.courseCode, (s.nextPart ?? s.parts.first).sectionNo),
    };
    final existingExams = <String, int>{
      for (final e in active)
        if (_catalog.examDay(e.courseCode, e.semesterNo) case final day?) e.courseCode: day,
    };
    final addExams = <String, int>{
      for (final s in sections)
        if (_catalog.examDay(s.courseCode, s.semesterNo) case final day?) s.courseCode: day,
    };
    return [
      ...AdvisingRules.timeClashes(existingSlots, addSlots),
      ...AdvisingRules.examClashes(existingExams, addExams),
    ];
  }

  void _dropSeat(Enrollment e, String by) {
    _enrollments[e.id] = e.dropped(by, _now);
    final section = _sections[e.sectionId];
    if (section == null) return;
    _sections[section.id] = section.copyWith(parts: [
      for (final p in section.parts)
        p.sectionNo == e.sectionNo
            ? p.copyWith(enrolled: (p.enrolled - 1).clamp(0, p.capacity))
            : p,
    ]);
    _promoteWaitlist(section.id);
  }

  /// Gives free seats to the waitlist in server-time order.
  void _promoteWaitlist(String sectionId) {
    final queue = _waitlist.where((w) => w.sectionId == sectionId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final w in queue) {
      final section = _sections[sectionId];
      if (section == null || section.isFull) return;
      _waitlist.remove(w);
      final student = _base(w.studentId);
      try {
        // The student chose this course when joining the waitlist (and saw any
        // clash warning then), so a clash must not cost them the seat.
        _validateAndCommit(student, [section],
            by: 'waitlist', checkLock: true, acceptConflicts: true);
        _log(_staffUser(student.id), AuditAction.waitlistPromote, student.id,
            'Promoted from waitlist into ${section.label}');
        _notify(student.id, 'You got a seat!',
            'A seat freed up in ${section.label} ${section.title}. You are now enrolled.');
      } on ApiException catch (e) {
        _notify(student.id, 'Waitlist update',
            'A seat freed up in ${section.label}, but you could not be enrolled: ${e.message}');
      }
    }
  }

  // ---------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------

  @override
  Future<AppUser> login(String username, String password, UserRole role) async {
    await _delay();
    final id = username.trim();
    if (id.isEmpty) throw const ApiException('Enter your username.');
    if (password.isEmpty) throw const ApiException('Enter your password.');
    switch (role) {
      case UserRole.student:
        final s = _students[id];
        if (s == null) throw ApiException('No student account found for "$id".');
        return AppUser(id: s.id, role: UserRole.student, name: s.name);
      case UserRole.instructor:
        final f = _catalog.facultyByShort(id);
        if (f == null) {
          throw ApiException('No instructor account found for "$id". '
              'Use your short form, e.g. TRINA.');
        }
        return AppUser(
          id: f.shortForm,
          role: UserRole.instructor,
          name: f.name,
          shortName: f.shortForm,
          isDean: Catalog.facultyKey(f.shortForm) ==
              Catalog.facultyKey(AppConfig.deanShortForm),
        );
      case UserRole.admin:
        if (id.toLowerCase() != 'admin') {
          throw ApiException('No administrator account found for "$id".');
        }
        return const AppUser(id: 'admin', role: UserRole.admin, name: 'Administrator');
    }
  }

  // ---------------------------------------------------------------------
  // Students
  // ---------------------------------------------------------------------

  @override
  Future<Student> fetchStudent(String studentId) async {
    await _delay();
    return _view(studentId.trim());
  }

  @override
  Future<List<Student>> fetchStudents() async {
    await _delay();
    return [for (final id in _students.keys) _view(id)];
  }

  @override
  Future<Student> updateContact(
    String studentId, {
    required String phone,
    required String email,
    required String presentAddress,
    required String emergencyContact,
  }) async {
    await _delay();
    _students[studentId] = _base(studentId).copyWith(
      phone: phone,
      email: email,
      presentAddress: presentAddress,
      emergencyContact: emergencyContact,
    );
    return _view(studentId);
  }

  @override
  Future<List<TranscriptEntry>> fetchTranscript(String studentId) async {
    await _delay();
    return List.of(_transcripts[studentId] ?? const []);
  }

  @override
  Future<FinanceSummary> fetchFinance(String studentId) async {
    await _delay();
    final f = _finance[studentId];
    if (f == null) throw ApiException('No account found for $studentId.');
    return f;
  }

  // ---------------------------------------------------------------------
  // Sections & seats
  // ---------------------------------------------------------------------

  @override
  Future<List<CourseSection>> fetchSections({int? semesterNo}) async {
    await _delay();
    return _sections.values
        .where((s) => semesterNo == null || s.semesterNo == semesterNo)
        .toList();
  }

  @override
  Future<CourseSection> changeSeats(AppUser actor, String sectionId, int capacity) async {
    await _delay();
    final s = _section(sectionId);
    if (!actor.isStaff) throw const ApiException('Only faculty or the Dean can change seats.');
    if (!_owns(actor, s)) {
      throw ApiException('${s.label} is not your course. Only the Dean can change it.');
    }
    final main = s.parts.first;
    final room = _catalog.roomCapacity(s.courseCode, main.sectionNo);
    if (capacity < main.enrolled) {
      throw ApiException('Cannot go below the current enrolment (${main.enrolled}).');
    }
    if (capacity > room) {
      throw ApiException('Cannot go above the room capacity ($room).');
    }
    final before = main.capacity;
    _sections[s.id] = s.copyWith(parts: [
      main.copyWith(capacity: capacity),
      ...s.parts.skip(1),
    ]);
    _log(actor, AuditAction.seatChange, s.id, '${s.label}: $before -> $capacity seats');
    _promoteWaitlist(s.id);
    return _sections[s.id]!;
  }

  // ---------------------------------------------------------------------
  // Enrolment
  // ---------------------------------------------------------------------

  @override
  Future<List<Enrollment>> fetchEnrollments(String studentId) async {
    await _delay();
    return _active(studentId)..sort((a, b) => a.courseCode.compareTo(b.courseCode));
  }

  @override
  Future<List<Enrollment>> fetchSectionEnrollments(String sectionId) async {
    await _delay();
    return _enrollments.values.where((e) => e.sectionId == sectionId && e.isActive).toList();
  }

  @override
  Future<List<Enrollment>> enrollSelected(String studentId, List<String> sectionIds,
      {bool acceptConflicts = false}) async {
    await _delay();
    final student = _base(studentId);
    if (!student.clearanceStatus.canAdvise) {
      throw const ApiException('Advising is locked: your accounts clearance is Not cleared.');
    }
    if (!_windows.regularOpen) {
      throw const ApiException('The regular advising window is closed.');
    }
    final sections = sectionIds.map(_section).toList();
    if (sections.any((s) => s.semesterNo != student.semesterNo)) {
      throw ApiException('Regular advising is for Semester ${student.semesterNo} only. '
          'Use the Extra course tab for other semesters.');
    }
    final result = _validateAndCommit(student, sections,
        by: studentId, checkLock: true, acceptConflicts: acceptConflicts);
    _log(_staffUser(studentId), AuditAction.enroll, studentId,
        'Enrolled in ${result.map((e) => e.label).join(', ')}');
    return result;
  }

  @override
  Future<List<Enrollment>> staffAdvise(
      AppUser actor, String studentId, List<String> sectionIds,
      {bool acceptConflicts = false}) async {
    await _delay();
    if (!actor.isStaff) throw const ApiException('Only faculty or the Dean can do this.');
    final student = _base(studentId);
    final bypass = !student.clearanceStatus.canAdvise;
    if (bypass && !actor.isDean) {
      throw const ApiException(
          'This student is Not cleared. Only the Dean can advise without clearance.');
    }
    final sections = sectionIds.map(_section).toList();
    // Staff follow the windows too: regular courses need the regular window,
    // other-semester (extra) courses need the extra window.
    for (final s in sections) {
      final extra = s.semesterNo != student.semesterNo;
      if (extra ? !_windows.extraOpen : !_windows.regularOpen) {
        throw ApiException(extra
            ? 'The extra course window is closed.'
            : 'The regular advising window is closed.');
      }
    }
    for (final s in sections) {
      if (!_owns(actor, s)) {
        throw ApiException('${s.label} is not your course. You can only add your own courses.');
      }
    }
    final result = _validateAndCommit(student, sections,
        by: actor.id, checkLock: true, acceptConflicts: acceptConflicts);
    if (bypass) {
      _log(actor, AuditAction.deanBypass, studentId,
          'Advised without clearance (${student.clearanceStatus.label})',
          bypassed: true);
    }
    for (final e in result) {
      _log(actor, AuditAction.addByFaculty, studentId,
          'Added ${e.label} (${e.type.label})',
          bypassed: bypass);
    }
    _notify(studentId, 'Courses added',
        '${actor.name} added ${result.map((e) => e.label).join(', ')} to your courses.');
    return result;
  }

  @override
  Future<void> staffDrop(AppUser actor, String enrollmentId) async {
    await _delay();
    final e = _enrollments[enrollmentId];
    if (e == null || !e.isActive) throw const ApiException('That course is no longer enrolled.');
    if (!actor.isStaff) {
      throw const ApiException('Students cannot drop courses. Ask your faculty or the Dean.');
    }
    if (!_owns(actor, _section(e.sectionId))) {
      throw ApiException('${e.label} is not your course. Only the Dean can drop it.');
    }
    _dropSeat(e, actor.id);
    _log(actor, AuditAction.dropByFaculty, e.studentId, 'Dropped ${e.label} (${e.type.label})');
    _notify(e.studentId, 'Course dropped', '${actor.name} dropped ${e.label} ${e.title}.');
  }

  // ---------------------------------------------------------------------
  // Waitlist
  // ---------------------------------------------------------------------

  WaitlistEntry _entry(_WaitItem w) {
    final s = _sections[w.sectionId];
    final queue = _waitlist.where((x) => x.sectionId == w.sectionId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return WaitlistEntry(
      id: w.id,
      studentId: w.studentId,
      sectionId: w.sectionId,
      sectionLabel: s?.label ?? w.sectionId,
      title: s?.title ?? '',
      createdAt: w.createdAt,
      position: queue.indexOf(w) + 1,
    );
  }

  @override
  Future<List<WaitlistEntry>> fetchWaitlist(String studentId) async {
    await _delay();
    return [for (final w in _waitlist.where((w) => w.studentId == studentId)) _entry(w)];
  }

  @override
  Future<List<WaitlistEntry>> fetchSectionWaitlist(String sectionId) async {
    await _delay();
    return [for (final w in _waitlist.where((w) => w.sectionId == sectionId)) _entry(w)]
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  @override
  Future<WaitlistEntry> joinWaitlist(String studentId, String sectionId,
      {bool acceptConflicts = false}) async {
    await _delay();
    final student = _base(studentId);
    final s = _section(sectionId);
    if (!student.clearanceStatus.canAdvise) {
      throw const ApiException('Advising is locked: your accounts clearance is Not cleared.');
    }
    if (!_windows.regularOpen) throw const ApiException('The regular advising window is closed.');
    if (s.semesterNo != student.semesterNo) {
      throw const ApiException('The waitlist is for courses of your own semester.');
    }
    if (!s.isFull) throw ApiException('${s.label} still has seats. Enroll instead.');
    if (_active(studentId).any((e) => e.courseCode == s.courseCode)) {
      throw ApiException('${s.courseCode} is already in your courses.');
    }
    final locked = _lockedGroup(student);
    if (locked != null && locked != s.groupNo) {
      throw ApiException('Locked to Section $locked: other sections are view-only.');
    }
    if (_waitlist.any((w) => w.studentId == studentId && w.sectionId == sectionId)) {
      throw ApiException('You are already on the waitlist for ${s.label}.');
    }
    if (!acceptConflicts) {
      final conflicts = _conflictsOf(_active(studentId), [s]);
      if (conflicts.isNotEmpty) throw ConflictException(conflicts);
    }
    final item = _WaitItem(_nextId('W'), studentId, sectionId, _now);
    _waitlist.add(item);
    _log(_staffUser(studentId), AuditAction.waitlistJoin, studentId, 'Joined waitlist of ${s.label}');
    return _entry(item);
  }

  @override
  Future<void> leaveWaitlist(String entryId) async {
    await _delay();
    _waitlist.removeWhere((w) => w.id == entryId);
  }

  // ---------------------------------------------------------------------
  // Extra course requests
  // ---------------------------------------------------------------------

  List<ExtraRequest> _sorted(Iterable<ExtraRequest> items) => items.toList()
    ..sort((a, b) {
      if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });

  @override
  Future<List<ExtraRequest>> fetchMyRequests(String studentId) async {
    await _delay();
    return _sorted(_requests.values.where((r) => r.studentId == studentId));
  }

  @override
  Future<List<ExtraRequest>> fetchRequestsFor(AppUser staff) async {
    await _delay();
    return _sorted(_requests.values.where((r) {
      final s = _sections[r.sectionId];
      return s != null && _owns(staff, s);
    }));
  }

  @override
  Future<ExtraRequest> createExtraRequest({
    required String studentId,
    required String sectionId,
    required RequestKind kind,
    required RequestReason reason,
    String comment = '',
    bool acceptConflicts = false,
  }) async {
    await _delay();
    final student = _base(studentId);
    final s = _section(sectionId);
    if (!_windows.extraOpen) throw const ApiException('The extra course window is closed.');
    if (!student.clearanceStatus.canAdvise) {
      throw const ApiException('Your accounts clearance is Not cleared.');
    }
    final id = ExtraRequest.makeId(studentId, s.courseCode, kind);
    final existing = _requests[id];
    if (existing != null && existing.status.blocksNewRequest) {
      throw ApiException('You already sent a ${kind.label.toLowerCase()} request for '
          '${s.courseCode} (${existing.status.label}).');
    }
    final enrolled = _active(studentId).where((e) => e.courseCode == s.courseCode);
    if (kind == RequestKind.add) {
      if (s.semesterNo == student.semesterNo) {
        throw const ApiException('Use regular advising for courses of your own semester.');
      }
      if (enrolled.isNotEmpty) throw ApiException('${s.courseCode} is already in your courses.');
      if (s.isFull) throw ApiException('${s.label} has no vacant seat.');
      if (!acceptConflicts) {
        final conflicts = _conflictsOf(_active(studentId), [s]);
        if (conflicts.isNotEmpty) throw ConflictException(conflicts);
      }
    } else if (!enrolled.any((e) => e.type == EnrollmentType.extra)) {
      throw const ApiException('You can only request to drop an extra course.');
    }
    final request = ExtraRequest(
      id: id,
      studentId: studentId,
      studentName: student.name,
      sectionId: s.id,
      sectionLabel: s.label,
      courseCode: s.courseCode,
      title: s.title,
      semesterNo: s.semesterNo,
      kind: kind,
      reason: reason,
      comment: comment.trim(),
      status: RequestStatus.pending,
      createdAt: _now,
    );
    _requests[id] = request;
    _log(_staffUser(studentId), AuditAction.requestCreated, id,
        '${kind.label} request for ${s.label} (${reason.label})');
    for (final owner in _ownersOf(s)) {
      _notify(owner, 'New extra course request',
          '${student.name} ($studentId) requested to ${kind.label.toLowerCase()} ${s.label}.');
    }
    return request;
  }

  @override
  Future<ExtraRequest> withdrawExtraRequest(String requestId) async {
    await _delay();
    final r = _requests[requestId];
    if (r == null) throw const ApiException('Request not found.');
    if (!r.isPending) {
      throw ApiException('Only pending requests can be withdrawn (this one is ${r.status.label}).');
    }
    final updated = r.copyWith(status: RequestStatus.withdrawn, decidedAt: _now);
    _requests[requestId] = updated;
    _log(_staffUser(r.studentId), AuditAction.requestWithdrawn, requestId,
        'Withdrew ${r.kind.label.toLowerCase()} request for ${r.sectionLabel}');
    return updated;
  }

  @override
  Future<ExtraRequest> decideExtraRequest(
      AppUser actor, String requestId, bool approve, String comment) async {
    await _delay();
    final r = _requests[requestId];
    if (r == null) throw const ApiException('Request not found.');
    if (!r.isPending) throw ApiException('This request is already ${r.status.label}.');
    final s = _section(r.sectionId);
    if (!_owns(actor, s)) throw ApiException('${s.label} is not your course.');
    // Rejecting is always possible; approving needs the extra course window.
    if (approve && !_windows.extraOpen) {
      throw const ApiException('The extra course window is closed. You can still reject.');
    }

    var status = RequestStatus.rejected;
    if (approve) {
      if (r.kind == RequestKind.add) {
        // The student accepted any clash when sending the request.
        _validateAndCommit(_base(r.studentId), [s],
            by: actor.id, checkLock: false, acceptConflicts: true);
        status = RequestStatus.enrolled;
      } else {
        final e = _active(r.studentId).where((e) => e.courseCode == r.courseCode);
        if (e.isNotEmpty) _dropSeat(e.first, actor.id);
        status = RequestStatus.approved;
      }
    }
    final updated = r.copyWith(
      status: status,
      decidedBy: actor.name,
      facultyComment: comment.trim().isEmpty ? null : comment.trim(),
      decidedAt: _now,
    );
    _requests[requestId] = updated;
    _log(actor, approve ? AuditAction.requestApproved : AuditAction.requestRejected, requestId,
        '${approve ? 'Approved' : 'Rejected'} ${r.kind.label.toLowerCase()} ${r.sectionLabel} '
        'for ${r.studentId}');
    _notify(
      r.studentId,
      'Extra course request ${approve ? 'approved' : 'rejected'}',
      '${r.sectionLabel} (${r.kind.label}): ${status.label}'
          '${updated.facultyComment == null ? '' : ' - ${updated.facultyComment}'}',
    );
    return updated;
  }

  // ---------------------------------------------------------------------
  // Administrator
  // ---------------------------------------------------------------------

  void _requireAdmin(AppUser actor) {
    if (!actor.isAdmin) throw const ApiException('Only the Administrator can do this.');
  }

  @override
  Future<Student> setClearance(AppUser actor, String studentId, ClearanceAction action) async {
    await _delay();
    _requireAdmin(actor);
    final s = _base(studentId);
    final (status, logAction) = switch (action) {
      ClearanceAction.give => (ClearanceStatus.cleared, AuditAction.clearanceGiven),
      ClearanceAction.revoke => (ClearanceStatus.notCleared, AuditAction.clearanceRevoked),
      ClearanceAction.special => (ClearanceStatus.special, AuditAction.clearanceSpecial),
    };
    _students[studentId] = s.copyWith(
      clearanceStatus: status,
      clearanceType: ClearanceType.adminOverride,
      specialConsideration: action == ClearanceAction.special ? true : null,
    );
    _log(actor, logAction, studentId, '${s.clearanceStatus.label} -> ${status.label}');
    _notify(studentId, 'Accounts clearance updated',
        'Your clearance is now: ${status.label}. ${status.remark}');
    return _view(studentId);
  }

  @override
  Future<AdvisingWindows> fetchWindows() async {
    await _delay();
    return _windows;
  }

  @override
  Future<AdvisingWindows> updateWindows(AppUser actor, AdvisingWindows windows) async {
    await _delay();
    _requireAdmin(actor);
    final changes = <String>[
      if (windows.regularOpen != _windows.regularOpen)
        'Regular advising ${windows.regularOpen ? 'opened' : 'closed'}',
      if (windows.extraOpen != _windows.extraOpen)
        'Extra course window ${windows.extraOpen ? 'opened' : 'closed'}',
      if (windows.opensAt != _windows.opensAt || windows.closesAt != _windows.closesAt)
        'Dates changed',
    ];
    _windows = windows;
    if (changes.isNotEmpty) {
      _log(actor, AuditAction.windowChange, 'settings/windows', changes.join('; '));
    }
    return _windows;
  }

  @override
  Future<void> saveCourse(
    AppUser actor, {
    required String code,
    required String title,
    required double credits,
    required int semesterNo,
    required bool isNew,
    int capacity = 30,
  }) async {
    await _delay();
    _requireAdmin(actor);
    final normalized = code.trim().toUpperCase().replaceAllMapped(
        RegExp(r'^([A-Z]+)\s*(\d+)$'), (m) => '${m[1]} ${m[2]}');
    if (!RegExp(r'^[A-Z]{2,5} \d{3}$').hasMatch(normalized)) {
      throw const ApiException('Course code must look like "CSE 499".');
    }
    if (title.trim().isEmpty) throw const ApiException('Enter a course title.');
    if (credits <= 0 || credits > 6) throw const ApiException('Credits must be between 0.5 and 6.');
    final existing =
        _sections.values.where((s) => s.semesterNo == semesterNo && s.courseCode == normalized);
    if (isNew) {
      if (existing.isNotEmpty) {
        throw ApiException('$normalized already exists in Semester $semesterNo.');
      }
      if (capacity < 1) throw const ApiException('Capacity must be at least 1.');
      final groups = _groupNumbers(semesterNo);
      for (final g in groups.isEmpty ? [1] : groups) {
        final s = CourseSection(
          id: CourseSection.makeId(normalized, semesterNo, g),
          courseCode: normalized,
          title: title.trim(),
          credits: credits,
          semesterNo: semesterNo,
          groupNo: g,
          parts: [SectionPart(sectionNo: g, capacity: capacity, enrolled: 0)],
        );
        _sections[s.id] = s;
      }
      _log(actor, AuditAction.courseChange, normalized,
          'Added $normalized to Semester $semesterNo');
    } else {
      for (final s in existing.toList()) {
        _sections[s.id] = s.copyWith(title: title.trim(), credits: credits);
      }
      _log(actor, AuditAction.courseChange, normalized, 'Updated $normalized: $title, $credits cr');
    }
  }

  List<int> _groupNumbers(int semesterNo) =>
      ({for (final s in _sections.values) if (s.semesterNo == semesterNo) s.groupNo}.toList()
        ..sort());

  @override
  Future<void> deleteCourse(AppUser actor, String code, int semesterNo) async {
    await _delay();
    _requireAdmin(actor);
    final ids = _sections.values
        .where((s) => s.semesterNo == semesterNo && s.courseCode == code)
        .map((s) => s.id)
        .toSet();
    if (_enrollments.values.any((e) => e.isActive && ids.contains(e.sectionId))) {
      throw ApiException('$code has enrolled students. Drop them first.');
    }
    _sections.removeWhere((id, _) => ids.contains(id));
    _waitlist.removeWhere((w) => ids.contains(w.sectionId));
    _log(actor, AuditAction.courseChange, code, 'Deleted $code from Semester $semesterNo');
  }

  @override
  Future<void> addSectionGroup(AppUser actor, int semesterNo, int capacity) async {
    await _delay();
    _requireAdmin(actor);
    if (capacity < 1) throw const ApiException('Capacity must be at least 1.');
    final groups = _groupNumbers(semesterNo);
    final next = (groups.isEmpty ? 0 : groups.last) + 1;
    final codes = <String, CourseSection>{
      for (final s in _sections.values)
        if (s.semesterNo == semesterNo) s.courseCode: s,
    };
    if (codes.isEmpty) throw const ApiException('Add a course to this semester first.');
    for (final template in codes.values) {
      final s = CourseSection(
        id: CourseSection.makeId(template.courseCode, semesterNo, next),
        courseCode: template.courseCode,
        title: template.title,
        credits: template.credits,
        semesterNo: semesterNo,
        groupNo: next,
        parts: [SectionPart(sectionNo: next, capacity: capacity, enrolled: 0)],
      );
      _sections[s.id] = s;
    }
    _log(actor, AuditAction.courseChange, 'semester-$semesterNo',
        'Opened Section $next in Semester $semesterNo ($capacity seats per course)');
  }

  @override
  Future<void> deleteSectionGroup(AppUser actor, int semesterNo, int groupNo) async {
    await _delay();
    _requireAdmin(actor);
    final ids = _sections.values
        .where((s) => s.semesterNo == semesterNo && s.groupNo == groupNo)
        .map((s) => s.id)
        .toSet();
    if (_enrollments.values.any((e) => e.isActive && ids.contains(e.sectionId))) {
      throw ApiException('Section $groupNo has enrolled students. Drop them first.');
    }
    _sections.removeWhere((id, _) => ids.contains(id));
    _waitlist.removeWhere((w) => ids.contains(w.sectionId));
    _log(actor, AuditAction.courseChange, 'semester-$semesterNo',
        'Closed Section $groupNo of Semester $semesterNo');
  }

  @override
  Future<List<AuditLog>> fetchAuditLogs() async {
    await _delay();
    return _audit.reversed.toList();
  }

  // ---------------------------------------------------------------------
  // Notices, FAQ, notifications
  // ---------------------------------------------------------------------

  @override
  Future<List<Notice>> fetchNotices() async {
    await _delay();
    return _notices.toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  @override
  Future<Notice> saveNotice(AppUser actor, Notice notice) async {
    await _delay();
    _requireAdmin(actor);
    if (notice.title.trim().isEmpty || notice.body.trim().isEmpty) {
      throw const ApiException('A notice needs a title and a message.');
    }
    final index = _notices.indexWhere((n) => n.id == notice.id);
    final saved = Notice(
      id: index < 0 ? _nextId('N') : notice.id,
      title: notice.title.trim(),
      body: notice.body.trim(),
      category: notice.category,
      pinned: notice.pinned,
      createdAt: index < 0 ? _now : notice.createdAt,
      createdBy: actor.id,
    );
    if (index < 0) {
      _notices.add(saved);
    } else {
      _notices[index] = saved;
    }
    _log(actor, AuditAction.noticeChange, saved.id,
        '${index < 0 ? 'Posted' : 'Edited'} notice "${saved.title}"');
    return saved;
  }

  @override
  Future<void> deleteNotice(AppUser actor, String noticeId) async {
    await _delay();
    _requireAdmin(actor);
    _notices.removeWhere((n) => n.id == noticeId);
    _log(actor, AuditAction.noticeChange, noticeId, 'Deleted notice');
  }

  @override
  Future<Set<String>> fetchReadNoticeIds(String userId) async {
    await _delay();
    return Set.of(_readNotices[userId] ?? const {});
  }

  @override
  Future<void> markNoticeRead(String userId, String noticeId) async {
    _readNotices.putIfAbsent(userId, () => {}).add(noticeId);
  }

  @override
  Future<List<Faq>> fetchFaqs() async {
    await _delay();
    return List.of(_faqs);
  }

  @override
  Future<Faq> saveFaq(AppUser actor, Faq faq) async {
    await _delay();
    _requireAdmin(actor);
    if (faq.question.trim().isEmpty || faq.answer.trim().isEmpty) {
      throw const ApiException('An FAQ needs a question and an answer.');
    }
    final index = _faqs.indexWhere((f) => f.id == faq.id);
    final saved = Faq(
      id: index < 0 ? _nextId('F') : faq.id,
      question: faq.question.trim(),
      answer: faq.answer.trim(),
      category: faq.category,
      keywords: faq.keywords,
    );
    if (index < 0) {
      _faqs.add(saved);
    } else {
      _faqs[index] = saved;
    }
    _log(actor, AuditAction.faqChange, saved.id,
        '${index < 0 ? 'Added' : 'Edited'} FAQ "${saved.question}"');
    return saved;
  }

  @override
  Future<void> deleteFaq(AppUser actor, String faqId) async {
    await _delay();
    _requireAdmin(actor);
    _faqs.removeWhere((f) => f.id == faqId);
    _log(actor, AuditAction.faqChange, faqId, 'Deleted FAQ');
  }

  @override
  Future<List<AppNotification>> fetchNotifications(String userId) async {
    await _delay();
    return _notifications.where((n) => n.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> markNotificationsRead(String userId) async {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == userId) _notifications[i] = _notifications[i].markRead();
    }
  }
}
