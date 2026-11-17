import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Friendly robot reading a book, flanked by a chat bubble and a PDF tile.
/// Built from widgets + a painter (no image assets) and gently floats.
class AssistantIllustration extends StatefulWidget {
  const AssistantIllustration({super.key, this.size = 240});

  final double size;

  @override
  State<AssistantIllustration> createState() => _AssistantIllustrationState();
}

class _AssistantIllustrationState extends State<AssistantIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return ExcludeSemantics(
      child: SizedBox(
        width: s * 1.35,
        height: s,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value * 2 * math.pi;
            final bob = math.sin(t) * s * 0.025;
            final drift = math.sin(t + 1.4) * s * 0.03;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Glow
                Container(
                  width: s * 0.95,
                  height: s * 0.95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.primary.withValues(alpha: 0.35),
                      AppColors.primary.withValues(alpha: 0),
                    ]),
                  ),
                ),
                // Platform
                Positioned(
                  bottom: s * 0.04,
                  child: Container(
                    width: s * 0.78,
                    height: s * 0.12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                          Radius.elliptical(s * 0.39, s * 0.06)),
                      gradient: LinearGradient(colors: [
                        AppColors.primaryDeep.withValues(alpha: 0.2),
                        AppColors.primary.withValues(alpha: 0.55),
                        AppColors.primaryDeep.withValues(alpha: 0.2),
                      ]),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, bob),
                  child: _Robot(size: s * 0.72),
                ),
                Positioned(
                  left: s * 0.02,
                  top: s * 0.12 + drift,
                  child: Transform.rotate(
                    angle: -0.18,
                    child: _ChatBubble(size: s * 0.3),
                  ),
                ),
                Positioned(
                  right: s * 0.02,
                  top: s * 0.04 - drift,
                  child: Transform.rotate(
                    angle: 0.2,
                    child: _PdfTile(size: s * 0.3),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Robot extends StatelessWidget {
  const _Robot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size;
    const shell = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Color(0xFFDCD3FF)],
    );
    return SizedBox(
      width: s,
      height: s * 1.05,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Antenna
          Positioned(
            top: 0,
            child: Column(children: [
              Container(
                width: s * 0.1,
                height: s * 0.1,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: shell,
                ),
              ),
              Container(width: s * 0.03, height: s * 0.08, color: AppColors.lavenderLight),
            ]),
          ),
          // Body
          Positioned(
            top: s * 0.62,
            child: Container(
              width: s * 0.56,
              height: s * 0.36,
              decoration: BoxDecoration(
                gradient: shell,
                borderRadius: BorderRadius.circular(s * 0.16),
              ),
            ),
          ),
          // Head
          Positioned(
            top: s * 0.16,
            child: Container(
              width: s * 0.74,
              height: s * 0.54,
              decoration: BoxDecoration(
                gradient: shell,
                borderRadius: BorderRadius.circular(s * 0.26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: s * 0.15,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Container(
                width: s * 0.56,
                height: s * 0.36,
                decoration: BoxDecoration(
                  color: AppColors.onLavender,
                  borderRadius: BorderRadius.circular(s * 0.18),
                ),
                child: CustomPaint(painter: _FacePainter()),
              ),
            ),
          ),
          // Ears
          for (final dx in [-1.0, 1.0])
            Positioned(
              top: s * 0.33,
              left: dx < 0 ? s * 0.06 : null,
              right: dx > 0 ? s * 0.06 : null,
              child: Container(
                width: s * 0.08,
                height: s * 0.2,
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(s * 0.04),
                ),
              ),
            ),
          // Book
          Positioned(
            top: s * 0.7,
            child: Container(
              width: s * 0.5,
              height: s * 0.32,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(s * 0.05),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDeep.withValues(alpha: 0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 2,
                  height: s * 0.26,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two happy "^ ^" eyes.
class _FacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lavenderLight
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.06;
    final r = size.width * 0.11;
    for (final cx in [size.width * 0.32, size.width * 0.68]) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, size.height * 0.6), radius: r),
        math.pi,
        math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.72,
      padding: EdgeInsets.symmetric(horizontal: size * 0.16),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final w in [1.0, 0.85, 0.6])
            Container(
              margin: EdgeInsets.symmetric(vertical: size * 0.03),
              width: size * 0.68 * w,
              height: size * 0.05,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

class _PdfTile extends StatelessWidget {
  const _PdfTile({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.82,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: size * 0.38),
          SizedBox(height: size * 0.04),
          Container(
            padding: EdgeInsets.symmetric(horizontal: size * 0.08, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.pdfRed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'PDF',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
