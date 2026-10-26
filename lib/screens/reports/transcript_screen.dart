import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/portal.dart';
import '../../providers/advising_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_export.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';

/// Unofficial transcript (dummy grades in the frontend phase).
class TranscriptScreen extends StatelessWidget {
  const TranscriptScreen({super.key});

  static double gpa(Iterable<TranscriptEntry> items) {
    final credits = items.fold<double>(0, (s, t) => s + t.credits);
    if (credits == 0) return 0;
    return items.fold<double>(0, (s, t) => s + t.credits * t.gradePoint) / credits;
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AdvisingProvider>().student;
    return Scaffold(
      appBar: const EduAppBar(title: 'Transcript', subtitle: 'Unofficial copy'),
      body: student == null
          ? const LoadingView()
          : FutureView<List<TranscriptEntry>>(
              load: () => context.read<ApiService>().fetchTranscript(student.id),
              builder: (context, transcript, _) {
                if (transcript.isEmpty) {
                  return const EmptyState(
                      icon: Icons.workspace_premium_outlined,
                      title: 'No completed courses yet',
                      message: 'Grades appear here after your first semester.');
                }
                final terms = <String, List<TranscriptEntry>>{};
                for (final t in transcript) {
                  terms.putIfAbsent('Semester ${t.semesterNo}  |  ${t.term}', () => []).add(t);
                }
                final passedCredits = transcript
                    .where((t) => t.passed)
                    .fold<double>(0, (s, t) => s + t.credits);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: StatTile(
                                value: gpa(transcript).toStringAsFixed(2), label: 'CGPA')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatTile(
                                value: Formatters.credits(passedCredits),
                                label: 'Credits earned')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatTile(value: '${transcript.length}', label: 'Courses')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => runWithFeedback(
                        context,
                        () => PdfExport.shareTable(
                          title: 'Transcript (unofficial)',
                          filename: 'transcript_${student.id}.pdf',
                          subtitle: [
                            '${student.name}   |   ID ${student.id}   |   CGPA ${gpa(transcript).toStringAsFixed(2)}'
                          ],
                          headers: ['Semester', 'Term', 'Course', 'Title', 'Cr', 'Grade', 'GP'],
                          rows: [
                            for (final t in transcript)
                              [
                                '${t.semesterNo}',
                                t.term,
                                t.courseCode,
                                t.title,
                                Formatters.credits(t.credits),
                                t.grade,
                                t.gradePoint.toStringAsFixed(2),
                              ],
                          ],
                          columnFlex: {0: 0.7, 1: 1.1, 2: 1, 3: 3.4, 4: 0.5, 5: 0.6, 6: 0.6},
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Download PDF'),
                    ),
                    for (final entry in terms.entries) ...[
                      SectionHeader(entry.key,
                          trailing: Text('GPA ${gpa(entry.value).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w700))),
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            for (final t in entry.value)
                              ListTile(
                                dense: true,
                                title: Text('${t.courseCode}  ${t.title}',
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text('${Formatters.credits(t.credits)} credits'),
                                trailing: Text(
                                  t.grade,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: t.passed ? AppColors.success : AppColors.danger,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
