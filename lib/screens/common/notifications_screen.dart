import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';
import 'notice_board_screen.dart';

/// The bell: personal alerts (requests, waitlist, clearance) and new notices.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final Set<String> _unreadAtOpen;

  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    _unreadAtOpen = {for (final n in provider.notifications) if (!n.read) n.id};
    provider.refresh().then((_) => provider.markNotificationsRead());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final unreadNotices = provider.notices.where((n) => !provider.isNoticeRead(n.id)).toList();
    return Scaffold(
      appBar: const EduAppBar(title: 'Notifications'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: provider.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SectionHeader('For you'),
            if (provider.notifications.isEmpty)
              const AppCard(
                child: Text('Nothing yet. Request decisions, waitlist seats and clearance '
                    'changes show up here.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            for (final n in provider.notifications)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  color: _unreadAtOpen.contains(n.id) ? AppColors.tint : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(n.body, style: const TextStyle(fontSize: 13)),
                            Text(Formatters.timeAgo(n.createdAt),
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SectionHeader(
              'Unread notices',
              trailing: TextButton(
                onPressed: () => openPage(context, const NoticeBoardScreen()),
                child: const Text('Notice board'),
              ),
            ),
            if (unreadNotices.isEmpty)
              const AppCard(
                child: Text('You have read every notice.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            for (final n in unreadNotices)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () => showNotice(context, n),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign_outlined, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const StatusPill('NEW', color: AppColors.danger),
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
