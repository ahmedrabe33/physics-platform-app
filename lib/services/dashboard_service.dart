import 'api_service.dart';

class DashboardService {
  final ApiService api = ApiService();

  Future<Map<String, dynamic>> loadDashboard(Map<String, dynamic> user) async {
    final userId = user['userId'] ?? user['id'];
    final grade = user['grade']?.toString() ?? 'second';

    final accessStatus = await api.getAccessStatus(userId);

    if (accessStatus == 'pending' ||
        accessStatus == 'rejected' ||
        accessStatus == 'expired') {
      return {'accessStatus': accessStatus};
    }

    final results = await Future.wait([
      api.getStudent(userId),
      api.getContent(grade),
      api.getProgress(userId),
    ]);

    final student = Map<String, dynamic>.from(results[0] as Map);
    final content = Map<String, dynamic>.from(results[1] as Map);
    final progress = List<dynamic>.from(results[2] as List);

    final chapters = ((content['chapters'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    chapters.sort((a, b) => _order(a).compareTo(_order(b)));

    final List<Map<String, dynamic>> lessons = [];

    for (final chapter in chapters) {
      final chapterLessons = ((chapter['lessons'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      chapterLessons.sort((a, b) => _order(a).compareTo(_order(b)));

      for (final lesson in chapterLessons) {
        lessons.add({
          ...lesson,
          'chapterId': chapter['id'],
          'chapterTitle': chapter['title'],
        });
      }
    }

    bool completed(Map<String, dynamic> lesson) {
      return progress.any((item) {
        if (item is! Map) return false;
        return item['lessonId'].toString() == lesson['id'].toString() &&
            item['completed'] == true;
      });
    }

    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      final isCompleted = completed(lesson);
      final previousCompleted = i == 0 ? true : completed(lessons[i - 1]);

      lesson['completed'] = isCompleted;
      lesson['unlocked'] = i == 0 || isCompleted || previousCompleted;
    }

    final completedCount = lessons.where((e) => e['completed'] == true).length;

    final totalLessons = lessons.length;

    final progressPercent = totalLessons == 0
        ? 0
        : ((completedCount / totalLessons) * 100).round();

    Map<String, dynamic>? continueLesson;

    for (final lesson in lessons) {
      if (lesson['unlocked'] == true && lesson['completed'] != true) {
        continueLesson = lesson;
        break;
      }
    }

    if (continueLesson == null) {
      final done = lessons.where((e) => e['completed'] == true).toList();
      if (done.isNotEmpty) continueLesson = done.last;
    }

    return {
      'accessStatus': accessStatus,
      'student': student,
      'chapters': chapters,
      'lessons': lessons,
      'progress': progress,
      'completedCount': completedCount,
      'totalLessons': totalLessons,
      'progressPercent': progressPercent,
      'continueLesson': continueLesson,
      'allLessonsCompleted': totalLessons > 0 && completedCount == totalLessons,
    };
  }

  int _order(Map<String, dynamic> item) {
    final value =
        item['lessonOrder'] ??
        item['chapterOrder'] ??
        item['topicOrder'] ??
        item['order'] ??
        0;

    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }
}
