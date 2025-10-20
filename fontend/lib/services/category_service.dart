import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import '../config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';

class CategoryService {
  CategoryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    return AppConfig.apiBaseUrl;
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{'Accept': 'application/json'};

    // Add JWT token if available
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    var p = path;
    if (!p.startsWith('/')) p = '/$p';
    final uri = Uri.parse('$_baseUrl$p');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        ...query.map((k, v) => MapEntry(k, v.toString())),
      },
    );
  }

  Future<List<Category>> fetchCategories() async {
    final uri = _buildUri('/api/Category');
    try {
      final headers = await _getHeaders();
      final res = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = json.decode(utf8.decode(res.bodyBytes));
        if (body is List) {
          return body
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        throw const FormatException('Unexpected response format');
      }

      throw HttpException('Failed with status ${res.statusCode}', uri: uri);
    } on Exception catch (e, st) {
      if (kDebugMode) {
        print('fetchCategories error: $e\n$st');
      }
      rethrow;
    }
  }

  Future<Category> addCategory(Category category) async {
    final uri = _buildUri('/api/Category');
    try {
      final headers = await _getHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await _client
          .post(uri, headers: headers, body: json.encode(category.toJson()))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = json.decode(utf8.decode(res.bodyBytes));
        return Category.fromJson(body);
      }

      // Try to parse error message
      String errorMessage = 'Failed with status ${res.statusCode}';
      try {
        final errorBody = json.decode(utf8.decode(res.bodyBytes));
        if (errorBody is Map && errorBody['message'] != null) {
          errorMessage = errorBody['message'];
        }
      } catch (_) {}

      throw HttpException(errorMessage, uri: uri);
    } on Exception catch (e, st) {
      if (kDebugMode) print('addCategory error: $e\n$st');
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    final uri = _buildUri('/api/Category/${category.id}');
    try {
      final headers = await _getHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await _client
          .put(uri, headers: headers, body: json.encode(category.toJson()))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        // Try to parse error message
        String errorMessage = 'Failed with status ${res.statusCode}';
        try {
          final errorBody = json.decode(utf8.decode(res.bodyBytes));
          if (errorBody is Map && errorBody['message'] != null) {
            errorMessage = errorBody['message'];
          }
        } catch (_) {}

        throw HttpException(errorMessage, uri: uri);
      }
    } on Exception catch (e, st) {
      if (kDebugMode) print('updateCategory error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    final uri = _buildUri('/api/Category/$id');
    try {
      final headers = await _getHeaders();
      final res = await _client
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('Failed with status ${res.statusCode}', uri: uri);
      }
    } on Exception catch (e, st) {
      if (kDebugMode) print('deleteCategory error: $e\n$st');
      rethrow;
    }
  }
}

class HttpException implements Exception {
  final String message;
  final Uri? uri;
  const HttpException(this.message, {this.uri});
  @override
  String toString() => 'HttpException: $message${uri == null ? '' : ' ($uri)'}';
}
