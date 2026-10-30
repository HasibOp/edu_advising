import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/portal.dart';
import '../../providers/admin_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/state_views.dart';

class WindowsScreen extends StatelessWidget {
  const WindowsScreen({super.key});

  Future<void> _update(BuildContext context, AdvisingWindows w, String message) =>
      runWithFeedback(context, () => context.read<AdminProvider>().updateWindows(w),
          success: message);

  Future<void> _pickDate(BuildContext context, AdvisingWindows w, bool opens) async {
    final current = (opens ? w.opensAt : w.closesAt) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(current));
    if (!context.mounted) return;
    final value = DateTime(date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);
    final other = opens ? w.closesAt : w.opensAt;
    if (other != null && (opens ? value.isAfter(other) : value.isBefore(other))) {
      showAppSnackBar(
          context, opens ? 'Opening must be before closing.' : 'Closing must be after opening.',
          isError: true);
      return;
    }
    await _update(
      context,
      opens ? w.copyWith(opensAt: value) : w.copyWith(closesAt: value),
      'Date saved',
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final w = admin.windows;
    if (w == null) return const LoadingView();

    Widget toggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) =>
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.success,
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle),
            secondary: Icon(value ? Icons.lock_open_rounded : Icons.lock_outline,
                color: value ? AppColors.success : AppColors.danger),
            onChanged: onChanged,
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Semester: ${w.semester}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 12),
        toggle(
          'Regular advising',
          w.regularOpen
              ? 'OPEN: cleared students can pick sections'
              : 'CLOSED: students can only view',
          w.regularOpen,
          (v) => _update(context, w.copyWith(regularOpen: v),
              'Regular advising ${v ? 'opened' : 'closed'}'),
        ),
        const SizedBox(height: 10),
        toggle(
          'Extra course',
          w.extraOpen
              ? 'OPEN: students can request vacant seats'
              : 'CLOSED: no new extra course requests',
          w.extraOpen,
          (v) => _update(context, w.copyWith(extraOpen: v),
              'Extra course window ${v ? 'opened' : 'closed'}'),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.event_available_outlined, color: AppColors.primary),
                title: const Text('Advising opens'),
                subtitle: Text(w.opensAt == null ? 'Not set' : Formatters.dateTime(w.opensAt!)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () => _pickDate(context, w, true),
              ),
              const Divider(indent: 56),
              ListTile(
                leading: const Icon(Icons.event_busy_outlined, color: AppColors.primary),
                title: const Text('Advising closes'),
                subtitle: Text(w.closesAt == null ? 'Not set' : Formatters.dateTime(w.closesAt!)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () => _pickDate(context, w, false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const NoticeBanner(
          message: 'Switching a window takes effect at once for every student. Each change is '
              'written to the audit log. The Extra course window is normally opened after '
              'the regular advising deadline.',
        ),
      ],
    );
  }
}
