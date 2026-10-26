import '../models/class_slot.dart';
import '../utils/formatters.dart';
import 'catalog.dart';

/// Pure advising checks, shared by the mock backend and the screens.
///
/// Validation order when enrolling:
/// clearance -> window -> section lock -> prerequisite -> seat, then clashes.
/// Clashes (class time, exam day) only warn: the user may still go ahead.
/// There is no credit limit.
class AdvisingRules {
  AdvisingRules._();

  /// Prerequisites of [courseCode] that are not in [passed].
  static List<String> missingPrerequisites(String courseCode, Set<String> passed) => Catalog
      .instance
      .prerequisitesOf(courseCode)
      .where((p) => !passed.contains(p))
      .toList();

  /// Every class-time clash between a section being added and anything else
  /// taken, one message per pair of sections.
  ///
  /// Both maps go from a section label ("CSE 443.3") to its weekly slots.
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

  /// First class-time clash, or null.
  static String? clashError(
    Map<String, List<ClassSlot>> existing,
    Map<String, List<ClassSlot>> adding,
  ) =>
      timeClashes(existing, adding).firstOrNull;

  /// Courses whose final exam falls on the same day. Both maps go from a
  /// course code to its exam day (1-8); courses without an exam are left out.
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
