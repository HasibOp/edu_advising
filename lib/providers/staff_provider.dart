import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/course.dart';
import '../models/extra_request.dart';
import '../services/api_service.dart';
import '../services/catalog.dart';

class StaffProvider extends ChangeNotifier {
  StaffProvider(this._api);

  final ApiService _api;

  AppUser? _user;
  List<CourseSection> _sections = [];
  List<ExtraRequest> _requests = [];
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  List<CourseSection> get allSections => _sections;
  List<ExtraRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingCount => _requests.where((r) => r.isPending).length;

  static bool owns(AppUser user, CourseSection s) {
    if (user.isDean) return true;
    final short = user.shortName;
    if (short == null) return false;
    return s.parts.any((p) => Catalog.instance.teaches(short, s.courseCode, p.sectionNo));
  }

  List<CourseSection> get mySections {
    final short = _user?.shortName;
    if (short == null) return const [];
    return _sections
        .where((s) => s.parts.any((p) => Catalog.instance.teaches(short, s.courseCode, p.sectionNo)))
        .toList();
  }

  Future<void> load(AppUser user) async {
    _user = user;
    _isLoading = _sections.isEmpty;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchSections(),
        _api.fetchRequestsFor(user),
      ]);
      _sections = results[0] as List<CourseSection>;
      _requests = results[1] as List<ExtraRequest>;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_user != null) await load(_user!);
  }

  Future<ExtraRequest> decide(String requestId, bool approve, String comment) async {
    final result = await _api.decideExtraRequest(_user!, requestId, approve, comment);
    await refresh();
    return result;
  }

  Future<CourseSection> changeSeats(String sectionId, int capacity) async {
    final result = await _api.changeSeats(_user!, sectionId, capacity);
    await refresh();
    return result;
  }

  void clear() {
    _user = null;
    _sections = [];
    _requests = [];
    _error = null;
    notifyListeners();
  }
}
