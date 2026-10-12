import 'package:flutter/material.dart';
import '../data.dart';
import '../store.dart';

class CareScreen extends StatelessWidget {
  const CareScreen({super.key, required this.store, required this.openChapter});
  final Store store;
  final void Function(int chapterNum) openChapter;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final wk = store.weekChecked;
          final mo = store.monthChecked;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Care checklists',
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
              const SizedBox(height: 4),
              Text('Weekly ticks reset every Monday, monthly ticks on the 1st.', style: tt.bodyMedium),
              const SizedBox(height: 14),
              _section(context, 'This week', Icons.event_repeat, weeklyItems, wk, store.toggleWeek),
              const SizedBox(height: 14),
              _section(context, 'This month', Icons.calendar_month, monthlyItems, mo, store.toggleMonth),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: store.resetChecklists,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset all'),
                ),
              ),
              const SizedBox(height: 10),
              Text('Need help?', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _link(context, Icons.healing, 'Troubleshooting guide', 'Quick answers to common problems', 23),
              _link(context, Icons.bug_report, 'Pests and diseases', 'Prevention first, gentle treatment second', 14),
              _link(context, Icons.eco, 'Seasonal gardening in North India', 'Grow with the seasons', 19),
              _link(context, Icons.calendar_today, 'A 30-day beginner plan', 'Small daily steps, big results', 24),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _section(BuildContext context, String title, IconData icon, List<String> items, Set<String> checked,
      Future<void> Function(String) toggle) {
    final cs = Theme.of(context).colorScheme;
    final n = items.where(checked.contains).length;
    return Card(
      elevation: 0,
      color: cs.primaryContainer.withAlpha(140),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
              child: Row(
                children: [
                  Icon(icon, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  Text('$n/${items.length}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            for (final it in items)
              CheckboxListTile(
                value: checked.contains(it),
                onChanged: (_) => toggle(it),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(it),
              ),
          ],
        ),
      ),
    );
  }

  Widget _link(BuildContext context, IconData icon, String title, String sub, int chapter) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openChapter(chapter),
      ),
    );
  }
}
