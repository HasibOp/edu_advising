import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/state_views.dart';

class AppConfig {
  AppConfig._();

  static const String universityName = 'East Delta University';
  static const String appName = 'EDU Advising';
  static const String currentTerm = 'Fall 2026';

  static const int theoryRoomCapacity = 35;
  static const int labRoomCapacity = 28;

  static const String deanShortForm = 'Dr. MK';
}

class AppLinks {
  AppLinks._();

  static const String clearancePortal =
      'https://script.google.com/a/macros/eastdelta.edu.bd/s/AKfycbyPL1HH3zhebxY5TAQ9Mg8FhnoMpcmTxd7LeKP7pfbzlqdJhlOUqPn58i1WBY807qZh/exec';
  static const String advisingInfoPortal = 'https://advising.eastdelta.edu.bd';
  static const String ePaymentPortal = 'https://epayment.eastdelta.edu.bd';

  static const String uploadDepositForm =
      'https://docs.google.com/forms/d/e/1FAIpQLSceCK_OXxBy7L4lWUthfKzxx2b28H2T5CKdYbsvnwktX_WIoQ/viewform?pli=1';

  static Future<void> open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
        .catchError((_) => false);
    if (!ok && context.mounted) {
      showAppSnackBar(context, 'Could not open $url', isError: true);
    }
  }
}
