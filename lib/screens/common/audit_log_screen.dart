import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/portal.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_export.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: EduAppBar(title: 'Audit Log'),
      body: AuditLogView(),
    );
  }
}

class AuditLogView extends StatefulWidget {
  const AuditLogView({super.key});

  @override
  State<AuditLogView> createState() => _AuditLogViewState();
}

class _AuditLogViewState extends State<AuditLogView> {
  static const Map<String, List<AuditAction>> _filters = {
    'Advising': [
      AuditAction.enroll,
      AuditAction.addByFaculty,
      AuditAction.dropByFaculty,
      AuditAction.waitlistJoin,
      AuditAction.waitlistPromote,
    ],
    'Dean bypass': [AuditAction.deanBypass],
    'Requests': [
      AuditAction.requestCreated,
      AuditAction.requestWithdrawn,
      AuditAction.requestApproved,
      AuditAction.requestRejected,
    ],
    'Clearance': [
      AuditAction.clearanceGiven,
      AuditAction.clearanceRevoked,
      AuditAction.clearanceSpecial,
    ],
    'Admin': [
      AuditAction.windowChange,
      AuditAction.seatChange,
      AuditAction.courseChange,
      AuditAction.noticeChange,
      AuditAction.faqChange,
    ],
  };

  String? _filter;
  String _query = '';

  Color _color(AuditLog l) {
    if (l.bypassedClearance || l.action == AuditAction.deanBypass) return AppColors.warning;
    if (l.action.code.contains('DROP') ||
        l.action.code.contains('REVOKED') ||
        l.action.code.contains('REJECTED')) {
      return AppColors.danger;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return FutureView<List<AuditLog>>(
      load: () => context.read<ApiService>().fetchAuditLogs(),
      builder: (context, logs, reload) {
        final shown = logs.where((l) {
          if (_filter != null && !_filters[_filter]!.contains(l.action)) return false;
          if (_query.isEmpty) return true;
          return '${l.actorId} ${l.targetId} ${l.details} ${l.action.code}'
              .toLowerCase()
              .contains(_query);
        }).toList();
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              ChoiceChipsRow<String?>(
                values: [null, ..._filters.keys],
                selected: _filter,
                labelOf: (f) => f ?? 'All',
                onSelected: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SearchField(
                      hint: 'Search ID, course, action',
                      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Download PDF',
                    icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
                    onPressed: () => runWithFeedback(
                      context,
                      () => PdfExport.shareTable(
                        title: 'Audit Log',
                        filename: 'audit_log.pdf',
                        subtitle: ['${shown.length} entries${_filter == null ? '' : ' ($_filter)'}'],
                        headers: ['Time', 'Actor', 'Role', 'Action', 'Target', 'Details'],
                        rows: [
                          for (final l in shown)
                            [
                              Formatters.dateTime(l.timestamp),
                              l.actorId,
                              l.actorRole,
                              l.action.code,
                              l.targetId,
                              '${l.details}${l.bypassedClearance ? ' [clearance bypass]' : ''}',
                            ],
                        ],
                        landscape: true,
                        columnFlex: {0: 1.5, 1: 0.9, 2: 0.9, 3: 1.5, 4: 1.6, 5: 3.2},
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('${shown.length} entries',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              const SizedBox(height: 6),
              for (final l in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  StatusPill(l.action.code, color: _color(l)),
                                  if (l.bypassedClearance)
                                    const StatusPill('BYPASS',
                                        color: AppColors.warning, solid: true),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(Formatters.timeAgo(l.timestamp),
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(l.details, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('${l.actorId} (${l.actorRole})  ->  ${l.targetId}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
