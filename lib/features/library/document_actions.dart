import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/file_badge.dart';
import '../../data/models.dart';
import '../chat/chat_screen.dart';
import '../chat/chat_sessions.dart';
import 'library_cubit.dart';

/// Actions on a document, shared by the library, the Chat tab and the chat
/// screen so every entry point behaves identically.
abstract final class DocumentActions {
  /// Opens the document's conversation and records it as recently opened.
  static Future<void> openChat(BuildContext context, DocumentItem doc) {
    final library = context.read<LibraryCubit>();
    final sessions = context.read<ChatSessions>();
    library.markOpened(doc.id!);
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: library,
          child: RepositoryProvider.value(
            value: sessions,
            child: ChatScreen(document: doc),
          ),
        ),
      ),
    );
  }

  /// Asks for confirmation, then deletes. Returns true when deleted.
  static Future<bool> confirmDelete(BuildContext context, DocumentItem doc) async {
    final library = context.read<LibraryCubit>();
    final sessions = context.read<ChatSessions>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        title: const Text('Delete document?'),
        content: Text(
          '"${doc.title}", its ${doc.chunkCount} chunks and its conversation '
          'will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    sessions.remove(doc.id!);
    await library.delete(doc);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${doc.title}"')),
      );
    }
    return true;
  }

  static Future<void> showDetails(BuildContext context, DocumentItem doc) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FileBadge(fileName: doc.title, size: 52),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      doc.title,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DetailRow('Chunks', '${doc.chunkCount}'),
              _DetailRow(
                'File size',
                doc.fileSize == null ? 'Unknown' : Format.bytes(doc.fileSize!),
              ),
              _DetailRow('Added', Format.date(doc.createdAt)),
              _DetailRow(
                'Last opened',
                doc.lastOpenedAt == null
                    ? 'Never'
                    : Format.relative(doc.lastOpenedAt!),
              ),
              _DetailRow('Starred', doc.starred ? 'Yes' : 'No'),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stored and processed only on this device.',
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: context.colors.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
