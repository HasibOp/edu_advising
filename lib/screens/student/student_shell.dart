import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/advising_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/edu_app_bar.dart';
import 'home_screen.dart';
import 'menu_screen.dart';

/// Student app: bottom tabs Home and Menu only. Everything else is opened
/// from the Menu (or from cards on Home).
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) context.read<AdvisingProvider>().load(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EduAppBar(brand: true, title: _tab == 0 ? 'Student Portal' : 'Menu'),
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(onOpenMenu: () => setState(() => _tab = 1)),
          const MenuScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Menu'),
        ],
      ),
    );
  }
}
