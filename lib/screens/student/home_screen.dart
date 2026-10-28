import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/advising_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/badges.dart';
import '../../widgets/common.dart';
import '../../widgets/edu_app_bar.dart';
import '../../widgets/state_views.dart';
import '../advising/clearance_screen.dart';
import '../classes/class_routine_screen.dart';
import '../classes/exam_routine_screen.dart';
import '../classes/my_classes_screen.dart';
import '../classes/offer_list_screen.dart';
import '../common/notice_board_screen.dart';
import '../reports/finance_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenMenu});

  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final advising = context.watch<AdvisingProvider>();
    final student = advising.student;
    if (advising.isLoading && student == null) return const LoadingView();
    if (student == null) {
      return ErrorView(
        message: advising.error ?? 'Could not load your profile.',
        onRetry: advising.refresh,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([
          advising.refresh(),
          context.read<NotificationProvider>().refresh(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Profile card (opens My Profile).
          AppCard(
            onTap: () => openPage(context, const ProfileScreen()),
            child: Row(
              children: [
                Avatar(student.initials, size: 54, photoUrl: student.photoUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text('ID ${student.id}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('${student.dept}  |  Semester ${student.semesterNo}  |  CGPA ${student.cgpa.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _AdvisingCard(advising: advising),
          const SectionHeader('Account summary'),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatTile(
                    value: student.cgpa.toStringAsFixed(2),
                    label: 'CGPA',
                    icon: Icons.insights_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    value: Formatters.credits(student.creditsDone),
                    label: 'Credits completed',
                    icon: Icons.task_alt,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatTile(
                    value: '${Formatters.credits(advising.credits)} cr',
                    label: 'Enrolled in ${AppConfig.currentTerm}',
                    icon: Icons.menu_book_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    value: Formatters.money(student.dues),
                    label: 'Dues (tap for finance)',
                    icon: Icons.account_balance_wallet_outlined,
                    color: student.dues > 0 ? AppColors.danger : AppColors.success,
                    onTap: () => openPage(context, const FinanceScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Quick links'),
          Row(
            children: [
              _QuickLink(Icons.class_outlined, 'My classes',
                  () => openPage(context, const MyClassesScreen())),
              _QuickLink(Icons.calendar_view_week_outlined, 'Routine',
                  () => openPage(context, const ClassRoutineScreen())),
              _QuickLink(Icons.event_note_outlined, 'Exams',
                  () => openPage(context, const ExamRoutineScreen())),
              _QuickLink(Icons.list_alt_outlined, 'Offer list',
                  () => openPage(context, const OfferListScreen())),
            ],
          ),
          SectionHeader(
            'Notices',
            trailing: TextButton(
              onPressed: () => openPage(context, const NoticeBoardScreen()),
              child: const Text('See all'),
            ),
          ),
          const _NoticePreview(),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: onOpenMenu,
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Open the full menu'),
            ),
          ),
        ],
      ),
    );
  }
}

/// The highlighted Advising card: clearance, window and progress.
class _AdvisingCard extends StatelessWidget {
  const _AdvisingCard({required this.advising});

  final AdvisingProvider advising;

  @override
  Widget build(BuildContext context) {
    final student = advising.student!;
    final done = student.advisingDone;
    return AppCard(
      color: AppColors.tint,
      borderColor: AppColors.primary.withAlpha(60),
      leftAccent: AppColors.primary,
      onTap: () => openPage(context, const ClearanceScreen()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_reg_outlined, color: AppColors.primary, size: 26),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Advising - ${AppConfig.currentTerm}',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              ClearanceBadge(student.clearanceStatus),
            ],
          ),
          const SizedBox(height: 10),
          _line(
            advising.regularOpen ? Icons.lock_open_rounded : Icons.lock_clock_outlined,
            advising.regularOpen ? 'Regular advising is open' : 'Regular advising is closed',
            advising.regularOpen ? AppColors.success : AppColors.danger,
          ),
          _line(
            done ? Icons.check_circle_outline : Icons.pending_outlined,
            done
                ? 'Advising done: Section ${student.lockedGroup}, '
                    '${advising.regular.length} course(s), ${Formatters.credits(advising.credits)} credits'
                : 'Advising not done yet',
            done ? AppColors.success : AppColors.warning,
          ),
          if (advising.waitlist.isNotEmpty)
            _line(Icons.hourglass_top_rounded,
                'On the waitlist for ${advising.waitlist.map((w) => w.sectionLabel).join(', ')}',
                AppColors.warning),
          if (advising.extraOpen)
            _line(Icons.add_task, 'Extra course requests are open', AppColors.info),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => openPage(context, const ClearanceScreen()),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(done ? 'View advising' : 'Start advising'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
          ],
        ),
      );
}

class _QuickLink extends StatelessWidget {
  const _QuickLink(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticePreview extends StatelessWidget {
  const _NoticePreview();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notices = provider.notices.take(3).toList();
    if (notices.isEmpty) {
      return const AppCard(child: Text('No notices yet.', style: TextStyle(color: AppColors.textMuted)));
    }
    return Column(
      children: [
        for (final n in notices)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              onTap: () => showNotice(context, n),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(n.pinned ? Icons.push_pin : Icons.campaign_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title,
                            style: TextStyle(
                                fontWeight: provider.isNoticeRead(n.id)
                                    ? FontWeight.w500
                                    : FontWeight.w700)),
                        Text('${n.category}  |  ${Formatters.timeAgo(n.createdAt)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  if (!provider.isNoticeRead(n.id))
                    const StatusPill('NEW', color: AppColors.danger),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
