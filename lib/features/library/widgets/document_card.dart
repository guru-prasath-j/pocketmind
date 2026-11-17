import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/file_badge.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/models.dart';

enum DocumentCardAction { open, star, details, delete }

/// Rounded library card: file badge, name, "44 chunks • 2.1 MB", and a ⋮ menu.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onAction,
  });

  final DocumentItem document;
  final VoidCallback onTap;
  final ValueChanged<DocumentCardAction> onAction;

  @override
  Widget build(BuildContext context) {
    final doc = document;
    final meta = [
      '${doc.chunkCount} chunk${doc.chunkCount == 1 ? '' : 's'}',
      if (doc.fileSize != null) Format.bytes(doc.fileSize!),
    ].join('  •  ');
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    return Semantics(
      button: true,
      label: '${doc.title}, $meta${doc.starred ? ', starred' : ''}',
      excludeSemantics: false,
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
          pressedScale: 0.98,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
            child: Row(
              children: [
                FileBadge(fileName: doc.title, size: 56),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (doc.starred) ...[
                            const Icon(Icons.star_rounded,
                                size: 16, color: AppColors.star),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: context.colors.border,
                ),
                CircleMenuButton<DocumentCardAction>(
                  size: 42,
                  tooltip: 'Document options',
                  onSelected: onAction,
                  items: [
                    menuItem(DocumentCardAction.open,
                        Icons.chat_bubble_outline_rounded, 'Open chat'),
                    menuItem(
                      DocumentCardAction.star,
                      doc.starred
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      doc.starred ? 'Remove from Starred' : 'Add to Starred',
                    ),
                    menuItem(DocumentCardAction.details,
                        Icons.info_outline_rounded, 'Details'),
                    menuItem(DocumentCardAction.delete,
                        Icons.delete_outline_rounded, 'Delete',
                        destructive: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
