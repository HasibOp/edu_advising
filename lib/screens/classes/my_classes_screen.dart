import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enrollment.dart';
import '../../providers/advising_provider.dart';
import '../../services/catalog.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_export.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';
import '../advising/clearance_screen.dart';
import 'class_routine_screen.dart';

/// What the student is enrolled in. There is no Drop button: only faculty
/// or the Dean can drop a regular course.
class MyClassesScreen extends StatelessWidget {
  const MyClassesScreen({super.key});

  static String schedule(Enrollment e) {
    final slots = Catalog.instance.slotsFor(e.courseCode, e.sectionNo);
    if (slots.isEmpty) return 'TBA';
    return slots
        .map((s) => '${s.day.substring(0, 3)} ${s.time.replaceAll('.', ':')}')
        .join(', ');
  }

  static String rooms(Enrollment e) => Catalog.instance
      .slotsFor(e.courseCode, e.sectionNo)
      .map((s) => s.room)
      .toSet()
      .join(', ');

  Future<void> _pdf(AdvisingProvider a) {
    final s = a.student!;
    return PdfExport.shareTable(
      title: 'My Classes - ${AppConfig.currentTerm}',
      filename: 'my_classes_${s.id}.pdf',
      subtitle: ['${s.name}   |   ID ${s.id}   |   Semester ${s.semesterNo}'],
      headers: ['Course', 'Title', 'Cr', 'Type', 'Schedule', 'Room', 'Faculty'],
      rows: [
        for (final e in a.enrollments)
          [
            e.label,
            e.title,
            Formatters.credits(e.credits),
            e.type.label,
            schedule(e),
            rooms(e),
            Catalog.instance.facultyFor(e.courseCode, e.sectionNo).join(', '),
          ],
      ],
      notes: ['Total: ${a.enrollments.length} courses, ${Formatters.credits(a.credits)} credits'],
      landscape: true,
      columnFlex: {0: 1.1, 1: 3, 2: 0.5, 3: 0.8, 4: 2.4, 5: 1, 6: 1.2},
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdvisingProvider>();
    return Scaffold(
      appBar: EduAppBar(
        title: 'My Classes',
        subtitle: AppConfig.currentTerm,
        actions: [
          if (a.enrollments.isNotEmpty)
            IconButton(
              tooltip: 'Download PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => runWithFeedback(context, () => _pdf(a)),
            ),
        ],
      ),
      body: a.student == null
          ? const LoadingView()
          : a.enrollments.isEmpty
              ? EmptyState(
                  icon: Icons.class_outlined,
                  title: 'No classes yet',
                  message: 'Courses appear here after advising.',
                  action: FilledButton(
                    onPressed: () => openPage(context, const ClearanceScreen()),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Go to Advising'),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: a.refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                                value: '${a.enrollments.length}',
                                label: 'Courses',
                                icon: Icons.menu_book_outlined),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatTile(
                                value: Formatters.credits(a.credits),
                                label: 'Credits',
                                icon: Icons.stacked_bar_chart),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatTile(
                                value: a.lockedGroup == null ? '-' : 'Sec ${a.lockedGroup}',
                                label: 'Your section',
                                icon: Icons.groups_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => openPage(context, const ClassRoutineScreen()),
                        icon: const Icon(Icons.calendar_view_week_outlined),
                        label: const Text('See my weekly routine'),
                      ),
                      const SizedBox(height: 6),
                      for (final e in a.enrollments)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _ClassCard(enrollment: e),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Need to drop a course? Students cannot drop regular courses. Contact the '
                        'course faculty or the Dean. Extra courses can be dropped by request.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.enrollment});

  final Enrollment enrollment;

  @override
  Widget build(BuildContext context) {
    final e = enrollment;
    final catalog = Catalog.instance;
    final slots = catalog.slotsFor(e.courseCode, e.sectionNo);
    final faculty = catalog.facultyFor(e.courseCode, e.sectionNo);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(e.label,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    StatusPill(e.type.label.toUpperCase(),
                        color:
                            e.type == EnrollmentType.regular ? AppColors.success : AppColors.info),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${Formatters.credits(e.credits)} cr',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          Text(e.title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          if (faculty.isNotEmpty)
            Text('Faculty: ${faculty.map(catalog.facultyName).join(', ')}',
                style: const TextStyle(fontSize: 12.5)),
          if (slots.isEmpty)
            const Text('Time: TBA', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          for (final s in slots)
            Text(
              '${s.day}  ${Formatters.routineTime(s.time)}  |  ${s.isLab ? 'Lab' : 'Theory'}  |  Room ${s.room}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          const SizedBox(height: 4),
          Text('Enrolled ${Formatters.date(e.createdAt)} by ${e.byUser == e.studentId ? 'you' : e.byUser}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
