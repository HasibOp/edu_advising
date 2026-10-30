import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api);

  final ApiService _api;

  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<AppUser?> login(String username, String password, UserRole role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _api.login(username, password, role);
      return _user;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _error = null;
    notifyListeners();
  }
}
