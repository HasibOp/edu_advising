import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../providers/advising_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/staff_provider.dart';
import '../screens/common/notifications_screen.dart';
import '../screens/login/login_screen.dart';
import '../utils/app_config.dart';
import '../utils/app_theme.dart';
import 'state_views.dart';

/// White top bar with a thin gold line underneath.
///
/// Root screens of a shell show the university brand, the notification bell
/// and logout; pushed pages show their [title] and a back arrow.
class EduAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EduAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.actions = const [],
    this.brand = false,
    this.bottom,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> actions;

  /// Seal + university name + bell + logout (shell root screens).
  final bool brand;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + 3 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: brand ? 12 : null,
      title: brand
          ? Row(
              children: [
                Image.asset('assets/images/edu_seal.png', width: 36, height: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(AppConfig.universityName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      Text(title ?? AppConfig.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
      actions: [
        ...actions,
        if (brand) const NotificationBell(),
        if (brand) const LogoutButton(),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(3 + (bottom?.preferredSize.height ?? 0)),
        child: Column(
          children: [
            if (bottom != null) bottom!,
            Container(height: 3, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<NotificationProvider>().unreadCount;
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => openPage(context, const NotificationsScreen()),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: AppColors.danger,
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Log out',
      icon: const Icon(Icons.logout_rounded),
      onPressed: () async {
        final ok = await confirmDialog(
          context,
          title: 'Log out?',
          message: 'You will return to the login screen.',
          confirmLabel: 'Log out',
        );
        if (ok && context.mounted) logout(context);
      },
    );
  }
}

/// Clears every provider and returns to the login screen.
void logout(BuildContext context) {
  context.read<AdvisingProvider>().clear();
  context.read<StaffProvider>().clear();
  context.read<AdminProvider>().clear();
  context.read<NotificationProvider>().clear();
  context.read<AuthProvider>().logout();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}

Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));
