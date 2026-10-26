import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/extra_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/state_views.dart';

/// Extra course requests for the faculty's own courses (Dean: all).
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  bool _pending = true;

  Future<void> _decide(ExtraRequest r, bool approve) async {
    final comment = await textInputDialog(
      context,
      title: '${approve ? 'Approve' : 'Reject'} ${r.kind.label.toLowerCase()} request',
      message: '${r.studentName} (${r.studentId})\n${r.sectionLabel}  ${r.title}',
      label: 'Comment (optional)',
      confirmLabel: approve ? 'Approve' : 'Reject',
      destructive: !approve,
      keyboardType: TextInputType.multiline,
    );
    if (comment == null || !mounted) return;
    await runWithFeedback(
      context,
      () => context.read<StaffProvider>().decide(r.id, approve, comment),
      success: approve
          ? (r.kind == RequestKind.add ? 'Approved: student enrolled' : 'Approved: course dropped')
          : 'Request rejected',
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffProvider>();
    final user = context.watch<AuthProvider>().user!;
    if (staff.isLoading) return const LoadingView();
    final list = staff.requests.where((r) => r.isPending == _pending).toList();
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: staff.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Text(user.isDean ? 'All extra course requests' : 'Requests for your courses',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text('Pending (${staff.pendingCount})')),
              ButtonSegment(
                  value: false,
                  label: Text('Decided (${staff.requests.length - staff.pendingCount})')),
            ],
            selected: {_pending},
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.tint,
              selectedForegroundColor: AppColors.primary,
            ),
            onSelectionChanged: (v) => setState(() => _pending = v.first),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            EmptyState(
              icon: Icons.inbox_outlined,
              title: _pending ? 'No pending requests' : 'Nothing decided yet',
            ),
          for (final r in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusPill(r.kind.label.toUpperCase(),
                            color: r.kind == RequestKind.add ? AppColors.info : AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r.sectionLabel,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ),
                        RequestStatusPill(r.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(r.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text('${r.studentName}  (${r.studentId})',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Reason: ${r.reason.label}',
                        style: const TextStyle(fontSize: 13)),
                    if (r.comment.isNotEmpty)
                      Text('"${r.comment}"',
                          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                    Text('Sent ${Formatters.timeAgo(r.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    if (r.decidedBy != null)
                      Text(
                        '${r.status.label} by ${r.decidedBy}'
                        '${r.facultyComment == null ? '' : ': ${r.facultyComment}'}',
                        style: TextStyle(fontSize: 12.5, color: requestColor(r.status)),
                      ),
                    if (r.isPending) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _decide(r, false),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _decide(r, true),
                              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
