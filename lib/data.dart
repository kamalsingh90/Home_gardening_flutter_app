import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Tip {
  Tip(this.title, this.body, this.chapter);
  final String title;
  final String body;
  final int chapter;
}

class Chapter {
  Chapter({
    required this.num,
    required this.title,
    required this.tagline,
    required this.blocks,
  });
  final int num;
  final String title;
  final String tagline;
  final List<Map<String, dynamic>> blocks;
}

class Content {
  Content(this.chapters, this.tips);
  final List<Chapter> chapters;
  final List<Tip> tips;

  static Future<Content> load() async {
    final cj = jsonDecode(await rootBundle.loadString('assets/chapters.json')) as List<dynamic>;
    final chapters = cj.map((e) {
      final m = e as Map<String, dynamic>;
      final blocks = (m['blocks'] as List<dynamic>)
          .map((b) => Map<String, dynamic>.from(b as Map))
          .toList();
      return Chapter(
        num: m['num'] as int,
        title: m['title'] as String,
        tagline: (m['tagline'] ?? '') as String,
        blocks: blocks,
      );
    }).toList();
    // Chapter 0 is the copyright page: keep it at the end of the list.
    chapters.sort((a, b) {
      if (a.num == 0) return 1;
      if (b.num == 0) return -1;
      return a.num.compareTo(b.num);
    });
    final tj = jsonDecode(await rootBundle.loadString('assets/tips.json')) as List<dynamic>;
    final tips = tj.map((e) {
      final m = e as Map<String, dynamic>;
      return Tip(m['title'] as String, m['body'] as String, m['chapter'] as int);
    }).toList();
    return Content(chapters, tips);
  }

  int indexOfNum(int n) {
    final i = chapters.indexWhere((c) => c.num == n);
    return i < 0 ? 0 : i;
  }

  int get bookChapters => chapters.where((c) => c.num > 0).length;
}

String two(int n) => n < 10 ? '0$n' : '$n';
String dateKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

/// Same tip for the same calendar day, used by both the Today screen and notifications.
int tipIndexFor(DateTime d, int len) {
  final days = DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2026, 1, 1)).inDays;
  return ((days % len) + len) % len;
}

const List<String> weekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];
const List<String> monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

/// Three easy care tasks for each weekday (index 0 = Monday).
const List<List<String>> dailyTasks = [
  ['Do the finger test on each pot', 'Look under a few leaves for pests', 'Give one pot a quarter turn'],
  ['Water the plants that feel dry', 'Remove dead leaves and flowers', 'Wipe dust off one plant'],
  ['Check drainage holes and saucers', 'Pinch the tips of a herb', 'Write one note in your garden diary'],
  ['Check soil moisture before watering', 'Look for new growth and flowers', 'Move any plant that looks unhappy'],
  ['Water early or in the evening', 'Deadhead faded flowers', 'Check stakes and supports'],
  ['Spend 10 minutes on a garden walk', 'Top up mulch or compost on one pot', 'Take a photo to track growth'],
  ['Rest and enjoy your plants', 'Plan one change for next week', 'Read one short chapter'],
];

const List<String> weeklyItems = [
  'Water plants as needed',
  'Check for pests',
  'Remove dead leaves',
  'Lightly feed (growth season)',
  'Clean leaves',
];
const List<String> monthlyItems = [
  'Repot if needed',
  'Prune and shape',
  'Check soil / refresh topsoil',
  'Refresh compost or mulch',
  'Plan the next season',
];
