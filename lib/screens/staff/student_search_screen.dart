import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/demo_data.dart';
import '../../models/student.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/clearance_card.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';
import 'staff_advise_screen.dart';

/// Search a student by ID -> clearance page -> start advising.
class StudentSearchScreen extends StatefulWidget {
  const StudentSearchScreen({super.key});

  @override
  State<StudentSearchScreen> createState() => _StudentSearchScreenState();
}

class _StudentSearchScreenState extends State<StudentSearchScreen> {
  final _id = TextEditingController();
  Student? _student;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  Future<void> _search([String? id]) async {
    if (id != null) _id.text = id;
    final value = _id.text.trim();
    if (value.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await context.read<ApiService>().fetchStudent(value);
      setState(() => _student = s);
    } catch (e) {
      setState(() {
        _student = null;
        _error = errorText(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final s = _student;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text('Enter Student ID',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _id,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.text),
                onSubmitted: (_) => _search(),
                decoration: const InputDecoration(
                  hintText: 'e.g. 233000004',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _loading ? null : _search,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success, minimumSize: const Size(90, 50)),
              child: Text(_loading ? '...' : 'Search'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final d in kDemoStudents.take(8))
              ActionChip(
                label: Text(d.id, style: const TextStyle(fontSize: 12)),
                onPressed: () => _search(d.id),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (_error != null)
          NoticeBanner(message: _error!, color: AppColors.danger, icon: Icons.error_outline),
        if (s != null) ...[
          ClearanceResultCard(student: s),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                InfoRow('Semester', '${s.semesterNo}'),
                InfoRow('CGPA', s.cgpa.toStringAsFixed(2)),
                InfoRow('Credits completed', Formatters.credits(s.creditsDone)),
                InfoRow('Clearance', '${s.clearanceStatus.label} (${s.clearanceType.label})'),
                InfoRow('Advising', s.advisingDone ? 'Done (Section ${s.lockedGroup})' : 'Not done'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!s.clearanceStatus.canAdvise && user.isDean)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: NoticeBanner(
                color: AppColors.warning,
                icon: Icons.shield_outlined,
                title: 'Dean bypass',
                message: 'This student is Not cleared. As Dean you can still advise; '
                    'every bypass is written to the audit log.',
              ),
            ),
          FilledButton.icon(
            onPressed: s.clearanceStatus.canAdvise || user.isDean
                ? () async {
                    await openPage(context, StaffAdviseScreen(studentId: s.id));
                    _search();
                  }
                : null,
            icon: const Icon(Icons.how_to_reg),
            label: Text(s.clearanceStatus.canAdvise || user.isDean
                ? 'Start advising for this student'
                : 'Not cleared: only the Dean can advise'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ],
    );
  }
}
