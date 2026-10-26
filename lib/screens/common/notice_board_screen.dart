import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/portal.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';

/// Opens a notice and marks it as read.
Future<void> showNotice(BuildContext context, Notice notice) {
  context.read<NotificationProvider>().markNoticeRead(notice.id);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(notice.category.toUpperCase(), color: AppColors.primary),
              if (notice.pinned) ...[
                const SizedBox(width: 6),
                const StatusPill('PINNED', color: AppColors.warning, icon: Icons.push_pin),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(notice.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Posted ${Formatters.dateTime(notice.createdAt)}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          Text(notice.body, style: const TextStyle(fontSize: 14.5, height: 1.5)),
        ],
      ),
    ),
  );
}

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final categories = provider.notices.map((n) => n.category).toSet().toList()..sort();
    final notices =
        provider.notices.where((n) => _category == null || n.category == _category).toList();
    return Scaffold(
      appBar: EduAppBar(title: 'Notice Board', subtitle: '${provider.unreadNotices} unread'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: provider.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            ChoiceChipsRow<String?>(
              values: [null, ...categories],
              selected: _category,
              labelOf: (c) => c ?? 'All',
              onSelected: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 10),
            if (notices.isEmpty)
              const EmptyState(icon: Icons.campaign_outlined, title: 'No notices'),
            for (final n in notices)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => showNotice(context, n),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (n.pinned)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.push_pin, size: 16, color: AppColors.warning),
                            ),
                          Expanded(
                            child: Text(n.title,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: provider.isNoticeRead(n.id)
                                        ? FontWeight.w500
                                        : FontWeight.w700)),
                          ),
                          if (!provider.isNoticeRead(n.id))
                            const StatusPill('NEW', color: AppColors.danger),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Text('${n.category}  |  ${Formatters.timeAgo(n.createdAt)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary)),
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
