import 'package:flutter/material.dart';
import '../data.dart';
import '../store.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.store, required this.content, required this.openChapter});
  final Store store;
  final Content content;
  final void Function(int chapterNum) openChapter;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final read = widget.store.readChapters;
          final total = widget.content.bookChapters;
          final readCount = read.where((n) => n > 0).length;
          final list = widget.content.chapters.where((c) {
            if (_q.isEmpty) return true;
            final q = _q.toLowerCase();
            return c.title.toLowerCase().contains(q) || c.tagline.toLowerCase().contains(q);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Home Gardening for Beginners',
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
              const SizedBox(height: 4),
              Text('A practical step-by-step guide to growing healthy plants at home',
                  style: tt.bodyMedium),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: total == 0 ? 0 : readCount / total, minHeight: 10),
              ),
              const SizedBox(height: 6),
              Text('$readCount of $total chapters read', style: tt.bodySmall),
              const SizedBox(height: 14),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search chapters',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
              const SizedBox(height: 10),
              for (final c in list)
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: cs.surfaceContainerHighest.withAlpha(120),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: read.contains(c.num) ? cs.primary : cs.primaryContainer,
                      foregroundColor: read.contains(c.num) ? cs.onPrimary : cs.onPrimaryContainer,
                      child: read.contains(c.num)
                          ? const Icon(Icons.check)
                          : Text(c.num > 0 ? '${c.num}' : '©'),
                    ),
                    title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: c.tagline.isEmpty ? null : Text(c.tagline),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => widget.openChapter(c.num),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
