import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  Future<void> initialize() async {
    _setLoading(true);
    await _authService.initialize();
    final user = await _authService.getCurrentUser();
    _currentUser = user;
    _setLoading(false);
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
    String? inviteCode,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await AuthService().register(
      email: email,
      username: username,
      password: password,
      confirmPassword: confirmPassword,
      inviteCode: inviteCode,
    );

    if (result.success) {
      _currentUser = result.user;
      _setLoading(false);
      return true;
    } else {
      _error = result.error;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await AuthService().login(
      email: email,
      password: password,
    );

    if (result.success) {
      _currentUser = result.user;
      _setLoading(false);
      return true;
    } else {
      _error = result.error;
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }
}