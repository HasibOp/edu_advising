import '../data/exam_data.dart';
import '../data/faculty_data.dart';
import '../data/misc_data.dart';
import '../data/offer_data.dart';
import '../data/routine_data.dart';
import '../models/class_slot.dart';
import '../models/course.dart';
import '../utils/app_config.dart';

class Faculty {
  const Faculty({required this.name, required this.shortForm});

  final String name;

  final String shortForm;

  String get email => 'Not provided';
  String get phone => 'Not provided';
  String get position => 'Not provided';
  String get department => 'Not provided';

  String get initials {
    final words = name
        .replaceAll(RegExp(r'^(Dr|Mr|Ms|Mrs)\.\s*'), '')
        .split(RegExp(r'[\s.]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    return (words.first[0] + (words.length > 1 ? words.last[0] : '')).toUpperCase();
  }
}

class Catalog {
  Catalog._() {
    for (final row in kRoutine) {
      final slot = _parseRow(row);
      _slots.add(slot);
      if (slot.sectionNo != null && !slot.isEee) {
        _bySection.putIfAbsent(slot.label, () => []).add(slot);
      }
    }
    for (final entry in kOffer.entries) {
      for (final c in entry.value.c) {
        final course = Course(code: c.$1, title: c.$2, credits: c.$3, semesterNo: entry.key);
        _bySemester.putIfAbsent(entry.key, () => []).add(course);
        _byCode.putIfAbsent(c.$1, () => course);
      }
    }
    for (final f in kFaculty) {
      final faculty = Faculty(name: f.$1, shortForm: f.$2);
      _faculty.add(faculty);
      _facultyByKey[facultyKey(f.$2)] = faculty;
    }
  }

  static final Catalog instance = Catalog._();

  final List<ClassSlot> _slots = [];
  final Map<String, List<ClassSlot>> _bySection = {};
  final Map<int, List<Course>> _bySemester = {};
  final Map<String, Course> _byCode = {};
  final List<Faculty> _faculty = [];
  final Map<String, Faculty> _facultyByKey = {};

  static final RegExp _courseRe = RegExp(r'^([A-Z]+ \d+)(?:\.(\d+))?( \(EEE\))?$');

  static ClassSlot _parseRow(RoutineRow row) {
    final m = _courseRe.firstMatch(row.$5)!;
    final (start, end) = ClassSlot.parseTime(row.$3);
    return ClassSlot(
      day: row.$1,
      isLab: row.$2 == 'L',
      time: row.$3,
      startMinute: start,
      endMinute: end,
      room: row.$4,
      courseCode: m.group(1)!,
      sectionNo: m.group(2) == null ? null : int.parse(m.group(2)!),
      faculty: row.$6,
      isEee: m.group(3) != null,
    );
  }

  static String facultyKey(String shortForm) =>
      shortForm.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  List<String> get days => kDays;
  List<ClassSlot> get allSlots => _slots;
  List<Faculty> get faculty => _faculty;
  int get semesterCount => kOffer.length;
  List<int> get semesters => kOffer.keys.toList()..sort();

  int groupCount(int semesterNo) => kOffer[semesterNo]?.n ?? 0;

  List<Course> coursesOf(int semesterNo) => _bySemester[semesterNo] ?? const [];
  Course? course(String code) => _byCode[code];
  String titleOf(String code) => _byCode[code]?.title ?? code;

  List<ClassSlot> slotsFor(String courseCode, int sectionNo) =>
      _bySection['$courseCode.$sectionNo'] ?? const [];

  List<String> facultyFor(String courseCode, int sectionNo) {
    final shorts = <String>[];
    for (final s in slotsFor(courseCode, sectionNo)) {
      if (s.faculty.isNotEmpty && !shorts.contains(s.faculty)) shorts.add(s.faculty);
    }
    return shorts;
  }

  bool teaches(String shortForm, String courseCode, int sectionNo) {
    final key = facultyKey(shortForm);
    return facultyFor(courseCode, sectionNo).any((f) => facultyKey(f) == key);
  }

  Faculty? facultyByShort(String shortForm) => _facultyByKey[facultyKey(shortForm)];

  String facultyName(String shortForm) => facultyByShort(shortForm)?.name ?? shortForm;

  List<(String, int)> sectionsTaughtBy(String shortForm) {
    final key = facultyKey(shortForm);
    final result = <(String, int)>[];
    for (final s in _slots) {
      if (s.isEee || s.sectionNo == null || facultyKey(s.faculty) != key) continue;
      final item = (s.courseCode, s.sectionNo!);
      if (!result.contains(item)) result.add(item);
    }
    return result;
  }

  List<String> prerequisitesOf(String courseCode) => kPrereq[courseCode] ?? const [];

  List<(int, String)> examsOf(int semesterNo) => kExam[semesterNo] ?? const [];

  int? examDay(String courseCode, int semesterNo) {
    for (final (day, code) in examsOf(semesterNo)) {
      if (code == courseCode) return day;
    }
    return null;
  }

  int roomCapacity(String courseCode, int sectionNo) {
    final slots = slotsFor(courseCode, sectionNo);
    if (slots.isEmpty) return AppConfig.theoryRoomCapacity;
    return slots.any((s) => !s.isLab) ? AppConfig.theoryRoomCapacity : AppConfig.labRoomCapacity;
  }

  List<CourseSection> offerSections() {
    final result = <CourseSection>[];
    for (final sem in semesters) {
      final offer = kOffer[sem]!;
      for (final c in offer.c) {
        final groups = offer.s[c.$1] ?? const [];
        for (var g = 0; g < groups.length; g++) {
          if (groups[g].isEmpty) continue;
          result.add(CourseSection(
            id: CourseSection.makeId(c.$1, sem, g + 1),
            courseCode: c.$1,
            title: c.$2,
            credits: c.$3,
            semesterNo: sem,
            groupNo: g + 1,
            parts: [
              for (final p in groups[g])
                SectionPart(sectionNo: p.$1, capacity: p.$2, enrolled: 0),
            ],
          ));
        }
      }
    }
    return result;
  }
}
