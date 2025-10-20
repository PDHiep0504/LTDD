import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/auth_models.dart';

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _expirationKey = 'token_expiration';

  String get _baseUrl => AppConfig.apiBaseUrl;

  Uri _buildUri(String path) {
    var p = path;
    if (!p.startsWith('/')) p = '/$p';
    return Uri.parse('$_baseUrl$p');
  }

  // Register new user
  Future<void> register(RegisterRequest request) async {
    final uri = _buildUri('/api/Auth/register');
    try {
      final res = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return;
      }

      final body = json.decode(utf8.decode(res.bodyBytes));
      throw AuthException(body['message'] ?? 'Registration failed');
    } catch (e) {
      if (kDebugMode) print('Register error: $e');
      rethrow;
    }
  }

  // Login user
  Future<AuthResponse> login(LoginRequest request) async {
    final uri = _buildUri('/api/Auth/login');
    try {
      final res = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = json.decode(utf8.decode(res.bodyBytes));
        final authResponse = AuthResponse.fromJson(body);
        await _saveAuthData(authResponse);
        return authResponse;
      }

      final body = json.decode(utf8.decode(res.bodyBytes));
      throw AuthException(body['message'] ?? 'Login failed');
    } catch (e) {
      if (kDebugMode) print('Login error: $e');
      rethrow;
    }
  }

  // Refresh token
  Future<AuthResponse> refreshToken() async {
    final token = await getToken();
    final refreshToken = await getRefreshToken();

    if (token == null || refreshToken == null) {
      throw AuthException('No tokens found');
    }

    final uri = _buildUri('/api/Auth/refresh');
    try {
      final res = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'token': token, 'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = json.decode(utf8.decode(res.bodyBytes));
        final authResponse = AuthResponse.fromJson(body);
        await _saveAuthData(authResponse);
        return authResponse;
      }

      throw AuthException('Token refresh failed');
    } catch (e) {
      if (kDebugMode) print('Refresh token error: $e');
      rethrow;
    }
  }

  // Save authentication data
  Future<void> _saveAuthData(AuthResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, response.token);
    await prefs.setString(_refreshTokenKey, response.refreshToken);
    await prefs.setString(_userKey, json.encode(response.user.toJson()));
    await prefs.setString(
      _expirationKey,
      response.expiration.toIso8601String(),
    );
  }

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get stored refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Get stored user
  Future<AuthUser?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return AuthUser.fromJson(json.decode(userJson));
  }

  // Get token expiration
  Future<DateTime?> getTokenExpiration() async {
    final prefs = await SharedPreferences.getInstance();
    final expString = prefs.getString(_expirationKey);
    if (expString == null) return null;
    return DateTime.parse(expString);
  }

  // Check if token is expired
  Future<bool> isTokenExpired() async {
    final exp = await getTokenExpiration();
    if (exp == null) return true;
    return DateTime.now().isAfter(exp);
  }

  // Decode JWT token to extract user info and roles
  Map<String, dynamic>? decodeToken(String token) {
    try {
      return Jwt.parseJwt(token);
    } catch (e) {
      if (kDebugMode) print('JWT decode error: $e');
      return null;
    }
  }

  // Get user info from token
  AuthUser? getUserFromToken(String token) {
    try {
      final payload = Jwt.parseJwt(token);

      // Extract roles from claims
      final roles = <String>[];
      if (payload.containsKey(
        'http://schemas.microsoft.com/ws/2008/06/identity/claims/role',
      )) {
        final roleData =
            payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
        if (roleData is List) {
          roles.addAll(roleData.map((e) => e.toString()));
        } else {
          roles.add(roleData.toString());
        }
      }

      return AuthUser(
        id:
            payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
            '',
        email:
            payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] ??
            '',
        fullName:
            payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ??
            '',
        roles: roles,
      );
    } catch (e) {
      if (kDebugMode) print('Get user from token error: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_expirationKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;
    return !await isTokenExpired();
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}
