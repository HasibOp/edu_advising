import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../providers/advising_provider.dart';
import '../../services/api_service.dart';
import '../../services/catalog.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_export.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';

/// CSE Course Offer List & Section Structures, with live seats.
class OfferListScreen extends StatefulWidget {
  const OfferListScreen({super.key});

  @override
  State<OfferListScreen> createState() => _OfferListScreenState();
}

class _OfferListScreenState extends State<OfferListScreen> {
  late int _semester = context.read<AdvisingProvider>().student?.semesterNo ?? 1;
  String _query = '';
  List<CourseSection> _loaded = [];

  Future<void> _pdf() => PdfExport.shareTable(
        title: 'Course Offer List - ${AppConfig.currentTerm}',
        filename: 'offer_list_sem$_semester.pdf',
        subtitle: ['CSE Semester $_semester'],
        headers: ['Section', 'Course', 'Title', 'Cr', 'Seats', 'Taken'],
        rows: [
          for (final s in _loaded)
            [
              'Section ${s.groupNo}',
              s.fullLabel,
              s.title,
              Formatters.credits(s.credits),
              '${s.capacity}',
              '${s.enrolled}',
            ],
        ],
        columnFlex: {0: 1, 1: 1.6, 2: 3.4, 3: 0.5, 4: 0.6, 5: 0.6},
      );

  @override
  Widget build(BuildContext context) {
    final catalog = Catalog.instance;
    return Scaffold(
      appBar: EduAppBar(
        title: 'Course Offer List',
        subtitle: 'CSE  |  ${AppConfig.currentTerm}',
        actions: [
          IconButton(
            tooltip: 'Download PDF (this semester)',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => runWithFeedback(context, _pdf),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              children: [
                ChoiceChipsRow<int>(
                  values: catalog.semesters,
                  selected: _semester,
                  labelOf: (s) => 'Semester $s',
                  onSelected: (s) => setState(() => _semester = s),
                ),
                const SizedBox(height: 10),
                SearchField(
                  hint: 'Search code or title',
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureView<List<CourseSection>>(
              key: ValueKey(_semester),
              load: () => context.read<ApiService>().fetchSections(semesterNo: _semester),
              builder: (context, sections, reload) {
                _loaded = sections;
                final byCourse = <String, List<CourseSection>>{};
                for (final s in sections) {
                  byCourse.putIfAbsent(s.courseCode, () => []).add(s);
                }
                final codes = byCourse.keys
                    .where((c) =>
                        _query.isEmpty ||
                        c.toLowerCase().contains(_query) ||
                        byCourse[c]!.first.title.toLowerCase().contains(_query))
                    .toList();
                final groups = sections.map((s) => s.groupNo).toSet().length;
                final credits =
                    byCourse.values.fold<double>(0, (sum, list) => sum + list.first.credits);
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Text(
                        'Semester $_semester: ${byCourse.length} courses, '
                        '${Formatters.credits(credits)} credits, $groups sections',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      for (final code in codes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CourseOffer(sections: byCourse[code]!),
                        ),
                      if (codes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No course matches.', textAlign: TextAlign.center),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseOffer extends StatelessWidget {
  const _CourseOffer({required this.sections});

  final List<CourseSection> sections;

  @override
  Widget build(BuildContext context) {
    final first = sections.first;
    final free = sections.fold<int>(0, (sum, s) => sum + s.seatsLeft);
    final total = sections.fold<int>(0, (sum, s) => sum + s.capacity);
    final prereq = Catalog.instance.prerequisitesOf(first.courseCode);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          title: Row(
            children: [
              Text(first.courseCode,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(width: 8),
              Text('${Formatters.credits(first.credits)} cr',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(first.title, style: const TextStyle(color: AppColors.text)),
              Text('${sections.length} sections  |  $free of $total seats free'
                  '${prereq.isEmpty ? '' : '  |  Prereq: ${prereq.join(', ')}'}',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
          children: [
            for (final s in sections)
              ListTile(
                dense: true,
                title: Text('Section ${s.groupNo}:  ${s.fullLabel}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: SeatBadge(s),
              ),
          ],
        ),
      ),
    );
  }
}
