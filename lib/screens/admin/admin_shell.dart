import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/edu_app_bar.dart';
import '../common/audit_log_screen.dart';
import 'clearance_list_screen.dart';
import 'content_manager_screen.dart';
import 'courses_manager_screen.dart';
import 'windows_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  static const _titles = ['Clearance list', 'Advising windows', 'Notices & FAQ', 'Courses & sections', 'Audit log'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) context.read<AdminProvider>().load(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EduAppBar(brand: true, title: 'Admin Panel  |  ${_titles[_tab]}'),
      body: IndexedStack(
        index: _tab,
        children: const [
          ClearanceListScreen(),
          WindowsScreen(),
          ContentManagerScreen(),
          CoursesManagerScreen(),
          AuditLogView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.verified_user_outlined),
              selectedIcon: Icon(Icons.verified_user),
              label: 'Clearance'),
          NavigationDestination(
              icon: Icon(Icons.toggle_off_outlined),
              selectedIcon: Icon(Icons.toggle_on),
              label: 'Windows'),
          NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign),
              label: 'Content'),
          NavigationDestination(
              icon: Icon(Icons.library_books_outlined),
              selectedIcon: Icon(Icons.library_books),
              label: 'Courses'),
          NavigationDestination(
              icon: Icon(Icons.history_edu_outlined),
              selectedIcon: Icon(Icons.history_edu),
              label: 'Audit'),
        ],
      ),
    );
  }
}
