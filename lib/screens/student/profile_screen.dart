import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/student.dart';
import '../../providers/advising_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AdvisingProvider>().student;
    return Scaffold(
      appBar: EduAppBar(
        title: 'My Profile',
        actions: [
          if (student != null)
            IconButton(
              tooltip: 'Edit contact details',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context, student),
            ),
        ],
      ),
      body: student == null
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Center(
                  child: Stack(
                    children: [
                      Avatar(student.initials, size: 96),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: AppColors.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => showAppSnackBar(context,
                                'Photo upload will use Firebase Storage in the backend phase.'),
                            child: const Padding(
                              padding: EdgeInsets.all(7),
                              child: Icon(Icons.photo_camera_outlined, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(student.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                Center(
                  child: Text('${student.id}  |  ${student.dept}',
                      style: const TextStyle(color: AppColors.textMuted)),
                ),
                const SizedBox(height: 8),
                Center(child: ClearanceBadge(student.clearanceStatus)),
                const SectionHeader('Academic'),
                AppCard(
                  child: Column(children: [
                    InfoRow('Student ID', student.id),
                    const InfoRow('Department', 'Computer Science & Engineering'),
                    InfoRow('Current semester', 'Semester ${student.semesterNo}'),
                    InfoRow('Batch (admitted)', student.batch),
                    InfoRow('CGPA', student.cgpa.toStringAsFixed(2), bold: true),
                    InfoRow('Credits completed', Formatters.credits(student.creditsDone)),
                  ]),
                ),
                const SectionHeader('Personal'),
                AppCard(
                  child: Column(children: [
                    InfoRow('Date of birth', student.dob),
                    InfoRow('Blood group', student.bloodGroup),
                    InfoRow("Father's name", student.fatherName),
                    InfoRow("Mother's name", student.motherName),
                  ]),
                ),
                SectionHeader(
                  'Contact',
                  trailing: TextButton.icon(
                    onPressed: () => _edit(context, student),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                AppCard(
                  child: Column(children: [
                    InfoRow('Phone', student.phone),
                    InfoRow('Email', student.email),
                    InfoRow('Present address', student.presentAddress),
                    InfoRow('Permanent address', student.permanentAddress),
                    InfoRow('Emergency contact', student.emergencyContact),
                  ]),
                ),
              ],
            ),
    );
  }

  Future<void> _edit(BuildContext context, Student student) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ContactForm(student: student),
    );
  }
}

class _ContactForm extends StatefulWidget {
  const _ContactForm({required this.student});

  final Student student;

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.student.phone);
  late final _email = TextEditingController(text: widget.student.email);
  late final _address = TextEditingController(text: widget.student.presentAddress);
  late final _emergency = TextEditingController(text: widget.student.emergencyContact);
  bool _saving = false;

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _emergency.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await runWithFeedback(
      context,
      () => context.read<AdvisingProvider>().updateContact(
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            presentAddress: _address.text.trim(),
            emergencyContact: _emergency.text.trim(),
          ),
      success: 'Contact details saved',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label, IconData icon) =>
        InputDecoration(labelText: label, prefixIcon: Icon(icon));
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Edit contact details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.text),
              decoration: deco('Phone', Icons.phone_outlined),
              validator: (v) => RegExp(r'^01\d{9}$').hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Enter an 11-digit number starting with 01',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.text),
              decoration: deco('Email', Icons.email_outlined),
              validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Enter a valid email',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              style: const TextStyle(color: AppColors.text),
              decoration: deco('Present address', Icons.home_outlined),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergency,
              style: const TextStyle(color: AppColors.text),
              decoration: deco('Emergency contact', Icons.contact_phone_outlined),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
