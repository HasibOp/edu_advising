import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/demo_data.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../admin/admin_shell.dart';
import '../staff/staff_shell.dart';
import '../student/student_shell.dart';

/// One login page for everyone. The role selector must match the account.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.student;
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _usernameLabel => switch (_role) {
        UserRole.student => 'Student ID',
        UserRole.instructor => 'Faculty short form',
        UserRole.admin => 'Username',
      };

  String get _usernameHint => switch (_role) {
        UserRole.student => 'e.g. 233000001',
        UserRole.instructor => 'e.g. TRINA or Dr. MK',
        UserRole.admin => 'admin',
      };

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final user = await auth.login(_username.text, _password.text, _role);
    if (user == null || !mounted) return;
    context.read<NotificationProvider>().load(user);
    final Widget home = switch (user.role) {
      UserRole.student => const StudentShell(),
      UserRole.instructor => const StaffShell(),
      UserRole.admin => const AdminShell(),
    };
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => home));
  }

  void _fill(UserRole role, String username) {
    setState(() {
      _role = role;
      _username.text = username;
      _password.text = 'demo';
    });
    context.read<AuthProvider>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.deepMaroon,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const Text(AppConfig.appName,
                      style: TextStyle(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${AppConfig.universityName}  |  ${AppConfig.currentTerm}',
                      style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(width: 56, height: 3, color: AppColors.gold),
                  const SizedBox(height: 20),
                  _card(auth),
                  const SizedBox(height: 16),
                  _demoAccounts(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('assets/images/edu_logo.png', height: 92),
            const SizedBox(height: 14),
            const Text('Sign in to your portal',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 16),
            SegmentedButton<UserRole>(
              segments: const [
                ButtonSegment(
                    value: UserRole.student,
                    label: Text('Student'),
                    icon: Icon(Icons.school_outlined)),
                ButtonSegment(
                    value: UserRole.instructor,
                    label: Text('Instructor'),
                    icon: Icon(Icons.co_present_outlined)),
                ButtonSegment(
                    value: UserRole.admin,
                    label: Text('Admin'),
                    icon: Icon(Icons.admin_panel_settings_outlined)),
              ],
              selected: {_role},
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.tint,
                selectedForegroundColor: AppColors.primary,
                foregroundColor: AppColors.textMuted,
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                visualDensity: VisualDensity.compact,
              ),
              onSelectionChanged: (value) {
                setState(() => _role = value.first);
                auth.clearError();
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _username,
              style: const TextStyle(color: AppColors.text),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              keyboardType:
                  _role == UserRole.student ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                labelText: _usernameLabel,
                hintText: _usernameHint,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _obscure,
              style: const TextStyle(color: AppColors.text),
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(auth.error!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: auth.isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Sign in',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoAccounts() {
    Widget tile(UserRole role, String username, String note) => ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(
            switch (role) {
              UserRole.student => Icons.school_outlined,
              UserRole.instructor => Icons.co_present_outlined,
              UserRole.admin => Icons.admin_panel_settings_outlined,
            },
            color: AppColors.gold,
            size: 20,
          ),
          title: Text(username,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(note, style: TextStyle(color: Colors.white.withAlpha(170), fontSize: 12)),
          onTap: () => _fill(role, username),
        );

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Material(
        color: Colors.white.withAlpha(18),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withAlpha(40)),
        ),
        child: ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          title: const Text('Demo accounts (any password)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text('Tap one to fill the form',
              style: TextStyle(color: Colors.white.withAlpha(170), fontSize: 12)),
          children: [
            for (final s in kDemoStudents) tile(UserRole.student, s.id, '${s.name} - ${s.note}'),
            tile(UserRole.instructor, 'TRINA', 'Ms. Trina Chakroborty - teaches CSE 463, CSE 225'),
            tile(UserRole.instructor, 'Dr. MK', 'Dr. K.M. Mohibul Kabir - Dean tools'),
            tile(UserRole.instructor, 'MRA', 'Mr. Mohammed Morshed Rana - teaches CSE 211'),
            tile(UserRole.admin, 'admin', 'Administrator'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
