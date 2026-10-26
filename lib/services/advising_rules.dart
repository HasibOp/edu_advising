import '../models/class_slot.dart';
import '../utils/app_config.dart';
import '../utils/formatters.dart';
import 'catalog.dart';

/// Pure advising checks, shared by the mock backend and the screens.
///
/// Validation order when enrolling (plan section 5):
/// clearance -> window -> section lock -> prerequisite -> credit limit ->
/// time clash -> seat.
class AdvisingRules {
  AdvisingRules._();

  /// Prerequisites of [courseCode] that are not in [passed].
  static List<String> missingPrerequisites(String courseCode, Set<String> passed) => Catalog
      .instance
      .prerequisitesOf(courseCode)
      .where((p) => !passed.contains(p))
      .toList();

  static String? creditLimitError(double current, double adding) {
    final total = current + adding;
    if (total <= AppConfig.maxCredits) return null;
    return 'Credit limit exceeded: ${Formatters.credits(current)} + '
        '${Formatters.credits(adding)} = ${Formatters.credits(total)} credits '
        '(maximum ${Formatters.credits(AppConfig.maxCredits)}).';
  }

  /// First clash between a section being added and anything else taken.
  ///
  /// Both maps go from a section label ("CSE 443.3") to its weekly slots.
  static String? clashError(
    Map<String, List<ClassSlot>> existing,
    Map<String, List<ClassSlot>> adding,
  ) {
    final checked = <String, List<ClassSlot>>{...existing};
    for (final entry in adding.entries) {
      for (final other in checked.entries) {
        for (final a in entry.value) {
          for (final b in other.value) {
            if (a.overlaps(b)) {
              return 'Time clash: ${entry.key} and ${other.key} both meet on '
                  '${a.day} ${Formatters.routineTime(a.time)}.';
            }
          }
        }
      }
      checked[entry.key] = entry.value;
    }
    return null;
  }
}
