import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// "CSE 443" + 3 -> "CSE 443.3". The number after the dot is the section.
  static String sectionLabel(String courseCode, int sectionNo) => '$courseCode.$sectionNo';

  /// 3.0 -> "3", 1.5 -> "1.5".
  static String credits(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  static String money(double value) => 'Tk ${NumberFormat('#,##0').format(value)}';

  static String date(DateTime value) => DateFormat('d MMM yyyy').format(value);

  static String dateTime(DateTime value) => DateFormat('d MMM yyyy, h:mm a').format(value);

  static String timeAgo(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return date(value);
  }

  /// Routine time "11.30-1.00" -> "11:30 - 1:00".
  static String routineTime(String time) => time.replaceAll('.', ':').replaceAll('-', ' - ');

  /// 600 -> "10:00".
  static String clock(int minute) {
    var hour = minute ~/ 60;
    if (hour > 12) hour -= 12;
    return '$hour:${(minute % 60).toString().padLeft(2, '0')}';
  }

  static String ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}
