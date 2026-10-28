import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/class_slot.dart';
import '../../models/course.dart';
import '../../providers/advising_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/catalog.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../utils/pdf_export.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/routine_views.dart';
import '../../widgets/state_views.dart';

enum _Mode { mine, section }

/// Weekly class routine. "By section" builds the routine of one section of
/// a semester from the course codes: CSE 443.3 belongs to Section 3.
class ClassRoutineScreen extends StatefulWidget {
  const ClassRoutineScreen({super.key, this.semester, this.group});

  final int? semester;
  final int? group;

  @override
  State<ClassRoutineScreen> createState() => _ClassRoutineScreenState();
}

class _ClassRoutineScreenState extends State<ClassRoutineScreen> {
  static final List<CourseSection> _offer = Catalog.instance.offerSections();

  late _Mode _mode;
  late int _semester;
  late int _group;
  bool _grid = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    final advising = context.read<AdvisingProvider>();
    final student = user?.isStudent == true ? advising.student : null;
    final hasMine = user?.isStaff == true || (student != null && advising.enrollments.isNotEmpty);
    _mode = widget.semester == null && hasMine ? _Mode.mine : _Mode.section;
    _semester = widget.semester ?? student?.semesterNo ?? 10;
    _group = widget.group ?? student?.lockedGroup ?? 1;
  }

  List<CourseSection> get _groupSections => _offer
      .where((s) => s.semesterNo == _semester && s.groupNo == _group)
      .toList();

  List<ClassSlot> _slots(BuildContext context) {
    final catalog = Catalog.instance;
    if (_mode == _Mode.section) {
      // Every part of a split lab (CSE 114.1 and CSE 114.11) belongs to the section.
      return [
        for (final s in _groupSections)
          for (final p in s.parts) ...catalog.slotsFor(s.courseCode, p.sectionNo),
      ];
    }
    final user = context.read<AuthProvider>().user!;
    if (user.isStaff) {
      return [
        for (final (code, no) in catalog.sectionsTaughtBy(user.shortName!))
          ...catalog
              .slotsFor(code, no)
              .where((s) => Catalog.facultyKey(s.faculty) == Catalog.facultyKey(user.shortName!)),
      ];
    }
    return [
      for (final e in context.read<AdvisingProvider>().enrollments)
        ...catalog.slotsFor(e.courseCode, e.sectionNo),
    ];
  }

  String _title(BuildContext context) {
    if (_mode == _Mode.section) return 'Semester $_semester - Section $_group';
    final user = context.read<AuthProvider>().user!;
    return user.isStaff ? 'Teaching routine - ${user.name}' : 'My routine - ${user.name}';
  }

  Future<void> _pdf(BuildContext context, List<ClassSlot> slots) {
    final title = _title(context);
    return PdfExport.shareTable(
      title: 'Class Routine - ${AppConfig.currentTerm}',
      filename: _mode == _Mode.section
          ? 'routine_sem${_semester}_sec$_group.pdf'
          : 'my_routine.pdf',
      subtitle: [title],
      headers: ['Day', 'Time', 'Course', 'Title', 'Type', 'Room', 'Faculty'],
      rows: routinePdfRows(slots),
      landscape: true,
      columnFlex: {0: 1.1, 1: 1.1, 2: 1, 3: 3, 4: 0.8, 5: 0.8, 6: 1},
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AdvisingProvider>();
    final user = context.read<AuthProvider>().user;
    final catalog = Catalog.instance;
    final slots = _slots(context);
    final noTime = _mode == _Mode.section
        ? _groupSections
            .where((s) => s.parts.every((p) => catalog.slotsFor(s.courseCode, p.sectionNo).isEmpty))
            .toList()
        : const <CourseSection>[];

    return Scaffold(
      appBar: EduAppBar(
        title: 'Class Routine',
        subtitle: AppConfig.currentTerm,
        actions: [
          IconButton(
            tooltip: _grid ? 'Day list' : 'Week grid',
            icon: Icon(_grid ? Icons.view_agenda_outlined : Icons.calendar_view_week_outlined),
            onPressed: () => setState(() => _grid = !_grid),
          ),
          IconButton(
            tooltip: 'Download PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: slots.isEmpty ? null : () => runWithFeedback(context, () => _pdf(context, slots)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          SegmentedButton<_Mode>(
            segments: [
              ButtonSegment(
                value: _Mode.mine,
                label: Text(user?.isStaff == true ? 'My teaching' : 'My routine'),
                icon: const Icon(Icons.person_outline),
              ),
              const ButtonSegment(
                value: _Mode.section,
                label: Text('By section'),
                icon: Icon(Icons.grid_on_outlined),
              ),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.tint,
              selectedForegroundColor: AppColors.primary,
            ),
            onSelectionChanged: (v) => setState(() => _mode = v.first),
          ),
          if (_mode == _Mode.section) ...[
            const SizedBox(height: 12),
            ChoiceChipsRow<int>(
              values: catalog.semesters,
              selected: _semester,
              labelOf: (s) => 'Semester $s',
              onSelected: (s) => setState(() {
                _semester = s;
                _group = 1;
              }),
            ),
            const SizedBox(height: 8),
            ChoiceChipsRow<int>(
              values: [for (var g = 1; g <= catalog.groupCount(_semester); g++) g],
              selected: _group,
              labelOf: (g) => 'Section $g',
              onSelected: (g) => setState(() => _group = g),
            ),
          ],
          const SizedBox(height: 12),
          Text(_title(context),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
          if (_mode == _Mode.section)
            Text(
              _groupSections.map((s) => s.label).join('  |  '),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          const SizedBox(height: 10),
          if (slots.isEmpty)
            const EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No classes to show',
              message: 'Enroll in courses first, or switch to "By section".',
            )
          else if (_grid)
            AppCard(padding: const EdgeInsets.all(8), child: WeekRoutineGrid(slots: slots))
          else
            DayRoutineList(slots: slots),
          if (noTime.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'No class time published: ${noTime.map((s) => s.label).join(', ')}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Labs have a maroon border. Tap and hold a block for the full course name.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
