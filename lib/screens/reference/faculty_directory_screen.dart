import 'package:flutter/material.dart';

import '../../services/catalog.dart';
import '../../utils/app_theme.dart';
import '../../utils/pdf_export.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';

/// The 55 SoSET faculty, searchable by name or short form.
class FacultyDirectoryScreen extends StatefulWidget {
  const FacultyDirectoryScreen({super.key});

  @override
  State<FacultyDirectoryScreen> createState() => _FacultyDirectoryScreenState();
}

class _FacultyDirectoryScreenState extends State<FacultyDirectoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = Catalog.instance.faculty;
    final list = all
        .where((f) =>
            _query.isEmpty ||
            f.name.toLowerCase().contains(_query) ||
            f.shortForm.toLowerCase().contains(_query))
        .toList();
    return Scaffold(
      appBar: EduAppBar(
        title: 'Faculty Directory',
        subtitle: '${all.length} faculty members',
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => runWithFeedback(
              context,
              () => PdfExport.shareTable(
                title: 'Faculty Directory',
                filename: 'faculty_directory.pdf',
                subtitle: ['${list.length} faculty members'],
                headers: ['Short form', 'Name', 'Position', 'Email', 'Phone'],
                rows: [
                  for (final f in list) [f.shortForm, f.name, f.position, f.email, f.phone],
                ],
                columnFlex: {0: 1, 1: 2.6, 2: 1.2, 3: 1.2, 4: 1.2},
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: SearchField(
              hint: 'Search name or short form (e.g. TRINA)',
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No faculty found'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final f = list[i];
                      return AppCard(
                        padding: const EdgeInsets.all(12),
                        onTap: () => _details(context, f),
                        child: Row(
                          children: [
                            Avatar(f.initials, size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(f.shortForm,
                                      style: const TextStyle(
                                          color: AppColors.primary, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textMuted),
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

  void _details(BuildContext context, Faculty f) {
    final taught = Catalog.instance.sectionsTaughtBy(f.shortForm)
      ..sort((a, b) {
        final c = a.$1.compareTo(b.$1);
        return c != 0 ? c : a.$2.compareTo(b.$2);
      });
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              children: [
                Avatar(f.initials, size: 60),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(f.shortForm,
                          style: const TextStyle(
                              color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            InfoRow('Position', f.position),
            InfoRow('Department', f.department),
            InfoRow('Email', f.email),
            InfoRow('Phone', f.phone),
            const SizedBox(height: 12),
            Text('Fall 2026 sections (${taught.length})',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 8),
            if (taught.isEmpty)
              const Text('No CSE classes in the routine.',
                  style: TextStyle(color: AppColors.textMuted))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (code, no) in taught)
                    Tooltip(
                      message: Catalog.instance.titleOf(code),
                      child: Chip(label: Text('$code.$no')),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
