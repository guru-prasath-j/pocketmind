import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Lightweight Markdown renderer for model answers — no extra dependency.
///
/// Supports headings (#, ##, ###), bullet and numbered lists (with nesting),
/// block quotes, fenced code blocks, and inline **bold**, *italic* and `code`.
/// Unclosed markers (common mid-stream) are shown as plain text.
class MarkdownText extends StatelessWidget {
  const MarkdownText(this.data, {super.key, this.style});

  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ??
        Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 15);
    final blocks = _parse(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) SizedBox(height: blocks[i].spaceBefore),
          blocks[i].build(context, base),
        ],
      ],
    );
  }

  static final _bullet = RegExp(r'^(\s*)[-*•+]\s+(.*)$');
  static final _numbered = RegExp(r'^(\s*)(\d+)[.)]\s+(.*)$');
  static final _heading = RegExp(r'^(#{1,6})\s+(.*)$');

  List<_Block> _parse(String src) {
    final lines = src.replaceAll('\r\n', '\n').split('\n');
    final blocks = <_Block>[];
    final paragraph = <String>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      blocks.add(_Paragraph(paragraph.join(' ')));
      paragraph.clear();
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.startsWith('```')) {
        flushParagraph();
        final code = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          code.add(lines[i]);
          i++;
        }
        blocks.add(_Code(code.join('\n')));
        continue;
      }
      if (trimmed.isEmpty) {
        flushParagraph();
        continue;
      }
      final h = _heading.firstMatch(trimmed);
      if (h != null) {
        flushParagraph();
        blocks.add(_Heading(h.group(2)!, h.group(1)!.length));
        continue;
      }
      final b = _bullet.firstMatch(line);
      if (b != null && !_isHorizontalRule(trimmed)) {
        flushParagraph();
        blocks.add(_ListItem(b.group(2)!, '•', _indent(b.group(1)!)));
        continue;
      }
      final n = _numbered.firstMatch(line);
      if (n != null) {
        flushParagraph();
        blocks.add(_ListItem(n.group(3)!, '${n.group(2)}.', _indent(n.group(1)!)));
        continue;
      }
      if (trimmed.startsWith('>')) {
        flushParagraph();
        blocks.add(_Quote(trimmed.replaceFirst(RegExp(r'^>\s?'), '')));
        continue;
      }
      if (_isHorizontalRule(trimmed)) {
        flushParagraph();
        blocks.add(_Rule());
        continue;
      }
      paragraph.add(trimmed);
    }
    flushParagraph();
    return blocks;
  }

  static bool _isHorizontalRule(String s) =>
      RegExp(r'^([-*_])(\s*\1){2,}$').hasMatch(s);

  static int _indent(String ws) => (ws.replaceAll('\t', '    ').length ~/ 2).clamp(0, 4);
}

/// Inline formatting: **bold**, *italic*, `code`. Underscore emphasis is
/// deliberately not supported so identifiers like snake_case stay intact.
List<InlineSpan> _inline(BuildContext context, String text, TextStyle base) {
  final pattern = RegExp(r'(\*\*(.+?)\*\*)|(`([^`]+)`)|(\*(?!\s)(.+?)(?<!\s)\*)');
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    if (m.group(2) != null) {
      spans.add(TextSpan(
        children: _inline(context, m.group(2)!, base),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
    } else if (m.group(4) != null) {
      spans.add(TextSpan(
        text: m.group(4),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: (base.fontSize ?? 15) * 0.9,
          color: context.colors.codeText,
          backgroundColor: context.colors.surfaceHighest,
        ),
      ));
    } else if (m.group(6) != null) {
      spans.add(TextSpan(
        text: m.group(6),
        style: const TextStyle(fontStyle: FontStyle.italic),
      ));
    }
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans;
}

sealed class _Block {
  double get spaceBefore => 10;
  Widget build(BuildContext context, TextStyle base);
}

class _Paragraph extends _Block {
  _Paragraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context, TextStyle base) =>
      Text.rich(TextSpan(children: _inline(context, text, base)), style: base);
}

class _Heading extends _Block {
  _Heading(this.text, this.level);
  final String text;
  final int level;

  @override
  double get spaceBefore => 16;

  @override
  Widget build(BuildContext context, TextStyle base) {
    final size = (base.fontSize ?? 15) + switch (level) { 1 => 6, 2 => 4, _ => 2 };
    return Text.rich(
      TextSpan(children: _inline(context, text, base)),
      style: base.copyWith(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: context.colors.textPrimary,
      ),
    );
  }
}

class _ListItem extends _Block {
  _ListItem(this.text, this.marker, this.depth);
  final String text;
  final String marker;
  final int depth;

  @override
  double get spaceBefore => 6;

  @override
  Widget build(BuildContext context, TextStyle base) {
    final isBullet = marker == '•';
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isBullet ? 18 : 24,
            child: Text(
              marker,
              style: base.copyWith(
                color: context.colors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text.rich(TextSpan(children: _inline(context, text, base)), style: base),
          ),
        ],
      ),
    );
  }
}

class _Quote extends _Block {
  _Quote(this.text);
  final String text;

  @override
  Widget build(BuildContext context, TextStyle base) => Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: context.colors.accent, width: 3)),
        ),
        child: Text.rich(
          TextSpan(children: _inline(context, text, base)),
          style: base.copyWith(
            fontStyle: FontStyle.italic,
            color: context.colors.textSecondary,
          ),
        ),
      );
}

class _Code extends _Block {
  _Code(this.code);
  final String code;

  @override
  double get spaceBefore => 12;

  @override
  Widget build(BuildContext context, TextStyle base) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.colors.backgroundDeep,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Text(
            code,
            style: base.copyWith(
              fontFamily: 'monospace',
              fontSize: (base.fontSize ?? 15) * 0.88,
              height: 1.45,
              color: context.colors.codeText,
            ),
          ),
        ),
      );
}

class _Rule extends _Block {
  @override
  Widget build(BuildContext context, TextStyle base) => const Divider(height: 8);
}
