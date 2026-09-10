import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

class LessonScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> lessonSummary;
  final dynamic previousLessonId;

  const LessonScreen({
    super.key,
    required this.user,
    required this.lessonSummary,
    this.previousLessonId,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final api = ApiService();
  late Future<Map<String, dynamic>> future;

  final Map<String, TextEditingController> answers = {};
  final Map<String, bool?> results = {};

  @override
  void initState() {
    super.initState();
    future = api.getLesson(
      widget.user['grade']?.toString() ?? 'second',
      widget.lessonSummary['id'],
    );
  }

  @override
  void dispose() {
    for (final controller in answers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> openVideo(String url, {dynamic topicId}) async {
    final userId = widget.user['userId'] ?? widget.user['id'];

    await api.trackVideoView(
      userId: userId,
      lessonId: widget.lessonSummary['id'],
      topicId: topicId,
      videoUrl: url,
    );

    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void checkAnswer(Map<String, dynamic> exercise) {
    final id = exercise['id'].toString();
    final submitted = (answers[id]?.text ?? '').trim().toLowerCase();
    final correct = (exercise['correctAnswer'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    setState(() {
      results[id] = submitted == correct;
    });
  }

  Future<void> complete() async {
    try {
      await api.completeLesson(
        userId: widget.user['userId'] ?? widget.user['id'],
        lessonId: widget.lessonSummary['id'],
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString(), textDirection: TextDirection.rtl)),
      );
    }
  }

  Widget panel(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xE0182235),
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFFF8FAFC);
    const muted = Color(0xFF94A3B8);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        appBar: AppBar(title: const Text('⚛ physics')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: Color(0xFFFECACA)),
                ),
              );
            }

            final lesson = snapshot.data!;

            final topics = ((lesson['topics'] as List?) ?? [])
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

            final exercises = ((lesson['exercises'] as List?) ?? [])
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

            return Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [Color(0xFF1E1B4B), Color(0xFF0B1020)],
                  stops: [0, .55],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Color(0x296366F1), Color(0x148B5CF6)],
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'الدرس ${lesson['order'] ?? lesson['lessonOrder'] ?? ''}',
                                style: const TextStyle(
                                  color: Color(0xFFC7D2FE),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                lesson['title']?.toString() ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: text,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if ((lesson['description'] ?? '')
                                  .toString()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  lesson['description'].toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: muted,
                                    height: 1.8,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        panel(
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🎯', style: TextStyle(fontSize: 28)),
                              SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'شاهد أجزاء الدرس، ثم أكمل التدريبات واضغط على إنهاء الدرس.',
                                  style: TextStyle(color: muted, height: 1.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (topics.isNotEmpty)
                          panel(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'موضوعات الدرس — ${topics.length} جزء',
                                  style: const TextStyle(
                                    color: text,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ...topics.map((topic) {
                                  final url =
                                      topic['videoUrl']?.toString() ?? '';

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xCC0F172A),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          '${topic['order'] ?? topic['topicOrder'] ?? ''} ${topic['title'] ?? ''}',
                                          style: const TextStyle(
                                            color: text,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        if ((topic['description'] ?? '')
                                            .toString()
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            topic['description'].toString(),
                                            style: const TextStyle(
                                              color: muted,
                                              height: 1.7,
                                            ),
                                          ),
                                        ],
                                        if (url.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          ElevatedButton.icon(
                                            onPressed: () => openVideo(
                                              url,
                                              topicId: topic['id'],
                                            ),
                                            icon: const Icon(Icons.play_arrow),
                                            label: const Text('فتح الفيديو'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          )
                        else if ((lesson['videoUrl'] ?? '')
                            .toString()
                            .isNotEmpty)
                          panel(
                            ElevatedButton.icon(
                              onPressed: () =>
                                  openVideo(lesson['videoUrl'].toString()),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('فتح الفيديو'),
                            ),
                          ),
                        panel(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'تدريبات الدرس — ${exercises.length} سؤال',
                                style: const TextStyle(
                                  color: text,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (exercises.isEmpty)
                                const Text(
                                  'لا توجد تدريبات لهذا الدرس حتى الآن.',
                                  style: TextStyle(color: muted),
                                ),
                              ...exercises.map((exercise) {
                                final id = exercise['id'].toString();

                                answers.putIfAbsent(
                                  id,
                                  () => TextEditingController(),
                                );

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xCC0F172A),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'سؤال ${exercise['order'] ?? ''}',
                                        style: const TextStyle(
                                          color: Color(0xFFA5B4FC),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        exercise['question']?.toString() ?? '',
                                        style: const TextStyle(
                                          color: text,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: answers[id],
                                        decoration: const InputDecoration(
                                          hintText: 'اكتب إجابتك هنا...',
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ElevatedButton(
                                        onPressed: () => checkAnswer(exercise),
                                        child: const Text('تحقق'),
                                      ),
                                      if (results[id] != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          results[id] == true
                                              ? '✅ إجابة صحيحة'
                                              : '❌ إجابة غير صحيحة — الإجابة الصحيحة: ${exercise['correctAnswer'] ?? ''}',
                                          style: TextStyle(
                                            color: results[id] == true
                                                ? const Color(0xFFBBF7D0)
                                                : const Color(0xFFFECACA),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: complete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                            child: const Text(
                              '✓ أنهيت الدرس — العودة إلى قائمة الدروس',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
