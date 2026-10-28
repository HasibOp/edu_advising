import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));
}

/// Centered icon + message, with an optional action (e.g. retry).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(color: AppColors.tint, shape: BoxShape.circle),
              child: Icon(icon, size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted)),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'Something went wrong',
      message: message,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
    );
  }
}

/// Loads data once (and again on [reload]) and shows loading / error states.
class FutureView<T> extends StatefulWidget {
  const FutureView({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;

  @override
  State<FutureView<T>> createState() => _FutureViewState<T>();
}

class _FutureViewState<T> extends State<FutureView<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await widget.load();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null && _data == null) {
      return ErrorView(message: errorText(_error!), onRetry: _reload);
    }
    return widget.builder(context, _data as T, _reload);
  }
}

String errorText(Object error) =>
    error is ApiException ? error.message : 'Unexpected error: $error';

/// Bold section title with an optional trailing widget (count, button).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.padding});

  final String title;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
    ));
}

/// Runs [action], shows [success] or the error message in a snack bar.
/// Returns true when it worked.
Future<bool> runWithFeedback(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) showAppSnackBar(context, success);
    return true;
  } catch (e) {
    if (context.mounted) showAppSnackBar(context, errorText(e), isError: true);
    return false;
  }
}

/// Warns about class-time or exam-day clashes. Resolves to true only when the
/// user chooses to take the courses anyway.
Future<bool> conflictDialog(BuildContext context, List<String> conflicts) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 44),
      title: const Text('Clash found'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in conflicts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 7, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            const Text('You can still take these courses if you accept the clash. '
                'It is your decision.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Go back')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Take anyway'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Runs [action]. If it throws a [ConflictException], shows the clashes and,
/// when the user accepts, runs it again with `acceptConflicts: true`.
/// Returns null when the user goes back instead.
Future<T?> runAllowingConflicts<T>(
  BuildContext context,
  Future<T> Function(bool acceptConflicts) action,
) async {
  try {
    return await action(false);
  } on ConflictException catch (e) {
    if (!context.mounted) return null;
    if (!await conflictDialog(context, e.conflicts)) return null;
    return action(true);
  }
}

/// Yes/no dialog. Resolves to true only when the user confirms.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? AppColors.danger : AppColors.primary,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Dialog with one text field. Returns null when cancelled.
Future<String?> textInputDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  String initial = '',
  String? message,
  bool required = false,
  TextInputType keyboardType = TextInputType.text,
  bool destructive = false,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[Text(message), const SizedBox(height: 14)],
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: keyboardType,
              maxLines: keyboardType == TextInputType.multiline ? 3 : 1,
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(labelText: label),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? AppColors.danger : AppColors.primary,
            ),
            onPressed: required && controller.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
}
