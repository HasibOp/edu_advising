import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../services/catalog.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';
import 'section_detail_screen.dart';

class MyCoursesScreen extends StatelessWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffProvider>();
    final user = context.watch<AuthProvider>().user;
    if (staff.isLoading) return const LoadingView();
    if (staff.error != null) return ErrorView(message: staff.error!, onRetry: staff.refresh);

    final sections = [...staff.mySections]
      ..sort((a, b) {
        final c = a.courseCode.compareTo(b.courseCode);
        return c != 0 ? c : a.groupNo.compareTo(b.groupNo);
      });
    final students = sections.fold<int>(0, (sum, s) => sum + s.enrolled);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: staff.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AppCard(
            child: Row(
              children: [
                Avatar(Catalog.instance.facultyByShort(user?.shortName ?? '')?.initials ?? '?',
                    size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('${user?.shortName}  |  ${user?.roleLabel}',
                          style: const TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: StatTile(value: '${sections.length}', label: 'Sections')),
              const SizedBox(width: 10),
              Expanded(child: StatTile(value: '$students', label: 'Seats taken')),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      value: '${staff.pendingCount}',
                      label: 'Pending requests',
                      color: staff.pendingCount > 0 ? AppColors.warning : AppColors.primary)),
            ],
          ),
          const SectionHeader('My sections'),
          if (sections.isEmpty)
            const EmptyState(
              icon: Icons.class_outlined,
              title: 'No sections in the routine',
              message: 'Sections appear here when the routine lists your short form.',
            ),
          for (final s in sections)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: SectionTile(section: s)),
        ],
      ),
    );
  }
}

class SectionTile extends StatelessWidget {
  const SectionTile({super.key, required this.section});

  final CourseSection section;

  @override
  Widget build(BuildContext context) {
    final s = section;
    final slots = Catalog.instance.slotsFor(s.courseCode, s.sectionNo);
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => openPage(context, SectionDetailScreen(sectionId: s.id)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fullLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  'Semester ${s.semesterNo}, Section ${s.groupNo}  |  '
                  '${slots.isEmpty ? 'Time TBA' : slots.map((x) => '${x.day.substring(0, 3)} ${x.time}').join(', ')}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SeatBadge(s),
              const SizedBox(height: 4),
              Text('${Formatters.credits(s.credits)} cr',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
