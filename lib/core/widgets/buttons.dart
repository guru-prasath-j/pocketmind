import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Round, softly-filled icon button used in headers (search, menu, back…).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.colors.surfaceHigh,
        shape: CircleBorder(side: BorderSide(color: context.colors.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: 22, color: color ?? context.colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// A [CircleIconButton] (⋮ by default) that opens a popup menu anchored to it.
class CircleMenuButton<T> extends StatelessWidget {
  const CircleMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
    required this.tooltip,
    this.icon = Icons.more_vert_rounded,
    this.size = 48,
  });

  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;
  final String tooltip;
  final IconData icon;
  final double size;

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset(0, box.size.height + 6),
        ancestor: overlay);
    final bottomRight = box.localToGlobal(
        box.size.bottomRight(Offset.zero) + const Offset(0, 6),
        ancestor: overlay);
    final value = await showMenu<T>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      ),
      items: items,
    );
    if (value != null) onSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => CircleIconButton(
        icon: icon,
        tooltip: tooltip,
        size: size,
        onPressed: () => _open(context),
      ),
    );
  }
}

/// A consistently styled popup menu row.
PopupMenuItem<T> menuItem<T>(
  T value,
  IconData icon,
  String label, {
  bool enabled = true,
  bool destructive = false,
  bool checked = false,
}) {
  return PopupMenuItem<T>(
    value: value,
    enabled: enabled,
    child: Builder(builder: (context) {
      final color = destructive ? AppColors.danger : context.colors.textPrimary;
      return Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: destructive ? color : context.colors.accent),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: color))),
            if (checked)
              Icon(Icons.check_rounded, size: 18, color: context.colors.accent),
          ],
        ),
      );
    }),
  );
}

/// Pill-shaped primary action with the brand gradient and a soft glow.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || loading ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, color: Colors.white, size: 24),
                  if (loading || icon != null) const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
