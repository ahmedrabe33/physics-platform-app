import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import 'lesson_screen.dart';
import 'login_screen.dart';
import 'status_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dashboard = DashboardService();
  final auth = AuthService();

  late Future<Map<String, dynamic>> future;

  static const bg = Color(0xFF0B1020);
  static const card = Color(0xFF182235);
  static const text = Color(0xFFF8FAFC);
  static const muted = Color(0xFF94A3B8);
  static const primary = Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    future = dashboard.loadDashboard(widget.user);
  }

  void reload() {
    setState(() {
      future = dashboard.loadDashboard(widget.user);
    });
  }

  Future<void> logout() async {
    await auth.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> openLesson(
    Map<String, dynamic> lesson,
    List<Map<String, dynamic>> allLessons,
  ) async {
    final index = allLessons.indexWhere(
      (e) => e['id'].toString() == lesson['id'].toString(),
    );

    final previousLessonId = index > 0 ? allLessons[index - 1]['id'] : null;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          user: widget.user,
          lessonSummary: lesson,
          previousLessonId: previousLessonId,
        ),
      ),
    );

    if (changed == true) reload();
  }

  String gradeName() {
    return widget.user['grade'] == 'second'
        ? 'الصف الثاني الثانوي'
        : 'الصف الثالث الثانوي';
  }

  String formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';
    final d = DateTime.tryParse(value.toString());
    if (d == null) return value.toString();

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF111827),
          title: const Text('⚛ physics'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Center(
                child: Text(
                  '👤 ${widget.user['username'] ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            TextButton(onPressed: logout, child: const Text('خروج')),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primary),
              );
            }

            if (snapshot.hasError) {
              return _error(snapshot.error.toString());
            }

            final data = snapshot.data!;
            final status = data['accessStatus']?.toString();

            if (status == 'pending' ||
                status == 'rejected' ||
                status == 'expired') {
              return StatusScreen(status: status!, onBack: logout);
            }

            return _dashboard(data);
          },
        ),
      ),
    );
  }

  Widget _error(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0x1FEF4444),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تعذر تحميل لوحة الطالب',
                style: TextStyle(
                  color: Color(0xFFFECACA),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: reload,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboard(Map<String, dynamic> data) {
    final student = Map<String, dynamic>.from(data['student'] ?? {});

    final chapters = (data['chapters'] as List).cast<Map<String, dynamic>>();

    final lessons = (data['lessons'] as List).cast<Map<String, dynamic>>();

    final completedCount = data['completedCount'] as int;
    final totalLessons = data['totalLessons'] as int;
    final progressPercent = data['progressPercent'] as int;

    Map<String, dynamic>? continueLesson;

    if (data['continueLesson'] is Map) {
      continueLesson = Map<String, dynamic>.from(data['continueLesson']);
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Color(0xFF1E1B4B), bg],
          stops: [0, .55],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          reload();
          await future;
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 50),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _hero(progressPercent),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _stat('${chapters.length}', '📚 الفصول'),
                      _stat('$totalLessons', '🎬 الدروس'),
                      _stat('$completedCount', '✅ مكتملة'),
                      _stat(
                        formatDate(student['subscriptionExpiry']),
                        '📅 انتهاء الاشتراك',
                        small: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (continueLesson != null)
                    _continueCard(continueLesson, lessons),
                  if (continueLesson != null) const SizedBox(height: 18),
                  _progress(progressPercent, completedCount, totalLessons),
                  const SizedBox(height: 18),
                  _content(chapters, lessons),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(int percent) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0x296366F1), Color(0x148B5CF6)],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'لوحة الطالب',
            style: TextStyle(
              color: Color(0xFFA5B4FC),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أهلاً يا ${widget.user['username'] ?? ''} 👋',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: text,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(gradeName(), style: const TextStyle(color: muted)),
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0x246366F1),
            child: Text(
              '$percent%',
              style: const TextStyle(
                color: text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, {bool small = false}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xDB182235),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: text,
              fontSize: small ? 16 : 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }

  Widget _continueCard(
    Map<String, dynamic> lesson,
    List<Map<String, dynamic>> allLessons,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0x2E6366F1), Color(0x178B5CF6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '▶ كمّل من آخر مكان وصلت له',
            style: TextStyle(
              color: text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${lesson['title'] ?? ''}'
            '${lesson['chapterTitle'] != null ? ' — ${lesson['chapterTitle']}' : ''}',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => openLesson(lesson, allLessons),
            child: const Text('متابعة الدرس ←'),
          ),
        ],
      ),
    );
  }

  Widget _progress(int percent, int completed, int total) {
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'المسار الدراسي',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
              ),
              Text('$percent%'),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: percent / 100,
            minHeight: 12,
            backgroundColor: const Color(0xFF020617),
            color: primary,
          ),
          const SizedBox(height: 12),
          Text(
            'أنهيت $completed من $total درس.',
            style: const TextStyle(color: muted),
          ),
        ],
      ),
    );
  }

  Widget _content(
    List<Map<String, dynamic>> chapters,
    List<Map<String, dynamic>> allLessons,
  ) {
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '📚 محتوى الصف',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (chapters.isEmpty)
            const Text(
              'لا يوجد محتوى حتى الآن.',
              style: TextStyle(color: muted),
            ),
          ...chapters.asMap().entries.map((entry) {
            final chapter = entry.value;

            final lessons = allLessons
                .where(
                  (lesson) =>
                      lesson['chapterId'].toString() ==
                      chapter['id'].toString(),
                )
                .toList();

            return Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: const Color(0xB80F172A),
                borderRadius: BorderRadius.circular(19),
              ),
              child: ExpansionTile(
                initiallyExpanded: entry.key == 0,
                title: Text(
                  '⚡ ${chapter['title'] ?? 'Chapter'}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                children: lessons.isEmpty
                    ? const [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('لا توجد دروس داخل هذا الفصل حتى الآن.'),
                        ),
                      ]
                    : lessons
                          .map((lesson) => _lessonCard(lesson, allLessons))
                          .toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _lessonCard(
    Map<String, dynamic> lesson,
    List<Map<String, dynamic>> allLessons,
  ) {
    final completed = lesson['completed'] == true;
    final unlocked = lesson['unlocked'] == true;
    final locked = !completed && !unlocked;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFF123C2B)
            : locked
            ? const Color(0xFF111827)
            : card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: completed
              ? const Color(0xFF22C55E)
              : locked
              ? const Color(0xFF334155)
              : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${completed
                ? '✅'
                : locked
                ? '🔒'
                : '📘'} '
            '${lesson['title'] ?? ''}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            (lesson['description'] ?? 'درس فيزياء').toString(),
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 10),
          if (locked)
            const Text(
              '🔒 يجب إنهاء جميع الدروس السابقة',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: completed ? const Color(0xFF16A34A) : null,
              ),
              onPressed: () => openLesson(lesson, allLessons),
              child: Text(completed ? 'مشاهدة الدرس مرة أخرى' : 'فتح الدرس'),
            ),
        ],
      ),
    );
  }

  Widget _panel(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xE0182235),
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}
