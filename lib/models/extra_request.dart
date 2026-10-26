enum RequestKind {
  add('Add'),
  drop('Drop');

  const RequestKind(this.label);
  final String label;
}

enum RequestReason {
  retake('Retake'),
  gradeImprovement('Grade improvement'),
  requiredForGraduation('Required for graduation'),
  scheduleProblem('Schedule problem'),
  other('Other');

  const RequestReason(this.label);
  final String label;
}

enum RequestStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  enrolled('Enrolled'),
  withdrawn('Withdrawn');

  const RequestStatus(this.label);
  final String label;

  /// Withdrawn requests free the course so it can be requested again.
  bool get blocksNewRequest => this != RequestStatus.withdrawn;
}

/// A student's request to add or drop an extra (open credit) course.
///
/// ID is "{studentId}_{courseCode}_{kind}": one add and one drop request per
/// course.
class ExtraRequest {
  const ExtraRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.sectionId,
    required this.sectionLabel,
    required this.courseCode,
    required this.title,
    required this.semesterNo,
    required this.kind,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.comment = '',
    this.decidedBy,
    this.facultyComment,
    this.decidedAt,
  });

  static String makeId(String studentId, String courseCode, RequestKind kind) =>
      '${studentId}_${courseCode.replaceAll(' ', '')}_${kind.name.toUpperCase()}';

  final String id;
  final String studentId;
  final String studentName;
  final String sectionId;
  final String sectionLabel;
  final String courseCode;
  final String title;
  final int semesterNo;
  final RequestKind kind;
  final RequestReason reason;
  final String comment;
  final RequestStatus status;
  final DateTime createdAt;
  final String? decidedBy;
  final String? facultyComment;
  final DateTime? decidedAt;

  bool get isPending => status == RequestStatus.pending;

  ExtraRequest copyWith({
    RequestStatus? status,
    String? decidedBy,
    String? facultyComment,
    DateTime? decidedAt,
  }) {
    return ExtraRequest(
      id: id,
      studentId: studentId,
      studentName: studentName,
      sectionId: sectionId,
      sectionLabel: sectionLabel,
      courseCode: courseCode,
      title: title,
      semesterNo: semesterNo,
      kind: kind,
      reason: reason,
      comment: comment,
      status: status ?? this.status,
      createdAt: createdAt,
      decidedBy: decidedBy ?? this.decidedBy,
      facultyComment: facultyComment ?? this.facultyComment,
      decidedAt: decidedAt ?? this.decidedAt,
    );
  }

  factory ExtraRequest.fromJson(Map<String, dynamic> json) => ExtraRequest(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        sectionId: json['sectionId'] as String,
        sectionLabel: json['sectionLabel'] as String,
        courseCode: json['courseCode'] as String,
        title: json['title'] as String,
        semesterNo: json['semesterNo'] as int,
        kind: RequestKind.values.byName(json['kind'] as String),
        reason: RequestReason.values.byName(json['reason'] as String),
        comment: json['comment'] as String? ?? '',
        status: RequestStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        decidedBy: json['decidedBy'] as String?,
        facultyComment: json['facultyComment'] as String?,
        decidedAt: json['decidedAt'] == null
            ? null
            : DateTime.parse(json['decidedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'sectionId': sectionId,
        'sectionLabel': sectionLabel,
        'courseCode': courseCode,
        'title': title,
        'semesterNo': semesterNo,
        'kind': kind.name,
        'reason': reason.name,
        'comment': comment,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'decidedBy': decidedBy,
        'facultyComment': facultyComment,
        'decidedAt': decidedAt?.toIso8601String(),
      };
}
