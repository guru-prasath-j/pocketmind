import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pressable.dart';

/// A starter prompt. When [prompt] is null, tapping focuses the input instead
/// of sending (the "Ask anything…" card).
class Suggestion {
  const Suggestion(this.icon, this.label, this.prompt);

  final IconData icon;
  final String label;
  final String? prompt;
}

const kSuggestions = [
  Suggestion(
    Icons.auto_awesome,
    'Summarize this document',
    'Summarize this document in a few clear bullet points.',
  ),
  Suggestion(
    Icons.help_outline_rounded,
    'Explain key concepts',
    'Explain the key concepts in this document in simple terms.',
  ),
  Suggestion(
    Icons.lightbulb_outline_rounded,
    'Generate notes',
    'Generate concise study notes from this document.',
  ),
  Suggestion(Icons.format_list_bulleted_rounded, 'Ask anything…', null),
];

/// Two-column grid of suggestion cards (one column on very narrow screens).
class SuggestionGrid extends StatelessWidget {
  const SuggestionGrid({
    super.key,
    required this.onSelected,
    this.enabled = true,
  });

  final ValueChanged<Suggestion> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 12.0;
      final columns = c.maxWidth < 300 ? 1 : 2;
      final width = (c.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final s in kSuggestions)
            SizedBox(
              width: width,
              child: _SuggestionCard(
                suggestion: s,
                onTap: enabled ? () => onSelected(s) : null,
              ),
            ),
        ],
      );
    });
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.onTap});

  final Suggestion suggestion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusPill);
    return Semantics(
      button: true,
      child: Material(
        color: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: context.colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Pressable(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(suggestion.icon, color: context.colors.accent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      suggestion.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
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
