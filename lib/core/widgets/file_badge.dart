import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../theme/app_theme.dart';

/// A file-type tile: red "PDF" page for PDFs, violet/teal for text formats.
class FileBadge extends StatelessWidget {
  const FileBadge({super.key, required this.fileName, this.size = 56});

  final String fileName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ext = p.extension(fileName).replaceFirst('.', '').toUpperCase();
    final label = ext.isEmpty ? 'DOC' : ext;
    final gradient = switch (label) {
      'PDF' => AppColors.pdfGradient,
      'MD' => const LinearGradient(
          colors: [Color(0xFF22D3EE), Color(0xFF0891B2)],
        ),
      _ => AppColors.brandGradient,
    };

    return SizedBox(
      width: size * 0.82,
      height: size,
      child: CustomPaint(
        painter: _PagePainter(gradient),
        child: Align(
          alignment: const Alignment(0, 0.35),
          child: Text(
            label.length > 4 ? label.substring(0, 4) : label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.25,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a page with a folded top-right corner.
class _PagePainter extends CustomPainter {
  _PagePainter(this.gradient);

  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final fold = size.width * 0.32;
    const r = 7.0;
    final rect = Offset.zero & size;
    final page = Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - fold, 0)
      ..lineTo(size.width, fold)
      ..lineTo(size.width, size.height - r)
      ..quadraticBezierTo(size.width, size.height, size.width - r, size.height)
      ..lineTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();

    canvas.drawShadow(page, gradient.colors.last, 6, false);
    canvas.drawPath(page, Paint()..shader = gradient.createShader(rect));

    final corner = Path()
      ..moveTo(size.width - fold, 0)
      ..lineTo(size.width - fold, fold - r)
      ..quadraticBezierTo(size.width - fold, fold, size.width - fold + r, fold)
      ..lineTo(size.width, fold)
      ..close();
    canvas.drawPath(
      corner,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_PagePainter old) => old.gradient != gradient;
}
