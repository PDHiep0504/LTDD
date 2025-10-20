import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class ProductService {
  ProductService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Prefer .env API_BASE_URL, else fallback to provided tunnel URL
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

  Future<List<Product>> fetchProducts() async {
    final uri = _buildUri('/api/ProductApi');
    try {
      final headers = await _getHeaders();
      final res = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = json.decode(utf8.decode(res.bodyBytes));
        if (body is List) {
          return body
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        // Some APIs wrap data in { data: [] }
        if (body is Map && body['data'] is List) {
          return (body['data'] as List)
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        throw const FormatException('Unexpected response format');
      }

      throw HttpException('Failed with status ${res.statusCode}', uri: uri);
    } on Exception catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('fetchProducts error: $e\n$st');
      }
      rethrow;
    }
  }

  Future<Product> addProduct(Product product) async {
    final uri = _buildUri('/api/ProductApi');
    try {
      final headers = await _getHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await _client
          .post(uri, headers: headers, body: json.encode(product.toJson()))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = json.decode(utf8.decode(res.bodyBytes));
        return Product.fromJson(body);
      }

      throw HttpException('Failed with status ${res.statusCode}', uri: uri);
    } on Exception catch (e, st) {
      if (kDebugMode) print('addProduct error: $e\n$st');
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    final uri = _buildUri('/api/ProductApi/${product.id}');
    try {
      final headers = await _getHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await _client
          .put(uri, headers: headers, body: json.encode(product.toJson()))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('Failed with status ${res.statusCode}', uri: uri);
      }
    } on Exception catch (e, st) {
      if (kDebugMode) print('updateProduct error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    final uri = _buildUri('/api/ProductApi/$id');
    try {
      final headers = await _getHeaders();
      final res = await _client
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('Failed with status ${res.statusCode}', uri: uri);
      }
    } on Exception catch (e, st) {
      if (kDebugMode) print('deleteProduct error: $e\n$st');
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
