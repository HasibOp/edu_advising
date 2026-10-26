import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/portal.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/catalog.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';

/// Pick a course and compare its prerequisites with the transcript.
class PrereqCheckerScreen extends StatefulWidget {
  const PrereqCheckerScreen({super.key});

  @override
  State<PrereqCheckerScreen> createState() => _PrereqCheckerScreenState();
}

class _PrereqCheckerScreenState extends State<PrereqCheckerScreen> {
  Course? _course;
  String _query = '';

  List<Course> get _allCourses {
    final seen = <String>{};
    return [
      for (final sem in Catalog.instance.semesters)
        for (final c in Catalog.instance.coursesOf(sem))
          if (seen.add(c.code)) c,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final isStudent = user?.isStudent ?? false;
    return Scaffold(
      appBar: const EduAppBar(title: 'Prerequisite Checker'),
      body: isStudent
          ? FutureView<List<TranscriptEntry>>(
              load: () => context.read<ApiService>().fetchTranscript(user!.id),
              builder: (context, transcript, _) => _body(transcript),
            )
          : _body(null),
    );
  }

  Widget _body(List<TranscriptEntry>? transcript) {
    final courses = _allCourses
        .where((c) =>
            _query.isEmpty ||
            c.code.toLowerCase().contains(_query) ||
            c.title.toLowerCase().contains(_query))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        SearchField(
          hint: 'Type a course code or title, e.g. CSE 443',
          onChanged: (v) => setState(() {
            _query = v.trim().toLowerCase();
            _course = null;
          }),
        ),
        const SizedBox(height: 12),
        if (_course != null)
          _Result(course: _course!, transcript: transcript)
        else ...[
          const Text('Pick a course', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          for (final c in courses.take(40))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${c.code}  ${c.title}', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('Semester ${c.semesterNo}  |  '
                  '${Catalog.instance.prerequisitesOf(c.code).isEmpty ? 'No prerequisite' : 'Needs ${Catalog.instance.prerequisitesOf(c.code).join(', ')}'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _course = c),
            ),
        ],
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.course, required this.transcript});

  final Course course;
  final List<TranscriptEntry>? transcript;

  @override
  Widget build(BuildContext context) {
    final catalog = Catalog.instance;
    final prereqs = catalog.prerequisitesOf(course.code);
    TranscriptEntry? entryFor(String code) {
      for (final t in transcript ?? const <TranscriptEntry>[]) {
        if (t.courseCode == code) return t;
      }
      return null;
    }

    final allPassed = prereqs.every((p) => entryFor(p)?.passed ?? false);
    final requiredBy = [
      for (final sem in catalog.semesters)
        for (final c in catalog.coursesOf(sem))
          if (catalog.prerequisitesOf(c.code).contains(course.code)) c.code,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.code,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
              Text(course.title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('Semester ${course.semesterNo}  |  ${Formatters.credits(course.credits)} credits',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              const SizedBox(height: 10),
              if (prereqs.isEmpty)
                const StatusPill('NO PREREQUISITE', color: AppColors.success)
              else if (transcript != null)
                StatusPill(allPassed ? 'YOU CAN TAKE THIS COURSE' : 'PREREQUISITE MISSING',
                    color: allPassed ? AppColors.success : AppColors.danger,
                    icon: allPassed ? Icons.check : Icons.close),
            ],
          ),
        ),
        if (prereqs.isNotEmpty) const SectionHeader('Prerequisites'),
        for (final p in prereqs)
          Builder(builder: (context) {
            final t = entryFor(p);
            final ok = t?.passed ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      transcript == null
                          ? Icons.circle_outlined
                          : ok
                              ? Icons.check_circle
                              : Icons.cancel,
                      color: transcript == null
                          ? AppColors.textMuted
                          : ok
                              ? AppColors.success
                              : AppColors.danger,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$p  ${catalog.titleOf(p)}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (transcript != null)
                            Text(
                              t == null
                                  ? 'Not taken yet'
                                  : '${t.term}: grade ${t.grade}${t.passed ? '' : ' (failed)'}',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        if (requiredBy.isNotEmpty) ...[
          const SectionHeader('This course unlocks'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final c in requiredBy) Chip(label: Text(c))],
          ),
        ],
      ],
    );
  }
}
