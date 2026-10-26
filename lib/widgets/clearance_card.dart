import 'package:flutter/material.dart';

import '../models/student.dart';
import '../utils/app_config.dart';
import '../utils/app_theme.dart';
import 'badges.dart';

/// Result box in the style of the university's Accounts Clearance Status
/// page: name, ID and the remark in green (allowed) or red (not cleared).
class ClearanceResultCard extends StatelessWidget {
  const ClearanceResultCard({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final status = student.clearanceStatus;
    final color = status.canAdvise ? AppColors.success : AppColors.danger;
    TextSpan line(String label, String value) => TextSpan(children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: value),
        ]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(110), width: 1.4),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Icon(clearanceIcon(status), color: color, size: 30),
              Text(status.label,
                  style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: TextStyle(color: color, fontSize: 14, height: 1.45),
              children: [
                line('Student Name', student.name),
                const TextSpan(text: '\n'),
                line('Student ID', student.id),
                const TextSpan(text: '\n'),
                line('Remarks', status.remark),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// The blue information box with the three official links.
class PortalLinksBox extends StatelessWidget {
  const PortalLinksBox({super.key});

  @override
  Widget build(BuildContext context) {
    Widget link(String lead, String rest, String label, String url) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('$lead ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.info)),
              Text('$rest ', style: const TextStyle(color: AppColors.info)),
              InkWell(
                onTap: () => AppLinks.open(context, url),
                child: Text(label,
                    style: const TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.info,
                    )),
              ),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F0FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9CC4EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          link('Get all the information', 'about scholarship, payment deadlines and FAQs from the',
              'Advising Information Portal', AppLinks.advisingInfoPortal),
          link('You can pay', 'via the', 'E-payment Portal', AppLinks.ePaymentPortal),
          link('Please upload', 'your Bank deposit slip via the', 'Upload Deposit Form',
              AppLinks.uploadDepositForm),
          link('Check', 'your status on the official', 'Accounts Clearance page',
              AppLinks.clearancePortal),
        ],
      ),
    );
  }
}
