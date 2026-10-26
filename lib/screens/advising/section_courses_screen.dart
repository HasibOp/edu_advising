import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../providers/advising_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/catalog.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';

/// The courses of one section with checkboxes, Select all and Confirm.
class SectionCoursesScreen extends StatefulWidget {
  const SectionCoursesScreen({super.key, required this.groupNo});

  final int groupNo;

  @override
  State<SectionCoursesScreen> createState() => _SectionCoursesScreenState();
}

class _SectionCoursesScreenState extends State<SectionCoursesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdvisingProvider>().openGroup(widget.groupNo);
  }

  Future<void> _confirm(AdvisingProvider a, SectionGroup group) async {
    final picked = group.sections.where((s) => a.isSelected(s.id)).toList();
    final ok = await confirmDialog(
      context,
      title: 'Enroll in ${picked.length} course(s)?',
      message: '${picked.map((s) => '${s.label}  ${s.title}').join('\n')}\n\n'
          'Total ${Formatters.credits(a.selectedCredits)} credits. After this you are locked to '
          '${group.name}, and you cannot drop regular courses yourself.',
      confirmLabel: 'Confirm',
    );
    if (!ok || !mounted) return;
    try {
      final result = await runAllowingConflicts(
          context, (accept) => a.confirmSelection(acceptConflicts: accept));
      // null: the student went back after seeing a clash. Nothing was saved.
      if (result == null || !mounted) return;
      context.read<NotificationProvider>().refresh();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
          title: const Text('Advising confirmed'),
          content: Text('You are enrolled in:\n${result.map((e) => e.label).join(', ')}'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: AppColors.danger, size: 44),
          title: const Text('Nothing was enrolled'),
          content: Text('${errorText(e)}\n\nEnrolment is all-or-nothing: fix this and try again.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdvisingProvider>();
    final student = a.student;
    if (student == null) return const Scaffold(body: LoadingView());
    final group = a.groups.where((g) => g.groupNo == widget.groupNo).firstOrNull;
    if (group == null) {
      return const Scaffold(
        appBar: EduAppBar(title: 'Section'),
        body: EmptyState(icon: Icons.event_busy, title: 'This section is no longer offered'),
      );
    }
    final viewOnly = a.isViewOnly(group.groupNo);
    final selectable = group.sections.where(a.canSelect).length;
    final selectedHere = group.sections.where((s) => a.isSelected(s.id)).length;

    return Scaffold(
      appBar: EduAppBar(
        title: 'Semester ${student.semesterNo}  |  ${group.name}',
        subtitle: viewOnly ? 'View only' : 'Tick your courses, then confirm',
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: a.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          children: [
            if (viewOnly)
              NoticeBanner(
                color: AppColors.textMuted,
                icon: Icons.lock_outline,
                title: 'View only',
                message: 'You are locked to Section ${a.lockedGroup}. You can see these courses '
                    'but cannot pick them.',
              )
            else if (!student.clearanceStatus.canAdvise)
              const NoticeBanner(
                color: AppColors.danger,
                icon: Icons.block,
                message: 'Your accounts clearance is Not cleared, so advising is locked.',
              )
            else if (!a.regularOpen)
              const NoticeBanner(
                color: AppColors.danger,
                icon: Icons.lock_clock_outlined,
                message: 'The regular advising window is closed.',
              ),
            if (viewOnly || !a.canAdvise) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${group.sections.length} courses  |  ${Formatters.credits(group.totalCredits)} credits',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
                if (selectedHere > 0)
                  TextButton(onPressed: a.clearSelection, child: const Text('Clear')),
                OutlinedButton.icon(
                  onPressed: selectable == 0 ? null : () => a.selectAll(group),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Select all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final s in group.sections)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CourseTile(section: s, viewOnly: viewOnly),
              ),
          ],
        ),
      ),
      bottomNavigationBar: viewOnly
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$selectedHere selected',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            '${Formatters.credits(a.selectedCredits)} cr  (total '
                            '${Formatters.credits(a.credits + a.selectedCredits)})',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: selectedHere == 0 || a.isBusy ? null : () => _confirm(a, group),
                      icon: a.isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.how_to_reg),
                      label: const Text('Confirm'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(130, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.section, required this.viewOnly});

  final CourseSection section;
  final bool viewOnly;

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdvisingProvider>();
    final s = section;
    final enrolled = a.enrollmentForCourse(s.courseCode);
    final enrolledHere = enrolled != null && enrolled.sectionId == s.id;
    final waiting = a.waitlistFor(s.id);
    final missing = a.missingPrerequisites(s.courseCode);
    final selected = a.isSelected(s.id);
    final slots = Catalog.instance.slotsFor(s.courseCode, s.sectionNo);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(6, 10, 14, 12),
      borderColor: selected
          ? AppColors.primary
          : enrolledHere
              ? AppColors.success
              : null,
      color: selected ? AppColors.tint : null,
      onTap: a.canSelect(s) ? () => a.toggle(s) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: enrolledHere || selected,
            activeColor: enrolledHere ? AppColors.success : AppColors.primary,
            onChanged: a.canSelect(s) ? (_) => a.toggle(s) : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(s.label,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    Text('${Formatters.credits(s.credits)} cr',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    SeatBadge(s),
                  ],
                ),
                Text(s.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (s.parts.length > 1)
                  Text('Lab split: ${s.fullLabel}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                if (slots.isEmpty)
                  const Text('Time: TBA (project course)',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted))
                else
                  for (final slot in slots)
                    Text(
                      '${slot.day.substring(0, 3)} ${Formatters.routineTime(slot.time)}  |  '
                      '${slot.isLab ? 'Lab' : 'Theory'}  |  Room ${slot.room}',
                      style: const TextStyle(fontSize: 12, color: AppColors.text),
                    ),
                if (missing.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Prerequisite not passed: ${missing.join(', ')}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 6),
                if (enrolledHere)
                  const StatusPill('ENROLLED', color: AppColors.success, icon: Icons.check)
                else if (enrolled != null)
                  StatusPill('You have ${enrolled.label}', color: AppColors.textMuted)
                else if (waiting != null)
                  Row(
                    children: [
                      StatusPill('WAITLIST #${waiting.position}',
                          color: AppColors.warning, icon: Icons.hourglass_top),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: a.isBusy
                            ? null
                            : () => runWithFeedback(context, () => a.leaveWaitlist(waiting.id),
                                success: 'Left the waitlist'),
                        child: const Text('Leave'),
                      ),
                    ],
                  )
                else if (s.isFull && !viewOnly && a.canAdvise)
                  OutlinedButton.icon(
                    onPressed: a.isBusy
                        ? null
                        : () => runWithFeedback(context, () => a.joinWaitlist(s.id),
                            success: 'Added to the waitlist for ${s.label}'),
                    icon: const Icon(Icons.playlist_add, size: 18),
                    label: const Text('Join waitlist'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
