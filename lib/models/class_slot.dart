/// One weekly class from the routine, e.g. CSE 443.3 on Sunday 10.00-11.30.
class ClassSlot {
  const ClassSlot({
    required this.day,
    required this.isLab,
    required this.time,
    required this.startMinute,
    required this.endMinute,
    required this.room,
    required this.courseCode,
    required this.sectionNo,
    required this.faculty,
    this.isEee = false,
  });

  final String day;
  final bool isLab;

  /// As printed in the routine, e.g. "11.30-1.00".
  final String time;

  /// Minutes after midnight, so 1.00 pm is 780.
  final int startMinute;
  final int endMinute;
  final String room;
  final String courseCode;

  /// Null for slots printed without a section (e.g. "EEE 453").
  final int? sectionNo;
  final String faculty;

  /// Slot of the EEE department, printed as "PHY 101 (EEE)".
  final bool isEee;

  String get label => sectionNo == null ? courseCode : '$courseCode.$sectionNo';

  bool overlaps(ClassSlot other) =>
      day == other.day &&
      startMinute < other.endMinute &&
      other.startMinute < endMinute;

  /// Parses "8.30-10.00" / "1.30-3.00". Hours before 8 are afternoon.
  static (int, int) parseTime(String time) {
    int toMinutes(String part) {
      final pieces = part.trim().split('.');
      var hour = int.parse(pieces[0]);
      final minute = pieces.length > 1 ? int.parse(pieces[1]) : 0;
      if (hour < 8) hour += 12;
      return hour * 60 + minute;
    }

    final pieces = time.split('-');
    return (toMinutes(pieces[0]), toMinutes(pieces[1]));
  }
}
