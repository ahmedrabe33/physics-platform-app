import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Try both gateway shapes so the app works with either gateway version.
  static const List<String> _studentBases = [
    '/api/students',
    '/api/students/students',
  ];

  static const List<String> _contentBases = [
    '/api/content',
    '/api/content/content',
  ];

  static const List<String> _progressBases = [
    '/api/progress',
    '/api/progress/progress',
  ];

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _map(String body) {
    if (body.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  List<dynamic> _list(String body) {
    if (body.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(body);
      if (decoded is List) return decoded;
    } catch (_) {}
    return [];
  }

  Future<http.Response> _getCandidates(List<String> paths) async {
    final headers = await _headers();
    http.Response? last;

    for (final path in paths) {
      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: headers,
      );
      last = response;

      if (response.statusCode != 404) {
        return response;
      }
    }

    return last!;
  }

  Future<http.Response> _postCandidates(
    List<String> paths,
    Map<String, dynamic> body,
  ) async {
    final headers = {...await _headers(), 'Content-Type': 'application/json'};

    http.Response? last;

    for (final path in paths) {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: jsonEncode(body),
      );
      last = response;

      if (response.statusCode != 404) {
        return response;
      }
    }

    return last!;
  }

  Future<Map<String, dynamic>> getContent(String grade) async {
    final response = await _getCandidates(
      _contentBases.map((base) => '$base/$grade').toList(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _map(response.body);
    }

    throw Exception('Cannot load content (${response.statusCode})');
  }

  Future<Map<String, dynamic>> getLesson(String grade, dynamic lessonId) async {
    final response = await _getCandidates(
      _contentBases.map((base) => '$base/$grade/lessons/$lessonId').toList(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _map(response.body);
    }

    throw Exception('Cannot load lesson (${response.statusCode})');
  }

  Future<Map<String, dynamic>> getStudent(dynamic userId) async {
    final response = await _getCandidates(
      _studentBases.map((base) => '$base/$userId').toList(),
    );

    if (response.statusCode == 404) return {};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _map(response.body);
    }

    throw Exception('Cannot load student (${response.statusCode})');
  }

  Future<String?> getAccessStatus(dynamic userId) async {
    final response = await _getCandidates(
      _studentBases.map((base) => '$base/$userId/access').toList(),
    );

    final data = _map(response.body);
    final status = data['status']?.toString();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return status ?? 'approved';
    }

    // The lab user may have no student-service record.
    if (response.statusCode == 404) return null;

    if (status == 'pending' || status == 'rejected' || status == 'expired') {
      return status;
    }

    return null;
  }

  Future<List<dynamic>> getProgress(dynamic userId) async {
    final response = await _getCandidates(
      _progressBases.map((base) => '$base/$userId').toList(),
    );

    if (response.statusCode == 404) return [];

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _list(response.body);
    }

    throw Exception('Cannot load progress (${response.statusCode})');
  }

  Future<void> completeLesson({
    required dynamic userId,
    required dynamic lessonId,
  }) async {
    final response = await _postCandidates(
      _progressBases.map((base) => '$base/complete').toList(),
      {'userId': userId, 'lessonId': lessonId, 'score': 100},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    final data = _map(response.body);

    throw Exception(
      data['message']?.toString() ??
          'Cannot complete lesson (${response.statusCode})',
    );
  }

  Future<void> trackVideoView({
    required dynamic userId,
    required dynamic lessonId,
    dynamic topicId,
    String? videoUrl,
  }) async {
    final response = await _postCandidates(
      _progressBases.map((base) => '$base/video-view').toList(),
      {
        'userId': userId,
        'lessonId': lessonId,
        'topicId': topicId,
        'videoUrl': videoUrl,
      },
    );

    if (response.statusCode == 404) return;
  }

  Future<void> createStudent({
    required String userId,
    required String username,
    required String email,
    required String grade,
    required String paymentProofPath,
  }) async {
    final token = await _storage.read(key: 'jwt_token');

    for (final path in _studentBases) {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));

      request.headers['Accept'] = 'application/json';

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['userId'] = userId;
      request.fields['username'] = username;
      request.fields['email'] = email;
      request.fields['grade'] = grade;

      request.files.add(
        await http.MultipartFile.fromPath('paymentProof', paymentProofPath),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 404) {
        continue;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final data = _map(body);

      throw Exception(
        data['message']?.toString() ??
            'Cannot upload payment proof (${response.statusCode})',
      );
    }

    throw Exception('Student endpoint not found');
  }
}
