import 'package:flutter/material.dart';

/// Parses the tiny markup used in the book text: <b>, <i> and <br/>.
List<InlineSpan> parseMarkup(String s, TextStyle base) {
  final spans = <InlineSpan>[];
  var bold = false;
  var italic = false;
  void add(String t) {
    if (t.isEmpty) return;
    final text = t.replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>');
    spans.add(TextSpan(
      text: text,
      style: base.copyWith(
        fontWeight: bold ? FontWeight.bold : null,
        fontStyle: italic ? FontStyle.italic : null,
      ),
    ));
  }

  final re = RegExp(r'<[^>]+>');
  var pos = 0;
  for (final m in re.allMatches(s)) {
    add(s.substring(pos, m.start));
    final tag = m.group(0)!.toLowerCase();
    if (tag == '<b>') {
      bold = true;
    } else if (tag == '</b>') {
      bold = false;
    } else if (tag == '<i>') {
      italic = true;
    } else if (tag == '</i>') {
      italic = false;
    } else if (tag.startsWith('<br')) {
      add('\n');
    }
    pos = m.end;
  }
  add(s.substring(pos));
  return spans;
}

class BlockView extends StatelessWidget {
  const BlockView({super.key, required this.block, required this.scale});
  final Map<String, dynamic> block;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = TextStyle(fontSize: 16 * scale, height: 1.5, color: cs.onSurface);

    switch (block['t'] as String) {
      case 'p':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text.rich(TextSpan(children: parseMarkup(block['text'] as String, base))),
        );

      case 'h2':
        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Text(
            block['text'] as String,
            style: base.copyWith(fontSize: 19 * scale, fontWeight: FontWeight.bold, color: cs.primary),
          ),
        );

      case 'quote':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              block['text'] as String,
              textAlign: TextAlign.center,
              style: base.copyWith(
                fontFamily: 'serif',
                fontSize: 22 * scale,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
        );

      case 'bullets':
        final items = (block['items'] as List<dynamic>).cast<String>();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              for (final it in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3, right: 10),
                        child: Icon(Icons.check_circle, size: 18 * scale, color: cs.primary),
                      ),
                      Expanded(child: Text.rich(TextSpan(children: parseMarkup(it, base)))),
                    ],
                  ),
                ),
            ],
          ),
        );

      case 'tip':
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: cs.onSecondaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(TextSpan(
                  children: [
                    TextSpan(text: 'Tip: ', style: base.copyWith(fontWeight: FontWeight.bold, color: cs.onSecondaryContainer)),
                    ...parseMarkup(block['text'] as String, base.copyWith(color: cs.onSecondaryContainer)),
                  ],
                )),
              ),
            ],
          ),
        );

      case 'box':
        final kids = (block['children'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((block['title'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    block['title'] as String,
                    style: base.copyWith(fontSize: 17 * scale, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
                  ),
                ),
              for (final k in kids)
                DefaultTextStyle.merge(
                  style: TextStyle(color: cs.onPrimaryContainer),
                  child: BlockView(block: k, scale: scale),
                ),
            ],
          ),
        );

      case 'table':
        final head = (block['head'] as List<dynamic>).cast<String>();
        final rows = (block['rows'] as List<dynamic>).map((r) => (r as List<dynamic>).cast<String>()).toList();
        final cellStyle = base.copyWith(fontSize: 14 * scale, height: 1.35);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Table(
              defaultColumnWidth: const FlexColumnWidth(),
              border: TableBorder(horizontalInside: BorderSide(color: cs.outlineVariant, width: 0.8)),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: cs.primary),
                  children: [
                    for (final h in head)
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(h, style: cellStyle.copyWith(fontWeight: FontWeight.bold, color: cs.onPrimary)),
                      ),
                  ],
                ),
                for (var r = 0; r < rows.length; r++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: r.isOdd ? cs.primaryContainer.withAlpha(90) : Colors.transparent,
                    ),
                    children: [
                      for (var c = 0; c < rows[r].length; c++)
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            rows[r][c],
                            style: c == 0
                                ? cellStyle.copyWith(fontWeight: FontWeight.bold, color: cs.primary)
                                : cellStyle,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );

      case 'image':
        final ar = (block['ar'] as num).toDouble();
        final tall = ar > 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: tall
                  ? SizedBox(
                      width: 220,
                      height: 220,
                      child: Image.asset('assets/images/${block['name']}.jpg', fit: BoxFit.cover),
                    )
                  : Image.asset(
                      'assets/images/${block['name']}.jpg',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
            ),
          ),
        );

      case 'gallery':
        final gItems = (block['items'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: LayoutBuilder(
            builder: (context, c) {
              final perRow = gItems.length >= 3 ? 3 : gItems.length;
              final w = (c.maxWidth - 12.0 * (perRow - 1)) / perRow - 0.5;
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 14,
                children: [
                  for (final it in gItems)
                    SizedBox(
                      width: w,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Image.asset('assets/images/${it['name']}.jpg', fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            it['caption'] as String,
                            textAlign: TextAlign.center,
                            style: base.copyWith(fontSize: 12.5 * scale, height: 1.25),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        );
    }
    return const SizedBox.shrink();
  }
}
