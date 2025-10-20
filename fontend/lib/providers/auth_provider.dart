import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/auth_models.dart';
import '../models/totp_models.dart';
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

  // Helper method to save user to SharedPreferences
  Future<void> _saveUserToPrefs() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(_user!.toJson()));
      if (kDebugMode) {
        print(
          '💾 Saved user to preferences: ${_user!.email}, isTotpEnabled: ${_user!.isTotpEnabled}',
        );
      }
    }
  }

  // Initialize auth state on app start
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        // Load user from SharedPreferences (includes isTotpEnabled)
        _user = await _authService.getStoredUser();

        if (kDebugMode) {
          print(
            '✅ Loaded user: ${_user?.email}, isTotpEnabled: ${_user?.isTotpEnabled}',
          );
        }

        // Check if token is about to expire (< 5 minutes)
        final exp = await _authService.getTokenExpiration();
        if (exp != null && exp.difference(DateTime.now()).inMinutes < 5) {
          await refreshToken();
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

  // Login user with TOTP support (returns requiresTwoFactor flag)
  Future<Map<String, dynamic>> loginWithTotpSupport({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      // Use unified login-with-totp endpoint for both 2FA and non-2FA accounts
      final request = LoginWithTotpRequest(email: email, password: password);
      final response = await _authService.loginWithTotp(request);

      if (kDebugMode) {
        print(
          '[AuthProvider] requiresTwoFactor: ${response.requiresTwoFactor}',
        );
      }

      if (response.requiresTwoFactor) {
        // Don't set user yet, wait for TOTP verification
        _setLoading(false);
        if (kDebugMode) {
          print('[AuthProvider] ✅ requiresTwoFactor is TRUE');
          print(
            '[AuthProvider] Returning Map: requiresTwoFactor=true, success=false',
          );
        }
        return {'requiresTwoFactor': true, 'success': false};
      } else {
        // No 2FA, login successful
        _user = response.user;
        _setLoading(false);
        if (kDebugMode) print('[AuthProvider] Login successful without 2FA');
        return {'requiresTwoFactor': false, 'success': true};
      }
    } catch (e, stackTrace) {
      _error = e.toString();
      _setLoading(false);
      if (kDebugMode) {
        print('[AuthProvider] ❌ LOGIN ERROR: $e');
        print('Stack trace: $stackTrace');
      }
      return {'requiresTwoFactor': false, 'success': false};
    }
  }

  // Complete login with TOTP code
  Future<bool> loginWithTotp({
    required String email,
    required String password,
    required String totpCode,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      if (kDebugMode) print('[AuthProvider] Verifying TOTP code: $totpCode');
      final request = LoginWithTotpRequest(
        email: email,
        password: password,
        totpCode: totpCode,
      );
      final response = await _authService.loginWithTotp(request);

      if (kDebugMode) {
        print('[AuthProvider] TOTP verification response:');
        print('  requiresTwoFactor: ${response.requiresTwoFactor}');
        print('  token length: ${response.token.length}');
      }

      if (response.requiresTwoFactor) {
        // Still requires 2FA - code was wrong
        _error = 'Mã xác thực không đúng';
        _setLoading(false);
        if (kDebugMode) print('[AuthProvider] TOTP code rejected');
        return false;
      }

      _user = response.user;
      _setLoading(false);
      if (kDebugMode)
        print('[AuthProvider] TOTP verification successful, user logged in');
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      if (kDebugMode) print('[AuthProvider] TOTP verification error: $e');
      return false;
    }
  }

  // Enable TOTP for current user
  Future<TotpSetupResponse?> enableTotp() async {
    try {
      return await _authService.enableTotp();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Verify TOTP code and complete setup
  Future<bool> verifyTotp(String code) async {
    try {
      await _authService.verifyTotp(code);

      // Update user's TOTP status
      if (_user != null) {
        _user = AuthUser(
          id: _user!.id,
          email: _user!.email,
          fullName: _user!.fullName,
          roles: _user!.roles,
          isTotpEnabled: true,
        );

        // Save updated user to SharedPreferences
        await _saveUserToPrefs();

        if (kDebugMode) {
          print('✅ TOTP enabled and saved to preferences');
        }

        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Disable TOTP for current user
  Future<bool> disableTotp(String password) async {
    try {
      await _authService.disableTotp(password);

      // Update user's TOTP status
      if (_user != null) {
        _user = AuthUser(
          id: _user!.id,
          email: _user!.email,
          fullName: _user!.fullName,
          roles: _user!.roles,
          isTotpEnabled: false,
        );

        // Save updated user to SharedPreferences
        await _saveUserToPrefs();

        if (kDebugMode) {
          print('✅ TOTP disabled and saved to preferences');
        }

        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
