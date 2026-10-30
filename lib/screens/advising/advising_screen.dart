import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../providers/advising_provider.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';
import 'extra_course_tab.dart';
import 'section_courses_screen.dart';

class AdvisingScreen extends StatelessWidget {
  const AdvisingScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final advising = context.watch<AdvisingProvider>();
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: EduAppBar(
          title: 'Advising',
          subtitle: advising.student == null
              ? null
              : '${AppConfig.currentTerm}  |  Semester ${advising.student!.semesterNo}',
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Regular'),
              const Tab(text: 'Extra course'),
              Tab(text: 'Waitlist (${advising.waitlist.length})'),
            ],
          ),
        ),
        body: advising.student == null
            ? const LoadingView()
            : const TabBarView(
                children: [_RegularTab(), ExtraCourseTab(), _WaitlistTab()],
              ),
      ),
    );
  }
}

class _RegularTab extends StatelessWidget {
  const _RegularTab();

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdvisingProvider>();
    final student = a.student!;
    final groups = a.groups;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: a.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (!a.regularOpen)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: NoticeBanner(
                color: AppColors.danger,
                icon: Icons.lock_clock_outlined,
                title: 'Regular advising window is closed',
                message: 'You can look at the sections, but enrolling is off until the '
                    'Administrator opens the window.',
              ),
            ),
          if (a.lockedGroup != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NoticeBanner(
                color: AppColors.primary,
                icon: Icons.lock_person_outlined,
                title: 'Locked to Section ${a.lockedGroup}',
                message: 'You have courses in Section ${a.lockedGroup}, so the other sections are '
                    'view-only. Only faculty or the Dean can drop a regular course.',
              ),
            ),
          if (a.regular.isNotEmpty) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Enrolled: ${a.regular.length} course(s)',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Text('${Formatters.credits(a.credits)} cr',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final e in a.regular)
                        StatusPill(e.label, color: AppColors.success, icon: Icons.check),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          SectionHeader('Semester ${student.semesterNo}: choose one section',
              padding: const EdgeInsets.only(top: 12, bottom: 4)),
          const Text(
            'Open a section to see its courses. Seats are live; the number after the dot '
            'in a course code is the section (CSE 443.3 = Section 3).',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (groups.isEmpty)
            const EmptyState(icon: Icons.event_busy, title: 'No sections offered'),
          for (final g in groups)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GroupCard(group: g),
            ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final SectionGroup group;

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdvisingProvider>();
    final mine = a.lockedGroup == group.groupNo;
    final viewOnly = a.isViewOnly(group.groupNo);
    final bottleneck = group.bottleneck!;
    return AppCard(
      borderColor: mine ? AppColors.success : null,
      color: viewOnly ? const Color(0xFFFAF8F9) : null,
      onTap: () => openPage(context, SectionCoursesScreen(groupNo: group.groupNo)),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mine ? AppColors.success.withAlpha(30) : AppColors.tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${group.groupNo}',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: mine ? AppColors.success : AppColors.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(group.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    if (mine)
                      const StatusPill('YOUR SECTION', color: AppColors.success)
                    else if (viewOnly)
                      const StatusPill('VIEW ONLY', color: AppColors.textMuted, icon: Icons.lock),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${group.sections.length} courses  |  ${Formatters.credits(group.totalCredits)} credits'
                  '${group.fullCourses > 0 ? '  |  ${group.fullCourses} full' : ''}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Seats', style: TextStyle(fontSize: 12.5)),
                    SeatBadge(bottleneck),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _WaitlistTab extends StatelessWidget {
  const _WaitlistTab();

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdvisingProvider>();
    if (a.waitlist.isEmpty) {
      return const EmptyState(
        icon: Icons.hourglass_empty_rounded,
        title: 'You are not on any waitlist',
        message: 'When a course of your section is full, tap "Join waitlist". The first '
            'student in the queue gets the next free seat automatically.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: a.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const NoticeBanner(
            message: 'Order is decided by the server time of your request. When a seat '
                'frees up you are enrolled automatically and get a notification.',
          ),
          const SizedBox(height: 12),
          for (final w in a.waitlist)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.warning.withAlpha(30),
                      child: Text('#${w.position}',
                          style: const TextStyle(
                              color: AppColors.warning, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${w.sectionLabel}  ${w.title}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            '${Formatters.ordinal(w.position)} in the queue  |  joined ${Formatters.timeAgo(w.createdAt)}',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: a.isBusy
                          ? null
                          : () async {
                              final ok = await confirmDialog(context,
                                  title: 'Leave waitlist?',
                                  message: 'You will lose your place for ${w.sectionLabel}.',
                                  confirmLabel: 'Leave',
                                  destructive: true);
                              if (ok && context.mounted) {
                                await runWithFeedback(context, () => a.leaveWaitlist(w.id),
                                    success: 'Left the waitlist');
                              }
                            },
                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      child: const Text('Leave'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
