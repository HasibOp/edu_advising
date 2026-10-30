import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/extra_request.dart';
import '../../providers/advising_provider.dart';
import '../../services/api_service.dart';
import '../../services/catalog.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/state_views.dart';

class ExtraCourseTab extends StatefulWidget {
  const ExtraCourseTab({super.key});

  @override
  State<ExtraCourseTab> createState() => _ExtraCourseTabState();
}

class _ExtraCourseTabState extends State<ExtraCourseTab> {
  int? _semester;
  String _query = '';
  Key _listKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdvisingProvider>();
    final own = a.student!.semesterNo;
    final semesters = Catalog.instance.semesters.where((s) => s != own).toList();
    _semester ??= own < 11 ? own + 1 : own - 1;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await a.refresh();
        setState(() => _listKey = UniqueKey());
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (!a.extraOpen)
            const NoticeBanner(
              color: AppColors.danger,
              icon: Icons.lock_clock_outlined,
              title: 'Extra course window is closed',
              message: 'Requests open after regular advising, when the Administrator opens the '
                  'Extra course window.',
            )
          else
            const NoticeBanner(
              message: 'After regular advising, vacant seats from junior and senior semesters '
                  'can be requested. You cannot add or drop extra courses yourself: the '
                  'course faculty or the Dean approves each request.',
            ),
          if (a.requests.isNotEmpty) ...[
            const SectionHeader('My requests'),
            for (final r in a.requests)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: _RequestCard(request: r)),
          ],
          if (a.extra.isNotEmpty) ...[
            const SectionHeader('My extra courses'),
            for (final e in a.extra)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${e.label}  ${e.title}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      if (a.requestFor(e.courseCode, RequestKind.drop) case final r?)
                        RequestStatusPill(r.status)
                      else
                        TextButton(
                          onPressed: a.extraOpen
                              ? () => _openRequestSheet(context, e.sectionId, e.label, e.title,
                                  RequestKind.drop)
                              : null,
                          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                          child: const Text('Request drop'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
          const SectionHeader('Vacant sections'),
          ChoiceChipsRow<int>(
            values: semesters,
            selected: _semester,
            labelOf: (s) => 'Sem $s',
            onSelected: (s) => setState(() => _semester = s),
          ),
          const SizedBox(height: 10),
          SearchField(
            hint: 'Search course code or title',
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 10),
          FutureView<List<CourseSection>>(
            key: ValueKey('${_semester}_$_listKey'),
            load: () => context.read<ApiService>().fetchSections(semesterNo: _semester),
            builder: (context, sections, _) {
              final vacant = sections
                  .where((s) => !s.isFull)
                  .where((s) =>
                      _query.isEmpty ||
                      s.label.toLowerCase().contains(_query) ||
                      s.title.toLowerCase().contains(_query))
                  .toList()
                ..sort((x, y) {
                  final c = x.courseCode.compareTo(y.courseCode);
                  return c != 0 ? c : x.groupNo.compareTo(y.groupNo);
                });
              if (vacant.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No vacant sections match.', textAlign: TextAlign.center),
                );
              }
              return Column(
                children: [
                  for (final s in vacant)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _VacantTile(
                        section: s,
                        onRequest: () =>
                            _openRequestSheet(context, s.id, s.label, s.title, RequestKind.add),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openRequestSheet(
      BuildContext context, String sectionId, String label, String title, RequestKind kind) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RequestSheet(sectionId: sectionId, label: label, title: title, kind: kind),
    );
    if (sent == true && mounted) setState(() => _listKey = UniqueKey());
  }
}

class _VacantTile extends StatelessWidget {
  const _VacantTile({required this.section, required this.onRequest});

  final CourseSection section;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdvisingProvider>();
    final s = section;
    final request = a.requestFor(s.courseCode, RequestKind.add);
    final enrolled = a.enrollmentForCourse(s.courseCode);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.label,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                Text(s.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('${Formatters.credits(s.credits)} cr',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    SeatBadge(s),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (enrolled != null)
            const StatusPill('ENROLLED', color: AppColors.success)
          else if (request != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RequestStatusPill(request.status),
                if (request.sectionId != s.id)
                  Text(request.sectionLabel,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            )
          else
            FilledButton(
              onPressed: a.extraOpen && a.student!.clearanceStatus.canAdvise ? onRequest : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Request'),
            ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final ExtraRequest request;

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdvisingProvider>();
    final r = request;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(r.kind.label.toUpperCase(),
                  color: r.kind == RequestKind.add ? AppColors.info : AppColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${r.sectionLabel}  ${r.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              RequestStatusPill(r.status),
            ],
          ),
          const SizedBox(height: 6),
          Text('Reason: ${r.reason.label}${r.comment.isEmpty ? '' : ' - "${r.comment}"'}',
              style: const TextStyle(fontSize: 12.5)),
          Text('Sent ${Formatters.timeAgo(r.createdAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          if (r.decidedBy != null)
            Text(
              '${r.status.label} by ${r.decidedBy}${r.facultyComment == null ? '' : ': ${r.facultyComment}'}',
              style: TextStyle(fontSize: 12.5, color: requestColor(r.status)),
            ),
          if (r.isPending)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: a.isBusy
                    ? null
                    : () async {
                        final ok = await confirmDialog(context,
                            title: 'Withdraw request?',
                            message: 'You can request ${r.courseCode} again later.',
                            confirmLabel: 'Withdraw',
                            destructive: true);
                        if (ok && context.mounted) {
                          await runWithFeedback(context, () => a.withdrawRequest(r.id),
                              success: 'Request withdrawn');
                        }
                      },
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Withdraw'),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}

class _RequestSheet extends StatefulWidget {
  const _RequestSheet({
    required this.sectionId,
    required this.label,
    required this.title,
    required this.kind,
  });

  final String sectionId;
  final String label;
  final String title;
  final RequestKind kind;

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  RequestReason? _reason;
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final advising = context.read<AdvisingProvider>();
    var sent = false;
    try {
      final request = await runAllowingConflicts(
        context,
        (accept) => advising.sendRequest(
          sectionId: widget.sectionId,
          kind: widget.kind,
          reason: _reason!,
          comment: _comment.text,
          acceptConflicts: accept,
        ),
      );
      sent = request != null;
      if (sent && mounted) {
        showAppSnackBar(context, 'Request sent to the course faculty and the Dean');
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, errorText(e), isError: true);
    }
    if (!mounted) return;
    setState(() => _sending = false);
    if (sent) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${widget.kind.label} request',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('${widget.label}  ${widget.title}',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            const Text('Reason (required)', style: TextStyle(fontWeight: FontWeight.w600)),
            RadioGroup<RequestReason>(
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v),
              child: Column(
                children: [
                  for (final reason in RequestReason.values)
                    RadioListTile<RequestReason>(
                      value: reason,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      title: Text(reason.label),
                    ),
                ],
              ),
            ),
            TextField(
              controller: _comment,
              maxLines: 2,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(labelText: 'Comment (optional)'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _reason == null || _sending ? null : _send,
              icon: const Icon(Icons.send_rounded),
              label: Text(_sending ? 'Sending...' : 'Send request'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
