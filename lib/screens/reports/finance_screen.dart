import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/portal.dart';
import '../../providers/advising_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_export.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';

/// Fees, payments and dues. Payments are recorded by Accounts; there is no
/// payment gateway in the app.
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AdvisingProvider>().student;
    return Scaffold(
      appBar: const EduAppBar(title: 'Finance Summary', subtitle: AppConfig.currentTerm),
      body: student == null
          ? const LoadingView()
          : FutureView<FinanceSummary>(
              load: () => context.read<ApiService>().fetchFinance(student.id),
              builder: (context, f, _) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Current dues',
                                  style: TextStyle(color: AppColors.textMuted)),
                            ),
                            ClearanceBadge(student.clearanceStatus),
                          ],
                        ),
                        Text(Formatters.money(f.dues),
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: f.dues > 0 ? AppColors.danger : AppColors.success)),
                        const Divider(height: 24),
                        InfoRow('Semester fee', Formatters.money(f.semesterFee)),
                        InfoRow('Waiver / scholarship', '- ${Formatters.money(f.waiver)}'),
                        InfoRow('Previous dues', Formatters.money(f.previousDues)),
                        InfoRow('Total payable', Formatters.money(f.totalPayable), bold: true),
                        InfoRow('Paid', Formatters.money(f.paid), valueColor: AppColors.success),
                        if (f.requiredAmount > 0)
                          InfoRow('Required for special consideration',
                              Formatters.money(f.requiredAmount)),
                      ],
                    ),
                  ),
                  const SectionHeader('Payments recorded by Accounts'),
                  if (f.payments.isEmpty)
                    const AppCard(
                      child: Text('No payments recorded yet.',
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                  for (final p in f.payments)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              p.type == 'E-payment'
                                  ? Icons.phone_android_outlined
                                  : Icons.account_balance_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.type, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('${Formatters.date(p.date)}  |  Txn ${p.txnId}',
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.textMuted)),
                                  Text('Verified by ${p.verifiedBy}',
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Text(Formatters.money(p.amount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, color: AppColors.success)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => AppLinks.open(context, AppLinks.ePaymentPortal),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('E-payment'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => runWithFeedback(
                            context,
                            () => PdfExport.shareTable(
                              title: 'Finance Summary - ${AppConfig.currentTerm}',
                              filename: 'finance_${student.id}.pdf',
                              subtitle: ['${student.name}   |   ID ${student.id}'],
                              headers: ['Item', 'Amount'],
                              rows: [
                                ['Semester fee', Formatters.money(f.semesterFee)],
                                ['Waiver / scholarship', '- ${Formatters.money(f.waiver)}'],
                                ['Previous dues', Formatters.money(f.previousDues)],
                                ['Total payable', Formatters.money(f.totalPayable)],
                                for (final p in f.payments)
                                  ['Paid ${Formatters.date(p.date)} (${p.type}, ${p.txnId})',
                                      Formatters.money(p.amount)],
                                ['Dues', Formatters.money(f.dues)],
                              ],
                            ),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                          label: const Text('PDF'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Payments are checked by the Accounts office outside the app. '
                    'There is no payment gateway in EDU Advising.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
    );
  }
}
