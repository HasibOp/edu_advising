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
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';

class StaffAdviseScreen extends StatefulWidget {
  const StaffAdviseScreen({super.key, required this.studentId});

  final String studentId;

  @override
  State<StaffAdviseScreen> createState() => _StaffAdviseScreenState();
}

class _StaffAdviseScreenState extends State<StaffAdviseScreen> {
  Student? _student;
  List<Enrollment> _enrollments = [];
  List<CourseSection> _sections = [];
  int? _semester;
  int _group = 1;
  final Set<String> _selected = {};
  bool _loading = true;
  bool _busy = false;
  String? _error;

  ApiService get _api => context.read<ApiService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final student = await _api.fetchStudent(widget.studentId);
      _semester ??= student.semesterNo;
      _group = student.lockedGroup ?? _group;
      final results = await Future.wait([
        _api.fetchEnrollments(student.id),
        _api.fetchSections(semesterNo: _semester),
      ]);
      if (!mounted) return;
      setState(() {
        _student = student;
        _enrollments = results[0] as List<Enrollment>;
        _sections = results[1] as List<CourseSection>;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickSemester(int semester) async {
    setState(() {
      _semester = semester;
      _group = 1;
      _selected.clear();
    });
    final sections = await _api.fetchSections(semesterNo: semester);
    if (mounted) setState(() => _sections = sections);
  }

  Future<void> _add() async {
    final user = context.read<AuthProvider>().user!;
    final picked = _sections.where((s) => _selected.contains(s.id)).toList();
    final bypass = !_student!.clearanceStatus.canAdvise;
    final ok = await confirmDialog(
      context,
      title: 'Add ${picked.length} course(s) for ${_student!.name}?',
      message: '${picked.map((s) => s.label).join(', ')}'
          '${bypass ? '\n\nThe student is Not cleared: this Dean bypass will be logged.' : ''}',
      confirmLabel: 'Add',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    var done = false;
    try {
      final added = await runAllowingConflicts(
        context,
        (accept) => _api.staffAdvise(user, _student!.id, picked.map((s) => s.id).toList(),
            acceptConflicts: accept),
      );
      done = added != null;
      if (done && mounted) {
        showAppSnackBar(context, 'Added ${picked.map((s) => s.label).join(', ')}');
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, errorText(e), isError: true);
    }
    if (done) _selected.clear();
    await _load();
    if (mounted) {
      setState(() => _busy = false);
      context.read<StaffProvider>().refresh();
    }
  }

  Future<void> _drop(Enrollment e) async {
    final user = context.read<AuthProvider>().user!;
    final ok = await confirmDialog(
      context,
      title: 'Drop ${e.label}?',
      message: 'Remove ${e.title} from ${_student!.name}. The seat goes to the waitlist.',
      confirmLabel: 'Drop',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await runWithFeedback(context, () => _api.staffDrop(user, e.id), success: 'Dropped ${e.label}');
    await _load();
    if (mounted) context.read<StaffProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final s = _student;
    if (_loading) return const Scaffold(body: LoadingView());
    if (s == null) {
      return Scaffold(
        appBar: const EduAppBar(title: 'Advise student'),
        body: ErrorView(message: _error ?? 'Not found', onRetry: _load),
      );
    }
    final catalog = Catalog.instance;
    final groups = SectionGroup.fromSections(_semester!, _sections);
    final group = groups.where((g) => g.groupNo == _group).firstOrNull ?? groups.firstOrNull;
    final taken = {for (final e in _enrollments) e.courseCode};
    final credits = _enrollments.fold<double>(0, (sum, e) => sum + e.credits);
    final ownSemester = _semester == s.semesterNo;
    final lockedOther =
        ownSemester && s.lockedGroup != null && group != null && s.lockedGroup != group.groupNo;

    return Scaffold(
      appBar: EduAppBar(title: s.name, subtitle: '${s.id}  |  Semester ${s.semesterNo}'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ClearanceBadge(s.clearanceStatus),
              Text('${Formatters.credits(credits)} credits enrolled',
                  style: const TextStyle(color: AppColors.textMuted)),
            ],
          ),
          if (!s.clearanceStatus.canAdvise) ...[
            const SizedBox(height: 10),
            const NoticeBanner(
              color: AppColors.warning,
              icon: Icons.shield_outlined,
              message: 'Not cleared: you are advising with the Dean bypass. It is logged.',
            ),
          ],
          SectionHeader('Current courses (${_enrollments.length})'),
          if (_enrollments.isEmpty)
            const AppCard(
                child: Text('No courses yet.', style: TextStyle(color: AppColors.textMuted))),
          for (final e in _enrollments)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.label}  ${e.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                              '${e.type.label}  |  ${Formatters.credits(e.credits)} cr  |  '
                              '${catalog.facultyFor(e.courseCode, e.sectionNo).join(', ')}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Builder(builder: (context) {
                      final section = _sectionOf(e);
                      final allowed = user.isDean ||
                          (section != null && StaffProvider.owns(user, section)) ||
                          catalog.teaches(user.shortName ?? '', e.courseCode, e.sectionNo);
                      return TextButton(
                        onPressed: allowed ? () => _drop(e) : null,
                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                        child: Text(allowed ? 'DROP' : 'Not yours'),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SectionHeader('Add courses'),
          ChoiceChipsRow<int>(
            values: catalog.semesters,
            selected: _semester,
            labelOf: (x) => x == s.semesterNo ? 'Sem $x (own)' : 'Sem $x',
            onSelected: _pickSemester,
          ),
          const SizedBox(height: 8),
          ChoiceChipsRow<int>(
            values: [for (final g in groups) g.groupNo],
            selected: group?.groupNo,
            labelOf: (g) => 'Section $g',
            onSelected: (g) => setState(() {
              _group = g;
              _selected.clear();
            }),
          ),
          const SizedBox(height: 8),
          Text(
            ownSemester
                ? 'Own semester: added as REGULAR (section lock applies).'
                : 'Other semester: added as EXTRA.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          if (lockedOther)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: NoticeBanner(
                color: AppColors.textMuted,
                icon: Icons.lock_outline,
                message: 'Student is locked to Section ${s.lockedGroup}. Drop all regular courses '
                    'first to move them.',
              ),
            ),
          const SizedBox(height: 8),
          if (group != null)
            for (final sec in group.sections)
              Builder(builder: (context) {
                final mine = StaffProvider.owns(user, sec);
                final enabled = mine && !sec.isFull && !taken.contains(sec.courseCode) && !lockedOther;
                return CheckboxListTile(
                  value: taken.contains(sec.courseCode) || _selected.contains(sec.id),
                  onChanged: enabled
                      ? (v) => setState(() => v == true ? _selected.add(sec.id) : _selected.remove(sec.id))
                      : null,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('${sec.label}  ${sec.title}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    taken.contains(sec.courseCode)
                        ? 'Already has ${sec.courseCode}'
                        : mine
                            ? '${Formatters.credits(sec.credits)} cr'
                            : 'Not your course',
                    style: TextStyle(color: mine ? AppColors.textMuted : AppColors.danger),
                  ),
                  secondary: SeatBadge(sec, showCount: false),
                );
              }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: FilledButton.icon(
            onPressed: _selected.isEmpty || _busy ? null : _add,
            icon: const Icon(Icons.add),
            label: Text('Add ${_selected.length} selected'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
      ),
    );
  }

  CourseSection? _sectionOf(Enrollment e) {
    for (final s in context.read<StaffProvider>().allSections) {
      if (s.id == e.sectionId) return s;
    }
    return null;
  }
}
