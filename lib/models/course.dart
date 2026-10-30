import '../utils/formatters.dart';

class Course {
  const Course({
    required this.code,
    required this.title,
    required this.credits,
    required this.semesterNo,
  });

  final String code;
  final String title;
  final double credits;
  final int semesterNo;

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        code: json['code'] as String,
        title: json['title'] as String,
        credits: (json['credits'] as num).toDouble(),
        semesterNo: json['semesterNo'] as int,
      );

  Map<String, dynamic> toJson() =>
      {'code': code, 'title': title, 'credits': credits, 'semesterNo': semesterNo};
}

enum SeatLevel { open, low, full }

class SectionPart {
  const SectionPart({
    required this.sectionNo,
    required this.capacity,
    required this.enrolled,
  });

  final int sectionNo;
  final int capacity;
  final int enrolled;

  int get seatsLeft => capacity - enrolled;
  bool get hasSeat => enrolled < capacity;

  SectionPart copyWith({int? capacity, int? enrolled}) => SectionPart(
        sectionNo: sectionNo,
        capacity: capacity ?? this.capacity,
        enrolled: enrolled ?? this.enrolled,
      );

  Map<String, dynamic> toJson() =>
      {'sectionNo': sectionNo, 'capacity': capacity, 'enrolled': enrolled};

  factory SectionPart.fromJson(Map<String, dynamic> json) => SectionPart(
        sectionNo: json['sectionNo'] as int,
        capacity: json['capacity'] as int,
        enrolled: json['enrolled'] as int,
      );
}

class CourseSection {
  const CourseSection({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.credits,
    required this.semesterNo,
    required this.groupNo,
    required this.parts,
  });

  final String id;
  final String courseCode;
  final String title;
  final double credits;
  final int semesterNo;

  final int groupNo;
  final List<SectionPart> parts;

  static String makeId(String courseCode, int semesterNo, int groupNo) =>
      '${courseCode.replaceAll(' ', '')}-$semesterNo-$groupNo';

  int get capacity => parts.fold(0, (sum, p) => sum + p.capacity);
  int get enrolled => parts.fold(0, (sum, p) => sum + p.enrolled);
  int get seatsLeft => capacity - enrolled;
  bool get isFull => seatsLeft <= 0;

  SeatLevel get seatLevel {
    if (isFull) return SeatLevel.full;
    if (seatsLeft <= 5) return SeatLevel.low;
    return SeatLevel.open;
  }

  int get sectionNo => parts.first.sectionNo;

  String get label => Formatters.sectionLabel(courseCode, sectionNo);

  String get fullLabel => parts.length == 1
      ? label
      : '$label + ${parts.skip(1).map((p) => '.${p.sectionNo}').join(' + ')}';

  SectionPart? get nextPart {
    for (final p in parts) {
      if (p.hasSeat) return p;
    }
    return null;
  }

  CourseSection copyWith({String? title, double? credits, List<SectionPart>? parts}) {
    return CourseSection(
      id: id,
      courseCode: courseCode,
      title: title ?? this.title,
      credits: credits ?? this.credits,
      semesterNo: semesterNo,
      groupNo: groupNo,
      parts: parts ?? this.parts,
    );
  }

  factory CourseSection.fromJson(Map<String, dynamic> json) => CourseSection(
        id: json['id'] as String,
        courseCode: json['courseCode'] as String,
        title: json['title'] as String,
        credits: (json['credits'] as num).toDouble(),
        semesterNo: json['semesterNo'] as int,
        groupNo: json['groupNo'] as int,
        parts: (json['parts'] as List)
            .map((p) => SectionPart.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseCode': courseCode,
        'title': title,
        'credits': credits,
        'semesterNo': semesterNo,
        'groupNo': groupNo,
        'parts': parts.map((p) => p.toJson()).toList(),
      };
}

class SectionGroup {
  const SectionGroup({
    required this.semesterNo,
    required this.groupNo,
    required this.sections,
  });

  final int semesterNo;
  final int groupNo;
  final List<CourseSection> sections;

  String get name => 'Section $groupNo';

  CourseSection? get bottleneck {
    if (sections.isEmpty) return null;
    return sections.reduce((a, b) => a.seatsLeft <= b.seatsLeft ? a : b);
  }

  int get fullCourses => sections.where((s) => s.isFull).length;
  double get totalCredits => sections.fold(0, (sum, s) => sum + s.credits);

  static List<SectionGroup> fromSections(int semesterNo, List<CourseSection> sections) {
    final byGroup = <int, List<CourseSection>>{};
    for (final s in sections.where((s) => s.semesterNo == semesterNo)) {
      byGroup.putIfAbsent(s.groupNo, () => []).add(s);
    }
    final groups = byGroup.keys.toList()..sort();
    return [
      for (final g in groups)
        SectionGroup(semesterNo: semesterNo, groupNo: g, sections: byGroup[g]!),
    ];
  }
}
