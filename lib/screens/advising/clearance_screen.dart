import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/student.dart';
import '../../providers/advising_provider.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/clearance_card.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';
import 'advising_screen.dart';

class ClearanceScreen extends StatelessWidget {
  const ClearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final advising = context.watch<AdvisingProvider>();
    final student = advising.student;
    return Scaffold(
      appBar: const EduAppBar(title: 'Advising', subtitle: 'Accounts clearance check'),
      body: student == null
          ? (advising.isLoading
              ? const LoadingView()
              : ErrorView(message: advising.error ?? 'Not loaded', onRetry: advising.refresh))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: advising.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  const Text(
                    '${AppConfig.currentTerm} Advising: Accounts Clearance Status',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.info, fontSize: 16.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  ClearanceResultCard(student: student),
                  const SizedBox(height: 14),
                  _details(student),
                  const SizedBox(height: 14),
                  _status(advising),
                  const SizedBox(height: 16),
                  if (student.clearanceStatus.canAdvise)
                    FilledButton.icon(
                      onPressed: () => openPage(context, const AdvisingScreen()),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(student.advisingDone ? 'Go to Advising' : 'Proceed to Advising'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(52),
                        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                      ),
                    )
                  else ...[
                    const NoticeBanner(
                      title: 'Advising is locked',
                      color: AppColors.danger,
                      icon: Icons.lock_outline,
                      message: 'What to do:\n'
                          '1. Pay your dues through the E-payment Portal, or pay at the bank.\n'
                          '2. If you paid at the bank, upload the deposit slip with the Upload '
                          'Deposit Form.\n'
                          '3. Wait 15-30 minutes, then pull down to check again.\n'
                          'If you have a special case, contact the Accounts office.',
                    ),
                    const SizedBox(height: 12),
                    const FilledButton(
                      onPressed: null,
                      child: Text('Proceed to Advising'),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const PortalLinksBox(),
                ],
              ),
            ),
    );
  }

  Widget _details(Student s) {
    return AppCard(
      child: Column(
        children: [
          InfoRow('Clearance', s.clearanceStatus.label,
              valueColor: s.clearanceStatus.canAdvise ? AppColors.success : AppColors.danger,
              bold: true),
          InfoRow('How', s.clearanceType.label),
          InfoRow('Paid this semester', Formatters.money(s.paidAmount)),
          InfoRow('Dues', Formatters.money(s.dues),
              valueColor: s.dues > 0 ? AppColors.danger : AppColors.success),
          if (s.specialConsideration)
            InfoRow('Required for special consideration', Formatters.money(s.requiredAmount)),
        ],
      ),
    );
  }

  Widget _status(AdvisingProvider a) {
    final s = a.student!;
    Widget row(IconData icon, String label, bool ok, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: ok ? AppColors.success : AppColors.warning),
              const SizedBox(width: 10),
              Expanded(child: Text(label)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ok ? AppColors.success : AppColors.warning)),
              ),
            ],
          ),
        );
    final w = a.windows;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(Icons.assignment_turned_in_outlined, 'Your advising', s.advisingDone,
              s.advisingDone ? 'Done (Section ${s.lockedGroup})' : 'Not done'),
          row(Icons.event_available_outlined, 'Regular advising window', a.regularOpen,
              a.regularOpen ? 'Open' : 'Closed'),
          row(Icons.add_task, 'Extra course window', a.extraOpen, a.extraOpen ? 'Open' : 'Closed'),
          if (w?.closesAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Advising closes ${Formatters.dateTime(w!.closesAt!)}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            ),
        ],
      ),
    );
  }
}
