import '../models/class_slot.dart';
import '../utils/formatters.dart';
import 'catalog.dart';

class AdvisingRules {
  AdvisingRules._();

  static List<String> missingPrerequisites(String courseCode, Set<String> passed) => Catalog
      .instance
      .prerequisitesOf(courseCode)
      .where((p) => !passed.contains(p))
      .toList();

  static List<String> timeClashes(
    Map<String, List<ClassSlot>> existing,
    Map<String, List<ClassSlot>> adding,
  ) {
    final result = <String>[];
    final checked = <String, List<ClassSlot>>{...existing};
    for (final entry in adding.entries) {
      for (final other in checked.entries) {
        final hit = _firstOverlap(entry.value, other.value);
        if (hit != null) {
          result.add('Class time: ${entry.key} and ${other.key} both meet on '
              '${hit.day} ${Formatters.routineTime(hit.time)}.');
        }
      }
      checked[entry.key] = entry.value;
    }
    return result;
  }

  static ClassSlot? _firstOverlap(List<ClassSlot> a, List<ClassSlot> b) {
    for (final x in a) {
      for (final y in b) {
        if (x.overlaps(y)) return x;
      }
    }
    return null;
  }

  static String? clashError(
    Map<String, List<ClassSlot>> existing,
    Map<String, List<ClassSlot>> adding,
  ) =>
      timeClashes(existing, adding).firstOrNull;

  static List<String> examClashes(Map<String, int> existing, Map<String, int> adding) {
    final result = <String>[];
    final checked = <String, int>{...existing};
    for (final entry in adding.entries) {
      for (final other in checked.entries) {
        if (entry.value == other.value) {
          result.add('Exam day: ${entry.key} and ${other.key} are both on Day ${entry.value}.');
        }
      }
      checked[entry.key] = entry.value;
    }
    return result;
  }
}
