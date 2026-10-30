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

  final String time;

  final int startMinute;
  final int endMinute;
  final String room;
  final String courseCode;

  final int? sectionNo;
  final String faculty;

  final bool isEee;

  String get label => sectionNo == null ? courseCode : '$courseCode.$sectionNo';

  bool overlaps(ClassSlot other) =>
      day == other.day &&
      startMinute < other.endMinute &&
      other.startMinute < endMinute;

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
