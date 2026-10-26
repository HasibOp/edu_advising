import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/portal.dart';
import '../../providers/staff_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';
import '../common/audit_log_screen.dart';
import 'my_courses_screen.dart';
import 'section_detail_screen.dart';

/// Dean extras: overview, seats of every section, audit log.
class DeanPanelScreen extends StatefulWidget {
  const DeanPanelScreen({super.key});

  @override
  State<DeanPanelScreen> createState() => _DeanPanelScreenState();
}

class _DeanPanelScreenState extends State<DeanPanelScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffProvider>();
    final all = staff.allSections;
    final matches = _query.length < 3
        ? const []
        : all
            .where((s) =>
                s.fullLabel.toLowerCase().contains(_query) ||
                s.title.toLowerCase().contains(_query))
            .take(30)
            .toList();
    final full = all.where((s) => s.isFull).length;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: staff.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const NoticeBanner(
            color: AppColors.primary,
            icon: Icons.shield_outlined,
            title: 'Dean tools',
            message: 'You can add or drop any course for any student (Students tab), advise '
                'without clearance (logged), decide every request, and change the seats of '
                'every section.',
          ),
          const SizedBox(height: 12),
          FutureView<List<AuditLog>>(
            load: () => context.read<ApiService>().fetchAuditLogs(),
            builder: (context, logs, _) {
              final bypasses = logs.where((l) => l.bypassedClearance).length;
              return Row(
                children: [
                  Expanded(child: StatTile(value: '${all.length}', label: 'Sections')),
                  const SizedBox(width: 8),
                  Expanded(
                      child: StatTile(
                          value: '$full', label: 'Full sections', color: AppColors.danger)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: StatTile(
                          value: '${staff.pendingCount}',
                          label: 'Pending requests',
                          color: AppColors.warning)),
                  const SizedBox(width: 8),
                  Expanded(child: StatTile(value: '$bypasses', label: 'Clearance bypasses')),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => openPage(context, const AuditLogScreen()),
            child: const Row(
              children: [
                Icon(Icons.history_edu_outlined, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Audit log',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
          const SectionHeader('Seats of any section'),
          SearchField(
            hint: 'Type at least 3 letters, e.g. CSE 443',
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 10),
          for (final s in matches)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: SectionTile(section: s)),
                  IconButton(
                    tooltip: 'Change seats',
                    icon: const Icon(Icons.event_seat_outlined, color: AppColors.primary),
                    onPressed: () => changeSeatsDialog(context, s),
                  ),
                ],
              ),
            ),
          if (_query.length >= 3 && matches.isEmpty)
            const Text('No section matches.', style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
