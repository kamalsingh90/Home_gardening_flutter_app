import 'package:flutter/material.dart';
import '../data.dart';
import '../store.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.store, required this.content, required this.openChapter});
  final Store store;
  final Content content;
  final void Function(int chapterNum) openChapter;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;
        final now = DateTime.now();
        final tip = content.tips[tipIndexFor(now, content.tips.length)];
        final tasks = dailyTasks[now.weekday - 1];
        final done = store.doneFor(now);
        final streak = store.streak;
        final last = content.chapters[content.indexOfNum(store.lastChapter)];

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---- hero ----
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_greeting()}, gardener! 🌱',
                              style: tt.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(
                            '${weekdayNames[now.weekday - 1]}, ${now.day} ${monthNames[now.month - 1]}',
                            style: tt.bodyMedium?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              streak > 0 ? '🔥 $streak day streak' : 'Finish a task to start a streak',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset('assets/images/cover.jpg', height: 112, fit: BoxFit.cover),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ---- tip of the day ----
              Card(
                elevation: 0,
                color: cs.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.wb_sunny_outlined, color: cs.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Text("Today's garden tip",
                            style: tt.labelLarge?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 10),
                      Text(tip.title,
                          style: tt.titleLarge?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(tip.body, style: tt.bodyLarge?.copyWith(color: cs.onPrimaryContainer, height: 1.45)),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => openChapter(tip.chapter),
                          icon: const Icon(Icons.menu_book),
                          label: Text('Read chapter ${tip.chapter}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ---- today's tasks ----
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text("Today's 3 easy tasks",
                                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            Text('${done.length}/3',
                                style: tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      for (var i = 0; i < tasks.length; i++)
                        CheckboxListTile(
                          value: done.contains('$i'),
                          onChanged: (_) => store.toggleTask(now, '$i'),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            tasks[i],
                            style: TextStyle(
                              decoration: done.contains('$i') ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      if (done.length == 3)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                          child: Text('All done. Your plants say thank you! 🌿',
                              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ---- continue reading ----
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  leading: Icon(Icons.auto_stories, color: cs.primary, size: 32),
                  title: const Text('Continue reading', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(last.num > 0 ? '${last.num}. ${last.title}' : last.title),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => openChapter(last.num),
                ),
              ),
              const SizedBox(height: 18),

              // ---- quick help ----
              Text('Quick help', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Watering', Icons.water_drop, 8),
                  _chip('Sunlight', Icons.wb_sunny, 9),
                  _chip('Pests', Icons.bug_report, 14),
                  _chip('Problems', Icons.healing, 23),
                  _chip('30-day plan', Icons.calendar_month, 24),
                  _chip('FAQ', Icons.help_outline, 27),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, IconData icon, int chapter) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => openChapter(chapter),
    );
  }
}
