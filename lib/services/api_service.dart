import '../models/app_user.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/extra_request.dart';
import '../models/portal.dart';
import '../models/student.dart';

/// Thrown by an [ApiService] with a message that is safe to show to the user.
class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Class-time or exam-day clashes. Nothing was saved. The caller shows
/// [conflicts] as an alert and, if the user agrees, repeats the same call with
/// `acceptConflicts: true`. Clashes are a warning, never a block.
class ConflictException extends ApiException {
  const ConflictException(this.conflicts)
      : super('Some of these courses clash with each other.');
  final List<String> conflicts;
}

enum ClearanceAction { give, revoke, special }

/// Everything the screens need from the backend.
///
/// The app runs on [MockApiService] (in-memory). For the backend phase, write
/// a Firebase implementation of this class and pass it to `EduAdvisingApp`
/// in main.dart. Providers and screens do not change. Calls that change data
/// take the acting [AppUser] so the backend can check permissions and write
/// the audit log.
abstract class ApiService {
  // Auth
  Future<AppUser> login(String username, String password, UserRole role);

  // Students
  Future<Student> fetchStudent(String studentId);
  Future<List<Student>> fetchStudents();
  Future<Student> updateContact(
    String studentId, {
    required String phone,
    required String email,
    required String presentAddress,
    required String emergencyContact,
  });
  Future<List<TranscriptEntry>> fetchTranscript(String studentId);
  Future<FinanceSummary> fetchFinance(String studentId);

  // Sections & seats
  Future<List<CourseSection>> fetchSections({int? semesterNo});
  Future<CourseSection> changeSeats(AppUser actor, String sectionId, int capacity);

  // Enrolment
  Future<List<Enrollment>> fetchEnrollments(String studentId);
  Future<List<Enrollment>> fetchSectionEnrollments(String sectionId);

  /// Student self-advising. One all-or-nothing transaction. Throws a
  /// [ConflictException] on a class-time or exam-day clash unless
  /// [acceptConflicts] is true.
  Future<List<Enrollment>> enrollSelected(String studentId, List<String> sectionIds,
      {bool acceptConflicts = false});

  /// Faculty (own courses) or Dean (any course, clearance bypass logged).
  Future<List<Enrollment>> staffAdvise(
      AppUser actor, String studentId, List<String> sectionIds,
      {bool acceptConflicts = false});
  Future<void> staffDrop(AppUser actor, String enrollmentId);

  // Waitlist
  Future<List<WaitlistEntry>> fetchWaitlist(String studentId);
  Future<List<WaitlistEntry>> fetchSectionWaitlist(String sectionId);
  Future<WaitlistEntry> joinWaitlist(String studentId, String sectionId,
      {bool acceptConflicts = false});
  Future<void> leaveWaitlist(String entryId);

  // Extra course requests
  Future<List<ExtraRequest>> fetchMyRequests(String studentId);
  Future<List<ExtraRequest>> fetchRequestsFor(AppUser staff);
  Future<ExtraRequest> createExtraRequest({
    required String studentId,
    required String sectionId,
    required RequestKind kind,
    required RequestReason reason,
    String comment = '',
    bool acceptConflicts = false,
  });
  Future<ExtraRequest> withdrawExtraRequest(String requestId);
  Future<ExtraRequest> decideExtraRequest(
      AppUser actor, String requestId, bool approve, String comment);

  // Administrator
  Future<Student> setClearance(AppUser actor, String studentId, ClearanceAction action);
  Future<AdvisingWindows> fetchWindows();
  Future<AdvisingWindows> updateWindows(AppUser actor, AdvisingWindows windows);
  Future<void> saveCourse(
    AppUser actor, {
    required String code,
    required String title,
    required double credits,
    required int semesterNo,
    required bool isNew,
    int capacity = 30,
  });
  Future<void> deleteCourse(AppUser actor, String code, int semesterNo);
  Future<void> addSectionGroup(AppUser actor, int semesterNo, int capacity);
  Future<void> deleteSectionGroup(AppUser actor, int semesterNo, int groupNo);
  Future<List<AuditLog>> fetchAuditLogs();

  // Notices, FAQ, notifications
  Future<List<Notice>> fetchNotices();
  Future<Notice> saveNotice(AppUser actor, Notice notice);
  Future<void> deleteNotice(AppUser actor, String noticeId);
  Future<Set<String>> fetchReadNoticeIds(String userId);
  Future<void> markNoticeRead(String userId, String noticeId);
  Future<List<Faq>> fetchFaqs();
  Future<Faq> saveFaq(AppUser actor, Faq faq);
  Future<void> deleteFaq(AppUser actor, String faqId);
  Future<List<AppNotification>> fetchNotifications(String userId);
  Future<void> markNotificationsRead(String userId);
}
