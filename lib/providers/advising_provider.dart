import 'package:flutter/foundation.dart';

import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/extra_request.dart';
import '../models/portal.dart';
import '../models/student.dart';
import '../services/advising_rules.dart';
import '../services/api_service.dart';

/// Everything the signed-in student sees: clearance, sections of their
/// semester, enrolments, waitlist and extra course requests.
class AdvisingProvider extends ChangeNotifier {
  AdvisingProvider(this._api);

  final ApiService _api;

  String? _studentId;
  Student? _student;
  AdvisingWindows? _windows;
  List<CourseSection> _sections = [];
  List<Enrollment> _enrollments = [];
  List<WaitlistEntry> _waitlist = [];
  List<ExtraRequest> _requests = [];
  Set<String> _passed = {};
  bool _isLoading = false;
  bool _isBusy = false;
  String? _error;

  /// Course sections ticked on the open section screen.
  final Set<String> _selected = {};
  int? _selectedGroup;

  Student? get student => _student;
  AdvisingWindows? get windows => _windows;
  List<CourseSection> get sections => _sections;
  List<Enrollment> get enrollments => _enrollments;
  List<WaitlistEntry> get waitlist => _waitlist;
  List<ExtraRequest> get requests => _requests;
  bool get isLoading => _isLoading;

  /// True while a confirm / request call is running.
  bool get isBusy => _isBusy;
  String? get error => _error;
  bool get hasData => _student != null;

  bool get regularOpen => _windows?.regularOpen ?? false;
  bool get extraOpen => _windows?.extraOpen ?? false;
  bool get canAdvise => (_student?.clearanceStatus.canAdvise ?? false) && regularOpen;

  List<SectionGroup> get groups =>
      _student == null ? const [] : SectionGroup.fromSections(_student!.semesterNo, _sections);

  int? get lockedGroup => _student?.lockedGroup;
  bool isViewOnly(int groupNo) => lockedGroup != null && lockedGroup != groupNo;

  double get credits => _enrollments.fold(0, (sum, e) => sum + e.credits);
  List<Enrollment> get regular =>
      _enrollments.where((e) => e.type == EnrollmentType.regular).toList();
  List<Enrollment> get extra => _enrollments.where((e) => e.type == EnrollmentType.extra).toList();

  Enrollment? enrollmentForCourse(String courseCode) {
    for (final e in _enrollments) {
      if (e.courseCode == courseCode) return e;
    }
    return null;
  }

  WaitlistEntry? waitlistFor(String sectionId) {
    for (final w in _waitlist) {
      if (w.sectionId == sectionId) return w;
    }
    return null;
  }

  /// The live (not withdrawn) request for a course, if any.
  ExtraRequest? requestFor(String courseCode, RequestKind kind) {
    for (final r in _requests) {
      if (r.courseCode == courseCode && r.kind == kind && r.status.blocksNewRequest) return r;
    }
    return null;
  }

  List<String> missingPrerequisites(String courseCode) =>
      AdvisingRules.missingPrerequisites(courseCode, _passed);

  Future<void> load(String studentId) async {
    _studentId = studentId;
    _isLoading = !hasData;
    _error = null;
    notifyListeners();
    try {
      final student = await _api.fetchStudent(studentId);
      final results = await Future.wait([
        _api.fetchWindows(),
        _api.fetchSections(semesterNo: student.semesterNo),
        _api.fetchEnrollments(studentId),
        _api.fetchWaitlist(studentId),
        _api.fetchMyRequests(studentId),
        _api.fetchTranscript(studentId),
      ]);
      _student = student;
      _windows = results[0] as AdvisingWindows;
      _sections = results[1] as List<CourseSection>;
      _enrollments = results[2] as List<Enrollment>;
      _waitlist = results[3] as List<WaitlistEntry>;
      _requests = results[4] as List<ExtraRequest>;
      _passed = {
        for (final t in results[5] as List<TranscriptEntry>)
          if (t.passed) t.courseCode,
      };
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_studentId != null) await load(_studentId!);
  }

  // Selection --------------------------------------------------------------

  Set<String> get selected => _selected;
  bool isSelected(String sectionId) => _selected.contains(sectionId);

  double get selectedCredits => _sections
      .where((s) => _selected.contains(s.id))
      .fold(0, (sum, s) => sum + s.credits);

  /// Starts a fresh selection when another section group is opened.
  void openGroup(int groupNo) {
    if (_selectedGroup != groupNo) {
      _selected.clear();
      _selectedGroup = groupNo;
    }
  }

  bool canSelect(CourseSection s) =>
      canAdvise &&
      !s.isFull &&
      !isViewOnly(s.groupNo) &&
      enrollmentForCourse(s.courseCode) == null;

  void toggle(CourseSection s) {
    if (!canSelect(s)) return;
    if (!_selected.remove(s.id)) _selected.add(s.id);
    notifyListeners();
  }

  /// Ticks every course of the group that still has a seat.
  void selectAll(SectionGroup group) {
    for (final s in group.sections) {
      if (canSelect(s)) _selected.add(s.id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  // Actions (each throws ApiException with a message for the user) --------

  Future<T> _busy<T>(Future<T> Function() action) async {
    _isBusy = true;
    notifyListeners();
    try {
      final result = await action();
      await refresh();
      return result;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<List<Enrollment>> confirmSelection() async {
    final ids = _selected.toList();
    final result = await _busy(() => _api.enrollSelected(_studentId!, ids));
    _selected.clear();
    notifyListeners();
    return result;
  }

  Future<WaitlistEntry> joinWaitlist(String sectionId) =>
      _busy(() => _api.joinWaitlist(_studentId!, sectionId));

  Future<void> leaveWaitlist(String entryId) => _busy(() => _api.leaveWaitlist(entryId));

  Future<ExtraRequest> sendRequest({
    required String sectionId,
    required RequestKind kind,
    required RequestReason reason,
    String comment = '',
  }) =>
      _busy(() => _api.createExtraRequest(
            studentId: _studentId!,
            sectionId: sectionId,
            kind: kind,
            reason: reason,
            comment: comment,
          ));

  Future<ExtraRequest> withdrawRequest(String requestId) =>
      _busy(() => _api.withdrawExtraRequest(requestId));

  Future<void> updateContact({
    required String phone,
    required String email,
    required String presentAddress,
    required String emergencyContact,
  }) =>
      _busy(() => _api.updateContact(
            _studentId!,
            phone: phone,
            email: email,
            presentAddress: presentAddress,
            emergencyContact: emergencyContact,
          ));

  Future<void> updatePhoto(Uint8List? bytes) =>
      _busy(() => _api.updatePhoto(_studentId!, bytes));

  void clear() {
    _studentId = null;
    _student = null;
    _windows = null;
    _sections = [];
    _enrollments = [];
    _waitlist = [];
    _requests = [];
    _passed = {};
    _selected.clear();
    _selectedGroup = null;
    _error = null;
    notifyListeners();
  }
}
