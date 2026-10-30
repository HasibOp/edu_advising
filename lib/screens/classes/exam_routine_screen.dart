import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/advising_provider.dart';
import '../../services/catalog.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../utils/pdf_export.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';

class ExamRoutineScreen extends StatefulWidget {
  const ExamRoutineScreen({super.key});

  @override
  State<ExamRoutineScreen> createState() => _ExamRoutineScreenState();
}

class _ExamRoutineScreenState extends State<ExamRoutineScreen> {
  late int _semester = context.read<AdvisingProvider>().student?.semesterNo ?? 0;

  Future<void> _pdf() {
    final catalog = Catalog.instance;
    return PdfExport.shareTable(
      title: 'Final Exam Routine - ${AppConfig.currentTerm}',
      filename: 'exam_routine_sem$_semester.pdf',
      subtitle: ['CSE Semester $_semester'],
      headers: ['Day', 'Course', 'Title'],
      rows: [
        for (final (day, code) in catalog.examsOf(_semester))
          ['Day $day', code, catalog.titleOf(code)],
      ],
      columnFlex: {0: 0.8, 1: 1, 2: 4},
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = Catalog.instance;
    return Scaffold(
      appBar: EduAppBar(
        title: 'Exam Routine',
        subtitle: 'Final exams  |  ${AppConfig.currentTerm}',
        actions: [
          IconButton(
            tooltip: _semester == 0 ? 'Pick one semester to download' : 'Download PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _semester == 0 ? null : () => runWithFeedback(context, _pdf),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          ChoiceChipsRow<int>(
            values: [0, ...catalog.semesters],
            selected: _semester,
            labelOf: (s) => s == 0 ? 'All' : 'Semester $s',
            onSelected: (s) => setState(() => _semester = s),
          ),
          const SizedBox(height: 12),
          if (_semester == 0) ..._byDay(catalog) else ..._oneSemester(catalog),
          const SizedBox(height: 12),
          const Text(
            'Exam dates are announced as Day 1 to Day 8 of the final exam week. '
            'Check the notice board for the calendar dates.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  List<Widget> _oneSemester(Catalog catalog) {
    final exams = catalog.examsOf(_semester);
    return [
      for (var day = 1; day <= 8; day++)
        Builder(builder: (context) {
          final today = exams.where((e) => e.$1 == day).toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              color: today.isEmpty ? const Color(0xFFFAF8F9) : null,
              child: Row(
                children: [
                  Container(
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: today.isEmpty ? AppColors.border : AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text('DAY',
                            style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1)),
                        Text('$day',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: today.isEmpty
                        ? const Text('No exam', style: TextStyle(color: AppColors.textMuted))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final (_, code) in today) ...[
                                Text(code,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800, color: AppColors.primary)),
                                Text(catalog.titleOf(code)),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        }),
    ];
  }

  List<Widget> _byDay(Catalog catalog) {
    return [
      for (var day = 1; day <= 8; day++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Day $day',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 15)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final sem in catalog.semesters)
                      for (final (d, code) in catalog.examsOf(sem))
                        if (d == day)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text('S$sem  $code', style: const TextStyle(fontSize: 12)),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ];
  }
}
