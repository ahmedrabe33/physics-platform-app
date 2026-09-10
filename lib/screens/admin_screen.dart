import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminScreen({super.key, required this.user});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final auth = AuthService();

  bool loading = true;
  String? error;

  List<dynamic> students = [];
  Map<String, dynamic> content = {};
  List<dynamic> videoViews = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<Map<String, String>> headers() async {
    final token = await auth.getToken();

    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> loadDashboard() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final h = await headers();

      final responses = await Future.wait([
        http.get(Uri.parse('${AuthService.baseUrl}/api/students'), headers: h),
        http.get(Uri.parse('${AuthService.baseUrl}/api/content'), headers: h),
        http.get(
          Uri.parse('${AuthService.baseUrl}/api/progress/admin/video-views'),
          headers: h,
        ),
      ]);

      if (responses.any((r) => r.statusCode < 200 || r.statusCode >= 300)) {
        throw Exception('Cannot load admin dashboard');
      }

      final studentsData = jsonDecode(responses[0].body);
      final contentData = jsonDecode(responses[1].body);
      final videoData = jsonDecode(responses[2].body);

      if (!mounted) return;

      setState(() {
        students = studentsData is List ? studentsData : [];
        content = contentData is Map
            ? Map<String, dynamic>.from(contentData)
            : {};
        videoViews = videoData is List ? videoData : [];
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  int chaptersCount() {
    int total = 0;

    for (final grade in ['second', 'third']) {
      final gradeData = content[grade];

      if (gradeData is Map) {
        final chapters = gradeData['chapters'];

        if (chapters is List) {
          total += chapters.length;
        }
      }
    }

    return total;
  }

  int lessonsCount() {
    int total = 0;

    for (final grade in ['second', 'third']) {
      final gradeData = content[grade];

      if (gradeData is Map) {
        final chapters = gradeData['chapters'];

        if (chapters is List) {
          for (final chapter in chapters) {
            if (chapter is Map && chapter['lessons'] is List) {
              total += (chapter['lessons'] as List).length;
            }
          }
        }
      }
    }

    return total;
  }

  Future<void> studentAction(dynamic userId, String action) async {
    try {
      final h = await headers();

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/students/$userId/$action'),
        headers: h,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Operation failed (${response.statusCode})');
      }

      await loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تنفيذ العملية بنجاح')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> logout() async {
    await auth.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = students.where((s) => s['status'] == 'pending').length;

    final approved = students.where((s) => s['status'] == 'approved').length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        appBar: AppBar(
          backgroundColor: const Color(0xFF111827),
          title: const Text('لوحة الإدارة'),
          actions: [
            IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loadDashboard,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: loadDashboard,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'أهلاً ${widget.user['username'] ?? 'Admin'} 👋',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        statCard(
                          'الطلاب',
                          students.length.toString(),
                          Icons.people,
                        ),
                        statCard(
                          'بانتظار الموافقة',
                          pending.toString(),
                          Icons.hourglass_top,
                        ),
                        statCard(
                          'مفعل',
                          approved.toString(),
                          Icons.check_circle,
                        ),
                        statCard(
                          'الفصول',
                          chaptersCount().toString(),
                          Icons.menu_book,
                        ),
                        statCard(
                          'الدروس',
                          lessonsCount().toString(),
                          Icons.video_library,
                        ),
                        statCard(
                          'مشاهدات الفيديو',
                          videoViews.length.toString(),
                          Icons.play_circle,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'الطلاب',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...students.map(studentCard),
                  ],
                ),
              ),
      ),
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    return SizedBox(
      width: 165,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF182235),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF818CF8), size: 30),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget studentCard(dynamic student) {
    final status = student['status']?.toString() ?? '-';
    final userId = student['userId'];

    return Card(
      color: const Color(0xFF182235),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              student['username']?.toString() ?? '-',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            Text(
              student['email']?.toString() ?? '-',
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),

            const SizedBox(height: 6),

            Text('الحالة: $status'),

            const SizedBox(height: 12),

            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => studentAction(userId, 'approve'),
                      child: const Text('موافقة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => studentAction(userId, 'reject'),
                      child: const Text('رفض'),
                    ),
                  ),
                ],
              ),

            if (status == 'approved')
              ElevatedButton(
                onPressed: () => studentAction(userId, 'renew'),
                child: const Text('تجديد الاشتراك'),
              ),
          ],
        ),
      ),
    );
  }
}
