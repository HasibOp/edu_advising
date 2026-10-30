import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../widgets/edu_app_bar.dart';
import '../student/menu_screen.dart';
import 'dean_panel_screen.dart';
import 'my_courses_screen.dart';
import 'requests_screen.dart';
import 'student_search_screen.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) context.read<StaffProvider>().load(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final staff = context.watch<StaffProvider>();
    final isDean = user?.isDean ?? false;

    final pages = <(String, NavigationDestination, Widget)>[
      (
        'My courses',
        const NavigationDestination(
            icon: Icon(Icons.class_outlined), selectedIcon: Icon(Icons.class_), label: 'Courses'),
        const MyCoursesScreen(),
      ),
      (
        'Student search',
        const NavigationDestination(
            icon: Icon(Icons.person_search_outlined),
            selectedIcon: Icon(Icons.person_search),
            label: 'Students'),
        const StudentSearchScreen(),
      ),
      (
        'Requests',
        NavigationDestination(
          icon: Badge(
            isLabelVisible: staff.pendingCount > 0,
            label: Text('${staff.pendingCount}'),
            child: const Icon(Icons.inbox_outlined),
          ),
          selectedIcon: const Icon(Icons.inbox),
          label: 'Requests',
        ),
        const RequestsScreen(),
      ),
      if (isDean)
        (
          'Dean panel',
          const NavigationDestination(
              icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Dean'),
          const DeanPanelScreen(),
        ),
      (
        'More',
        const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'More'),
        MenuList(groups: [
          (
            'Reference',
            [
              for (final group in MenuScreen.groups)
                for (final item in group.$2)
                  if (const ['Course offer list', 'Class routine', 'Exam routine',
                          'Prerequisite checker', 'Faculty directory', 'Notice board', 'FAQ chatbot']
                      .contains(item.title))
                    item,
            ],
          ),
        ]),
      ),
    ];
    if (_tab >= pages.length) _tab = 0;

    return Scaffold(
      appBar: EduAppBar(
        brand: true,
        title: '${isDean ? 'Dean' : 'Instructor'} Panel  |  ${pages[_tab].$1}',
      ),
      body: IndexedStack(index: _tab, children: [for (final p in pages) p.$3]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [for (final p in pages) p.$2],
      ),
    );
  }
}
