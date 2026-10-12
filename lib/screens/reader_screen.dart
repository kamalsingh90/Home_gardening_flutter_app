import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data.dart';
import '../store.dart';
import '../widgets/blocks.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.content, required this.store, required this.startIndex});
  final Content content;
  final Store store;
  final int startIndex;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late int _i;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _i = widget.startIndex;
    _visit();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _visit() {
    final c = widget.content.chapters[_i];
    if (c.num > 0) widget.store.setLastChapter(c.num);
  }

  void _go(int delta) {
    final n = _i + delta;
    if (n < 0 || n >= widget.content.chapters.length) return;
    setState(() => _i = n);
    _visit();
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = widget.content.chapters[_i];
    final isLast = _i == widget.content.chapters.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.num > 0 ? 'Chapter ${c.num} of ${widget.content.bookChapters}' : 'About this book'),
        actions: [
          IconButton(
            tooltip: 'Smaller text',
            icon: const Icon(Icons.text_decrease),
            onPressed: () => widget.store.setFontScale(math.max(0.85, widget.store.fontScale - 0.1)),
          ),
          IconButton(
            tooltip: 'Larger text',
            icon: const Icon(Icons.text_increase),
            onPressed: () => widget.store.setFontScale(math.min(1.6, widget.store.fontScale + 0.1)),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final scale = widget.store.fontScale;
          return ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              Text(
                c.title,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 27 * scale,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              if (c.tagline.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  c.tagline,
                  style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w600, color: cs.secondary),
                ),
              ],
              const SizedBox(height: 10),
              Divider(color: cs.primary, thickness: 1.5),
              const SizedBox(height: 10),
              for (final b in c.blocks) BlockView(block: b, scale: scale),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_i > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _go(-1),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                    ),
                  if (_i > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await widget.store.markRead(c.num);
                        if (isLast) {
                          if (context.mounted) Navigator.pop(context);
                        } else {
                          _go(1);
                        }
                      },
                      icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                      label: Text(isLast ? 'Mark as read' : 'Mark read & next'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
