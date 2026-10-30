import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/student.dart';
import '../../providers/admin_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_export.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/state_views.dart';

class ClearanceListScreen extends StatefulWidget {
  const ClearanceListScreen({super.key});

  @override
  State<ClearanceListScreen> createState() => _ClearanceListScreenState();
}

class _ClearanceListScreenState extends State<ClearanceListScreen> {
  ClearanceStatus? _filter;
  String _query = '';

  Future<void> _set(Student s, ClearanceAction action) async {
    final label = switch (action) {
      ClearanceAction.give => 'Give clearance',
      ClearanceAction.revoke => 'Revoke clearance',
      ClearanceAction.special => 'Mark special consideration',
    };
    final ok = await confirmDialog(
      context,
      title: '$label?',
      message: '${s.name} (${s.id})\nNow: ${s.clearanceStatus.label}. '
          'The student sees the change immediately.',
      confirmLabel: label,
      destructive: action == ClearanceAction.revoke,
    );
    if (!ok || !mounted) return;
    await runWithFeedback(
      context,
      () => context.read<AdminProvider>().setClearance(s.id, action),
      success: '${s.name}: $label done',
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    if (admin.isLoading) return const LoadingView();
    if (admin.error != null) return ErrorView(message: admin.error!, onRetry: admin.refresh);
    final list = admin.students
        .where((s) => _filter == null || s.clearanceStatus == _filter)
        .where((s) =>
            _query.isEmpty || s.id.contains(_query) || s.name.toLowerCase().contains(_query))
        .toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: admin.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(
            children: [
              for (final st in ClearanceStatus.values) ...[
                Expanded(
                  child: StatTile(
                    value: '${admin.count(st)}',
                    label: st.label,
                    color: clearanceColor(st),
                  ),
                ),
                if (st != ClearanceStatus.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SearchField(
                  hint: 'Search ID or name',
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
              IconButton(
                tooltip: 'Download PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
                onPressed: () => runWithFeedback(
                  context,
                  () => PdfExport.shareTable(
                    title: 'Clearance List',
                    filename: 'clearance_list.pdf',
                    subtitle: ['${list.length} students${_filter == null ? '' : ' (${_filter!.label})'}'],
                    headers: ['ID', 'Name', 'Sem', 'Status', 'How', 'Dues'],
                    rows: [
                      for (final s in list)
                        [
                          s.id,
                          s.name,
                          '${s.semesterNo}',
                          s.clearanceStatus.label,
                          s.clearanceType.label,
                          Formatters.money(s.dues),
                        ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ChoiceChipsRow<ClearanceStatus?>(
            values: const [null, ...ClearanceStatus.values],
            selected: _filter,
            labelOf: (s) => s?.label ?? 'All',
            onSelected: (s) => setState(() => _filter = s),
          ),
          const SizedBox(height: 10),
          if (list.isEmpty) const EmptyState(icon: Icons.search_off, title: 'No students match'),
          for (final s in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(s.initials, size: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${s.id}  |  Semester ${s.semesterNo}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        ClearanceBadge(s.clearanceStatus),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${s.clearanceType.label}  |  Paid ${Formatters.money(s.paidAmount)}  |  '
                      'Dues ${Formatters.money(s.dues)}'
                      '${s.specialConsideration ? '  |  Required ${Formatters.money(s.requiredAmount)}' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (s.clearanceStatus != ClearanceStatus.special)
                          TextButton(
                            onPressed: () => _set(s, ClearanceAction.special),
                            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
                            child: const Text('Special'),
                          ),
                        if (s.clearanceStatus != ClearanceStatus.notCleared)
                          OutlinedButton(
                            onPressed: () => _set(s, ClearanceAction.revoke),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                            child: const Text('Revoke'),
                          ),
                        if (s.clearanceStatus != ClearanceStatus.cleared)
                          FilledButton(
                            onPressed: () => _set(s, ClearanceAction.give),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                            child: const Text('Give clearance'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
