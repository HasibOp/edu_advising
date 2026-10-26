import '../utils/formatters.dart';

enum EnrollmentType {
  regular('Regular'),
  extra('Extra');

  const EnrollmentType(this.label);
  final String label;
}

enum EnrollmentStatus { enrolled, dropped }

/// A student's seat in one course section.
///
/// The ID is "{studentId}_{sectionId}" so a retry or a double tap can never
/// enroll the same student twice.
class Enrollment {
  const Enrollment({
    required this.id,
    required this.studentId,
    required this.sectionId,
    required this.courseCode,
    required this.title,
    required this.credits,
    required this.semesterNo,
    required this.groupNo,
    required this.sectionNo,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.byUser,
    this.droppedBy,
    this.droppedAt,
  });

  static String makeId(String studentId, String sectionId) => '${studentId}_$sectionId';

  final String id;
  final String studentId;
  final String sectionId;
  final String courseCode;
  final String title;
  final double credits;
  final int semesterNo;
  final int groupNo;

  /// The actual section the student sits in (can be a split-lab part).
  final int sectionNo;
  final EnrollmentType type;
  final EnrollmentStatus status;
  final DateTime createdAt;

  /// Who enrolled the student (the student, a faculty or the Dean).
  final String byUser;
  final String? droppedBy;
  final DateTime? droppedAt;

  bool get isActive => status == EnrollmentStatus.enrolled;
  String get label => Formatters.sectionLabel(courseCode, sectionNo);

  Enrollment dropped(String by, DateTime at) => Enrollment(
        id: id,
        studentId: studentId,
        sectionId: sectionId,
        courseCode: courseCode,
        title: title,
        credits: credits,
        semesterNo: semesterNo,
        groupNo: groupNo,
        sectionNo: sectionNo,
        type: type,
        status: EnrollmentStatus.dropped,
        createdAt: createdAt,
        byUser: byUser,
        droppedBy: by,
        droppedAt: at,
      );

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        sectionId: json['sectionId'] as String,
        courseCode: json['courseCode'] as String,
        title: json['title'] as String,
        credits: (json['credits'] as num).toDouble(),
        semesterNo: json['semesterNo'] as int,
        groupNo: json['groupNo'] as int,
        sectionNo: json['sectionNo'] as int,
        type: EnrollmentType.values.byName(json['type'] as String),
        status: EnrollmentStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        byUser: json['byUser'] as String,
        droppedBy: json['droppedBy'] as String?,
        droppedAt: json['droppedAt'] == null
            ? null
            : DateTime.parse(json['droppedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'sectionId': sectionId,
        'courseCode': courseCode,
        'title': title,
        'credits': credits,
        'semesterNo': semesterNo,
        'groupNo': groupNo,
        'sectionNo': sectionNo,
        'type': type.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'byUser': byUser,
        'droppedBy': droppedBy,
        'droppedAt': droppedAt?.toIso8601String(),
      };
}

/// A place in the queue for a full course section.
class WaitlistEntry {
  const WaitlistEntry({
    required this.id,
    required this.studentId,
    required this.sectionId,
    required this.sectionLabel,
    required this.title,
    required this.createdAt,
    required this.position,
  });

  final String id;
  final String studentId;
  final String sectionId;
  final String sectionLabel;
  final String title;

  /// Server time of the request; it decides the order.
  final DateTime createdAt;

  /// 1 = next to get a seat.
  final int position;

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) => WaitlistEntry(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        sectionId: json['sectionId'] as String,
        sectionLabel: json['sectionLabel'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        position: json['position'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'sectionId': sectionId,
        'sectionLabel': sectionLabel,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'position': position,
      };
}
