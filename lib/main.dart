import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/admin_provider.dart';
import 'providers/advising_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/staff_provider.dart';
import 'screens/login/login_screen.dart';
import 'services/api_service.dart';
import 'services/mock_api_service.dart';
import 'utils/app_config.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(EduAdvisingApp(api: MockApiService()));
}

class EduAdvisingApp extends StatelessWidget {
  const EduAdvisingApp({super.key, required this.api});

  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthProvider(api)),
        ChangeNotifierProvider(create: (_) => AdvisingProvider(api)),
        ChangeNotifierProvider(create: (_) => StaffProvider(api)),
        ChangeNotifierProvider(create: (_) => AdminProvider(api)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(api)),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        home: const LoginScreen(),
      ),
    );
  }
}
