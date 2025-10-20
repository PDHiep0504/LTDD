import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  AuthUser? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  AuthUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isManager => _user?.isManager ?? false;

  // Initialize auth state on app start
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final token = await _authService.getToken();
        if (token != null) {
          _user = _authService.getUserFromToken(token);

          // Check if token is about to expire (< 5 minutes)
          final exp = await _authService.getTokenExpiration();
          if (exp != null && exp.difference(DateTime.now()).inMinutes < 5) {
            await refreshToken();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Auth initialize error: $e');
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? userName,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final request = RegisterRequest(
        email: email,
        password: password,
        fullName: fullName,
        userName: userName,
      );
      await _authService.register(request);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Login user
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _error = null;
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _authService.login(request);
      _user = response.user;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final response = await _authService.refreshToken();
      _user = response.user;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('Token refresh error: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _user = null;
      _error = null;
    } finally {
      _setLoading(false);
    }
  }

  // Check if user has specific role
  bool hasRole(String role) => _user?.hasRole(role) ?? false;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
