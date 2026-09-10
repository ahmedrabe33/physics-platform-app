import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = _map(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final token = data['token']?.toString();
      if (token != null && token.isNotEmpty) {
        await _storage.write(key: 'jwt_token', value: token);
      }
      return data;
    }

    throw Exception(
      data['message']?.toString() ?? 'Login failed (${response.statusCode})',
    );
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String grade,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'grade': grade,
      }),
    );

    final data = _map(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Registration failed (${response.statusCode})',
    );
  }

  Future<String?> getToken() => _storage.read(key: 'jwt_token');
  Future<void> logout() => _storage.delete(key: 'jwt_token');

  static Map<String, dynamic> _map(String body) {
    if (body.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }
}
