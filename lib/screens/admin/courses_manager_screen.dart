import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/catalog.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/state_views.dart';

/// Courses and sections of each semester: add, edit, delete; open or close a
/// whole section. Seat numbers are changed by faculty / the Dean.
class CoursesManagerScreen extends StatefulWidget {
  const CoursesManagerScreen({super.key});

  @override
  State<CoursesManagerScreen> createState() => _CoursesManagerScreenState();
}

class _CoursesManagerScreenState extends State<CoursesManagerScreen> {
  int _semester = 10;
  Key _key = UniqueKey();

  void _reload() => setState(() => _key = UniqueKey());

  Future<void> _courseForm({CourseSection? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CourseForm(semester: _semester, existing: existing),
    );
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    final user = context.read<AuthProvider>().user!;
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _courseForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add course'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: ChoiceChipsRow<int>(
              values: Catalog.instance.semesters,
              selected: _semester,
              labelOf: (s) => 'Semester $s',
              onSelected: (s) => setState(() => _semester = s),
            ),
          ),
          Expanded(
            child: FutureView<List<CourseSection>>(
              key: ValueKey('$_semester$_key'),
              load: () => api.fetchSections(semesterNo: _semester),
              builder: (context, sections, reload) {
                final groups = SectionGroup.fromSections(_semester, sections);
                final byCourse = <String, List<CourseSection>>{};
                for (final s in sections) {
                  byCourse.putIfAbsent(s.courseCode, () => []).add(s);
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${byCourse.length} courses  |  ${groups.length} sections',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final cap = await textInputDialog(context,
                                title: 'Open a new section',
                                message: 'Adds Section ${groups.isEmpty ? 1 : groups.last.groupNo + 1} '
                                    'with every course of Semester $_semester.',
                                label: 'Seats per course',
                                initial: '30',
                                confirmLabel: 'Open section',
                                keyboardType: TextInputType.number,
                                required: true);
                            if (cap == null || !context.mounted) return;
                            await runWithFeedback(context,
                                () => api.addSectionGroup(user, _semester, int.tryParse(cap) ?? 0),
                                success: 'Section opened');
                            _reload();
                          },
                          icon: const Icon(Icons.add_box_outlined, size: 18),
                          label: const Text('Open section'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final g in groups)
                          InputChip(
                            label: Text('Section ${g.groupNo}'),
                            onDeleted: () async {
                              final ok = await confirmDialog(context,
                                  title: 'Close Section ${g.groupNo}?',
                                  message: 'Removes all ${g.sections.length} course sections of '
                                      'Section ${g.groupNo}. Only possible with no enrolled students.',
                                  confirmLabel: 'Close section',
                                  destructive: true);
                              if (!ok || !context.mounted) return;
                              await runWithFeedback(context,
                                  () => api.deleteSectionGroup(user, _semester, g.groupNo),
                                  success: 'Section ${g.groupNo} closed');
                              _reload();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final entry in byCourse.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              title: Text('${entry.key}  ${entry.value.first.title}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${Formatters.credits(entry.value.first.credits)} credits  |  '
                                  '${entry.value.length} sections'),
                              children: [
                                for (final s in entry.value)
                                  ListTile(
                                    dense: true,
                                    title: Text('Section ${s.groupNo}: ${s.fullLabel}'),
                                    trailing: SeatBadge(s),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _courseForm(existing: entry.value.first),
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        label: const Text('Edit'),
                                      ),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                                        onPressed: () async {
                                          final ok = await confirmDialog(context,
                                              title: 'Delete ${entry.key}?',
                                              message: 'Removes it from Semester $_semester. Only '
                                                  'possible when nobody is enrolled.',
                                              confirmLabel: 'Delete',
                                              destructive: true);
                                          if (!ok || !context.mounted) return;
                                          await runWithFeedback(
                                              context,
                                              () => api.deleteCourse(user, entry.key, _semester),
                                              success: '${entry.key} deleted');
                                          _reload();
                                        },
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        label: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseForm extends StatefulWidget {
  const _CourseForm({required this.semester, this.existing});

  final int semester;
  final CourseSection? existing;

  @override
  State<_CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<_CourseForm> {
  late final _code = TextEditingController(text: widget.existing?.courseCode);
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _credits = TextEditingController(
      text: widget.existing == null ? '3' : Formatters.credits(widget.existing!.credits));
  final _capacity = TextEditingController(text: '30');

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _credits.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = context.read<AuthProvider>().user!;
    final ok = await runWithFeedback(
      context,
      () => context.read<ApiService>().saveCourse(
            user,
            code: _code.text,
            title: _title.text,
            credits: double.tryParse(_credits.text) ?? 0,
            semesterNo: widget.semester,
            isNew: widget.existing == null,
            capacity: int.tryParse(_capacity.text) ?? 0,
          ),
      success: widget.existing == null ? 'Course added' : 'Course updated',
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isNew ? 'Add course to Semester ${widget.semester}' : 'Edit ${widget.existing!.courseCode}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
              controller: _code,
              enabled: isNew,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(labelText: 'Course code', hintText: 'CSE 499'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _title,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _credits,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.text),
                    decoration: const InputDecoration(labelText: 'Credits'),
                  ),
                ),
                if (isNew) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _capacity,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(labelText: 'Seats per section'),
                    ),
                  ),
                ],
              ],
            ),
            if (isNew)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('A section of this course is created in every section of the semester.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
