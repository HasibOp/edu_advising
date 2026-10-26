import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/portal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/state_views.dart';

/// Notices manager and FAQ manager (create, edit, delete).
class ContentManagerScreen extends StatelessWidget {
  const ContentManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(tabs: [Tab(text: 'Notices'), Tab(text: 'FAQ')]),
          ),
          Expanded(child: TabBarView(children: [_NoticesTab(), _FaqTab()])),
        ],
      ),
    );
  }
}

const List<String> _noticeCategories = ['Advising', 'Accounts', 'Academic', 'Exam', 'General'];

class _NoticesTab extends StatefulWidget {
  const _NoticesTab();

  @override
  State<_NoticesTab> createState() => _NoticesTabState();
}

class _NoticesTabState extends State<_NoticesTab> {
  Key _key = UniqueKey();

  Future<void> _edit([Notice? notice]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NoticeForm(notice: notice),
    );
    if (saved == true && mounted) {
      setState(() => _key = UniqueKey());
      context.read<NotificationProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    final user = context.read<AuthProvider>().user!;
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _edit(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New notice'),
      ),
      body: FutureView<List<Notice>>(
        key: _key,
        load: api.fetchNotices,
        builder: (context, notices, reload) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
          children: [
            if (notices.isEmpty) const EmptyState(icon: Icons.campaign_outlined, title: 'No notices'),
            for (final n in notices)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StatusPill(n.category, color: AppColors.primary),
                                if (n.pinned) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.push_pin, size: 16, color: AppColors.warning),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(n.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                            Text(Formatters.dateTime(n.createdAt),
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(n),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () async {
                          final ok = await confirmDialog(context,
                              title: 'Delete notice?',
                              message: n.title,
                              confirmLabel: 'Delete',
                              destructive: true);
                          if (!ok || !context.mounted) return;
                          await runWithFeedback(context, () => api.deleteNotice(user, n.id),
                              success: 'Notice deleted');
                          await reload();
                          if (context.mounted) context.read<NotificationProvider>().refresh();
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoticeForm extends StatefulWidget {
  const _NoticeForm({this.notice});

  final Notice? notice;

  @override
  State<_NoticeForm> createState() => _NoticeFormState();
}

class _NoticeFormState extends State<_NoticeForm> {
  late final _title = TextEditingController(text: widget.notice?.title);
  late final _body = TextEditingController(text: widget.notice?.body);
  late String _category = widget.notice?.category ?? 'Advising';
  late bool _pinned = widget.notice?.pinned ?? false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = context.read<AuthProvider>().user!;
    final notice = Notice(
      id: widget.notice?.id ?? '',
      title: _title.text,
      body: _body.text,
      category: _category,
      pinned: _pinned,
      createdAt: widget.notice?.createdAt ?? DateTime.now(),
    );
    final ok = await runWithFeedback(
      context,
      () => context.read<ApiService>().saveNotice(user, notice),
      success: widget.notice == null ? 'Notice posted' : 'Notice updated',
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.notice == null ? 'New notice' : 'Edit notice',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _body,
              maxLines: 5,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in _noticeCategories) DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _pinned,
              activeTrackColor: AppColors.primary,
              title: const Text('Pin to the top'),
              onChanged: (v) => setState(() => _pinned = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTab extends StatefulWidget {
  const _FaqTab();

  @override
  State<_FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<_FaqTab> {
  Key _key = UniqueKey();

  Future<void> _edit([Faq? faq]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FaqForm(faq: faq),
    );
    if (saved == true && mounted) setState(() => _key = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    final user = context.read<AuthProvider>().user!;
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _edit(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New FAQ'),
      ),
      body: FutureView<List<Faq>>(
        key: _key,
        load: api.fetchFaqs,
        builder: (context, faqs, reload) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
          children: [
            for (final f in faqs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.question, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(f.answer,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                            Text('${f.category}  |  ${f.keywords.join(', ')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, color: AppColors.primary)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(f)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () async {
                          final ok = await confirmDialog(context,
                              title: 'Delete FAQ?',
                              message: f.question,
                              confirmLabel: 'Delete',
                              destructive: true);
                          if (!ok || !context.mounted) return;
                          await runWithFeedback(context, () => api.deleteFaq(user, f.id),
                              success: 'FAQ deleted');
                          await reload();
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FaqForm extends StatefulWidget {
  const _FaqForm({this.faq});

  final Faq? faq;

  @override
  State<_FaqForm> createState() => _FaqFormState();
}

class _FaqFormState extends State<_FaqForm> {
  late final _question = TextEditingController(text: widget.faq?.question);
  late final _answer = TextEditingController(text: widget.faq?.answer);
  late final _keywords = TextEditingController(text: widget.faq?.keywords.join(', '));
  late String _category = widget.faq?.category ?? 'Advising';

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    _keywords.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = context.read<AuthProvider>().user!;
    final faq = Faq(
      id: widget.faq?.id ?? '',
      question: _question.text,
      answer: _answer.text,
      category: _category,
      keywords: _keywords.text
          .split(',')
          .map((k) => k.trim().toLowerCase())
          .where((k) => k.isNotEmpty)
          .toList(),
    );
    final ok = await runWithFeedback(
      context,
      () => context.read<ApiService>().saveFaq(user, faq),
      success: widget.faq == null ? 'FAQ added' : 'FAQ updated',
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.faq == null ? 'New FAQ' : 'Edit FAQ',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
              controller: _question,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(labelText: 'Question'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _answer,
              maxLines: 4,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(labelText: 'Answer'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _keywords,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(
                labelText: 'Keywords (comma separated)',
                hintText: 'waitlist, full, seat',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in _noticeCategories) DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
