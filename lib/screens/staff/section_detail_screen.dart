import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/enrollment.dart';
import '../../models/student.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../services/api_service.dart';
import '../../services/catalog.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_export.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';
import 'staff_advise_screen.dart';

Future<bool> changeSeatsDialog(BuildContext context, CourseSection s) async {
  final main = s.parts.first;
  final room = Catalog.instance.roomCapacity(s.courseCode, main.sectionNo);
  final value = await textInputDialog(
    context,
    title: 'Change seats of ${s.label}',
    message: 'Now ${main.capacity} seats, ${main.enrolled} taken.\n'
        'Allowed: ${main.enrolled} to $room (room capacity).',
    label: 'New capacity',
    initial: '${main.capacity}',
    confirmLabel: 'Save',
    keyboardType: TextInputType.number,
    required: true,
  );
  if (value == null || !context.mounted) return false;
  final capacity = int.tryParse(value);
  if (capacity == null) {
    showAppSnackBar(context, 'Enter a whole number', isError: true);
    return false;
  }
  return runWithFeedback(
    context,
    () => context.read<StaffProvider>().changeSeats(s.id, capacity),
    success: '${s.label} now has $capacity seats',
  );
}

class SectionDetailScreen extends StatefulWidget {
  const SectionDetailScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  State<SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends State<SectionDetailScreen> {
  Key _key = UniqueKey();

  void _reload() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffProvider>();
    final user = context.read<AuthProvider>().user!;
    final api = context.read<ApiService>();
    final s = staff.allSections.where((x) => x.id == widget.sectionId).firstOrNull;
    if (s == null) {
      return const Scaffold(
          appBar: EduAppBar(title: 'Section'), body: EmptyState(icon: Icons.error, title: 'Not found'));
    }
    final canEdit = StaffProvider.owns(user, s);
    final catalog = Catalog.instance;
    final slots = catalog.slotsFor(s.courseCode, s.sectionNo);

    return Scaffold(
      appBar: EduAppBar(title: s.fullLabel, subtitle: s.title),
      body: FutureView<(List<Enrollment>, List<Student>, List<WaitlistEntry>)>(
        key: _key,
        load: () async {
          final r = await Future.wait([
            api.fetchSectionEnrollments(s.id),
            api.fetchStudents(),
            api.fetchSectionWaitlist(s.id),
          ]);
          return (
            r[0] as List<Enrollment>,
            r[1] as List<Student>,
            r[2] as List<WaitlistEntry>,
          );
        },
        builder: (context, data, reload) {
          final (roster, students, waitlist) = data;
          final names = {for (final st in students) st.id: st.name};
          final others = s.enrolled - roster.length;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await staff.refresh();
              await reload();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Semester ${s.semesterNo}  |  Section ${s.groupNo}  |  '
                                '${Formatters.credits(s.credits)} credits'),
                          ),
                          SeatBadge(s),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final slot in slots)
                        Text(
                          '${slot.day} ${Formatters.routineTime(slot.time)}  |  '
                          '${slot.isLab ? 'Lab' : 'Theory'}  |  Room ${slot.room}  |  ${slot.faculty}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      if (slots.isEmpty)
                        const Text('Time TBA', style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          OutlinedButton.icon(
                            onPressed: canEdit
                                ? () async {
                                    if (await changeSeatsDialog(context, s)) _reload();
                                  }
                                : null,
                            icon: const Icon(Icons.event_seat_outlined, size: 18),
                            label: const Text('Change seats'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => runWithFeedback(
                              context,
                              () => PdfExport.shareTable(
                                title: 'Section roster',
                                filename: 'roster_${s.id}.pdf',
                                subtitle: ['${s.fullLabel}  ${s.title}', 'Seats ${s.enrolled}/${s.capacity}'],
                                headers: ['#', 'Student ID', 'Name', 'Section', 'Type'],
                                rows: [
                                  for (var i = 0; i < roster.length; i++)
                                    [
                                      '${i + 1}',
                                      roster[i].studentId,
                                      names[roster[i].studentId] ?? '',
                                      roster[i].label,
                                      roster[i].type.label,
                                    ],
                                ],
                              ),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                            label: const Text('PDF'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SectionHeader('Enrolled students (${roster.length})'),
                if (roster.isEmpty)
                  const AppCard(
                    child: Text('No demo students enrolled yet.',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                for (final e in roster)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(names[e.studentId] ?? e.studentId,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${e.studentId}  |  ${e.label}  |  ${e.type.label}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Open student',
                            icon: const Icon(Icons.manage_accounts_outlined),
                            onPressed: () async {
                              await openPage(context, StaffAdviseScreen(studentId: e.studentId));
                              _reload();
                            },
                          ),
                          if (canEdit)
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                              onPressed: () async {
                                final ok = await confirmDialog(context,
                                    title: 'Drop ${e.label}?',
                                    message: 'Drop ${names[e.studentId]} (${e.studentId}) from '
                                        '${e.label}. The first student on the waitlist gets the seat.',
                                    confirmLabel: 'Drop',
                                    destructive: true);
                                if (!ok || !context.mounted) return;
                                final done = await runWithFeedback(
                                    context, () => api.staffDrop(user, e.id),
                                    success: 'Dropped ${e.label}');
                                if (done && context.mounted) {
                                  await staff.refresh();
                                  _reload();
                                }
                              },
                              child: const Text('DROP'),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (others > 0)
                  Text('+ $others seat(s) taken by students outside this demo (simulated).',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                SectionHeader('Waitlist (${waitlist.length})'),
                if (waitlist.isEmpty)
                  const Text('Nobody is waiting.', style: TextStyle(color: AppColors.textMuted)),
                for (final w in waitlist)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.warning.withAlpha(30),
                      child: Text('#${w.position}',
                          style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(names[w.studentId] ?? w.studentId),
                    subtitle: Text('${w.studentId}  |  joined ${Formatters.timeAgo(w.createdAt)}'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
