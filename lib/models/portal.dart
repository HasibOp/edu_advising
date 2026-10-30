library;

class AdvisingWindows {
  const AdvisingWindows({
    required this.regularOpen,
    required this.extraOpen,
    this.semester = 'Fall 2026',
    this.opensAt,
    this.closesAt,
  });

  final bool regularOpen;
  final bool extraOpen;
  final String semester;
  final DateTime? opensAt;
  final DateTime? closesAt;

  AdvisingWindows copyWith({
    bool? regularOpen,
    bool? extraOpen,
    DateTime? opensAt,
    DateTime? closesAt,
  }) {
    return AdvisingWindows(
      regularOpen: regularOpen ?? this.regularOpen,
      extraOpen: extraOpen ?? this.extraOpen,
      semester: semester,
      opensAt: opensAt ?? this.opensAt,
      closesAt: closesAt ?? this.closesAt,
    );
  }

  factory AdvisingWindows.fromJson(Map<String, dynamic> json) => AdvisingWindows(
        regularOpen: json['regularOpen'] as bool,
        extraOpen: json['extraOpen'] as bool,
        semester: json['semester'] as String? ?? 'Fall 2026',
        opensAt: json['opensAt'] == null ? null : DateTime.parse(json['opensAt'] as String),
        closesAt: json['closesAt'] == null ? null : DateTime.parse(json['closesAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'regularOpen': regularOpen,
        'extraOpen': extraOpen,
        'semester': semester,
        'opensAt': opensAt?.toIso8601String(),
        'closesAt': closesAt?.toIso8601String(),
      };
}

class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.pinned = false,
    this.createdBy = 'admin',
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final bool pinned;
  final DateTime createdAt;
  final String createdBy;

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        category: json['category'] as String,
        pinned: json['pinned'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        createdBy: json['createdBy'] as String? ?? 'admin',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category,
        'pinned': pinned,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
      };
}

class Faq {
  const Faq({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.keywords = const [],
  });

  final String id;
  final String question;
  final String answer;
  final String category;
  final List<String> keywords;

  factory Faq.fromJson(Map<String, dynamic> json) => Faq(
        id: json['id'] as String,
        question: json['question'] as String,
        answer: json['answer'] as String,
        category: json['category'] as String,
        keywords: (json['keywords'] as List? ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'category': category,
        'keywords': keywords,
      };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  AppNotification markRead() => AppNotification(
        id: id,
        userId: userId,
        title: title,
        body: body,
        createdAt: createdAt,
        read: true,
      );
}

enum AuditAction {
  enroll('ENROLL'),
  addByFaculty('ADD_BY_FACULTY'),
  dropByFaculty('DROP_BY_FACULTY'),
  deanBypass('DEAN_BYPASS'),
  waitlistJoin('WAITLIST_JOIN'),
  waitlistPromote('WAITLIST_PROMOTE'),
  requestCreated('REQUEST_CREATED'),
  requestWithdrawn('REQUEST_WITHDRAWN'),
  requestApproved('REQUEST_APPROVED'),
  requestRejected('REQUEST_REJECTED'),
  clearanceGiven('CLEARANCE_GIVEN'),
  clearanceRevoked('CLEARANCE_REVOKED'),
  clearanceSpecial('CLEARANCE_SPECIAL'),
  windowChange('WINDOW_CHANGE'),
  seatChange('SEAT_CHANGE'),
  courseChange('COURSE_CHANGE'),
  noticeChange('NOTICE_CHANGE'),
  faqChange('FAQ_CHANGE');

  const AuditAction(this.code);
  final String code;
}

class AuditLog {
  const AuditLog({
    required this.id,
    required this.actorId,
    required this.actorRole,
    required this.action,
    required this.targetId,
    required this.details,
    required this.timestamp,
    this.bypassedClearance = false,
  });

  final String id;
  final String actorId;
  final String actorRole;
  final AuditAction action;
  final String targetId;
  final String details;
  final bool bypassedClearance;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'actorId': actorId,
        'actorRole': actorRole,
        'action': action.code,
        'targetId': targetId,
        'details': details,
        'bypassedClearance': bypassedClearance,
        'timestamp': timestamp.toIso8601String(),
      };
}

class TranscriptEntry {
  const TranscriptEntry({
    required this.courseCode,
    required this.title,
    required this.credits,
    required this.semesterNo,
    required this.term,
    required this.grade,
    required this.gradePoint,
  });

  final String courseCode;
  final String title;
  final double credits;
  final int semesterNo;

  final String term;
  final String grade;
  final double gradePoint;

  bool get passed => grade != 'F';
}

class Payment {
  const Payment({
    required this.date,
    required this.amount,
    required this.type,
    required this.txnId,
    required this.verifiedBy,
  });

  final DateTime date;
  final double amount;

  final String type;
  final String txnId;
  final String verifiedBy;
}

class FinanceSummary {
  const FinanceSummary({
    required this.semesterFee,
    required this.waiver,
    required this.previousDues,
    required this.paid,
    required this.requiredAmount,
    required this.payments,
  });

  final double semesterFee;
  final double waiver;
  final double previousDues;
  final double paid;

  final double requiredAmount;
  final List<Payment> payments;

  double get totalPayable => semesterFee - waiver + previousDues;
  double get dues => (totalPayable - paid).clamp(0, double.infinity).toDouble();
}
