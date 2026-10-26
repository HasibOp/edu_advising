import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/portal.dart';
import '../services/api_service.dart';

/// Notices and personal notifications behind the bell badge.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._api);

  final ApiService _api;

  AppUser? _user;
  List<AppNotification> _notifications = [];
  List<Notice> _notices = [];
  Set<String> _readNotices = {};

  List<AppNotification> get notifications => _notifications;
  List<Notice> get notices => _notices;
  bool isNoticeRead(String id) => _readNotices.contains(id);

  int get unreadNotices => _notices.where((n) => !_readNotices.contains(n.id)).length;
  int get unreadNotifications => _notifications.where((n) => !n.read).length;
  int get unreadCount => unreadNotices + unreadNotifications;

  Future<void> load(AppUser user) async {
    _user = user;
    await refresh();
  }

  Future<void> refresh() async {
    final user = _user;
    if (user == null) return;
    try {
      final results = await Future.wait([
        _api.fetchNotifications(user.id),
        _api.fetchNotices(),
        _api.fetchReadNoticeIds(user.id),
      ]);
      _notifications = results[0] as List<AppNotification>;
      _notices = results[1] as List<Notice>;
      _readNotices = results[2] as Set<String>;
      notifyListeners();
    } on ApiException {
      // The badge is optional; keep the old values.
    }
  }

  Future<void> markNoticeRead(String noticeId) async {
    final user = _user;
    if (user == null || _readNotices.contains(noticeId)) return;
    _readNotices = {..._readNotices, noticeId};
    notifyListeners();
    await _api.markNoticeRead(user.id, noticeId);
  }

  Future<void> markNotificationsRead() async {
    final user = _user;
    if (user == null || unreadNotifications == 0) return;
    _notifications = [for (final n in _notifications) n.markRead()];
    notifyListeners();
    await _api.markNotificationsRead(user.id);
  }

  void clear() {
    _user = null;
    _notifications = [];
    _notices = [];
    _readNotices = {};
    notifyListeners();
  }
}
