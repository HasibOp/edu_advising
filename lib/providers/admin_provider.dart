import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/portal.dart';
import '../models/student.dart';
import '../services/api_service.dart';

/// Administrator data: the clearance list and the advising windows.
class AdminProvider extends ChangeNotifier {
  AdminProvider(this._api);

  final ApiService _api;

  AppUser? _user;
  List<Student> _students = [];
  AdvisingWindows? _windows;
  bool _isLoading = false;
  String? _error;

  List<Student> get students => _students;
  AdvisingWindows? get windows => _windows;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int count(ClearanceStatus status) => _students.where((s) => s.clearanceStatus == status).length;

  Future<void> load(AppUser user) async {
    _user = user;
    _isLoading = _students.isEmpty;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([_api.fetchStudents(), _api.fetchWindows()]);
      _students = results[0] as List<Student>;
      _windows = results[1] as AdvisingWindows;
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

  Future<Student> setClearance(String studentId, ClearanceAction action) async {
    final updated = await _api.setClearance(_user!, studentId, action);
    _students = [for (final s in _students) s.id == studentId ? updated : s];
    notifyListeners();
    return updated;
  }

  Future<void> updateWindows(AdvisingWindows windows) async {
    _windows = await _api.updateWindows(_user!, windows);
    notifyListeners();
  }

  void clear() {
    _user = null;
    _students = [];
    _windows = null;
    notifyListeners();
  }
}
