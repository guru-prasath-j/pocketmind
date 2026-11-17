import 'package:flutter/material.dart';

import '../constants.dart';
import '../theme/app_theme.dart';

/// The PocketMind app mark: a glowing violet tile with a chat bubble + sparkle.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: size * 0.45,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white,
            size: size * 0.55,
          ),
          Positioned(
            top: size * 0.12,
            right: size * 0.12,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: size * 0.26,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Pocket" in white + "Mind" in the violet gradient.
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.fontSize = 26});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: context.colors.textPrimary,
    );
    return Semantics(
      label: AppConstants.appName,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Pocket', style: style),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: context.colors.textGradient.createShader,
            child: Text('Mind', style: style),
          ),
        ],
      ),
    );
  }
}

/// Soft violet glows painted behind a screen — the "ambient" layer from the
/// design. Purely visual; ignores pointer events.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [context.colors.background, context.colors.backgroundDeep],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: -160,
            bottom: -120,
            child: IgnorePointer(child: _Glow(size: 420, alpha: 0.16)),
          ),
          const Positioned(
            right: -140,
            top: -160,
            child: IgnorePointer(child: _Glow(size: 360, alpha: 0.10)),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary
                .withValues(alpha: alpha * context.colors.glowStrength),
            AppColors.primary.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
