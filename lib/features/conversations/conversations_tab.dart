import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/file_badge.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models.dart';
import '../chat/chat_cubit.dart';
import '../chat/chat_sessions.dart';
import '../library/document_actions.dart';
import '../library/library_cubit.dart';

/// The "Chat" tab: ongoing conversations first, then every other document
/// ready for a new chat.
class ConversationsTab extends StatelessWidget {
  const ConversationsTab({super.key, required this.onAddDocument});

  final VoidCallback onAddDocument;

  @override
  Widget build(BuildContext context) {
    final sessions = context.read<ChatSessions>();
    final library = context.watch<LibraryCubit>().state;

    return ListenableBuilder(
      listenable: sessions.changes,
      builder: (context, _) {
        final activeIds = sessions.documentIdsWithMessages.toSet();
        final byRecency = [...library.documents]..sort((a, b) {
            final ta = a.lastOpenedAt ?? a.createdAt;
            final tb = b.lastOpenedAt ?? b.createdAt;
            return tb.compareTo(ta);
          });
        final active = byRecency.where((d) => activeIds.contains(d.id)).toList();
        final others = byRecency.where((d) => !activeIds.contains(d.id)).toList();

        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _TabHeader()),
            if (library.documents.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _NoDocuments(onAddDocument: onAddDocument),
              )
            else ...[
              if (active.isNotEmpty) ...[
                const _SectionLabel('Active conversations'),
                _DocList(docs: active, sessions: sessions),
              ],
              _SectionLabel(active.isEmpty ? 'Start a chat' : 'Start a new chat'),
              if (others.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter, 0, AppSpacing.gutter, 0),
                    child: Text(
                      'Every document already has a conversation.',
                      style: TextStyle(color: context.colors.textMuted),
                    ),
                  ),
                )
              else
                _DocList(docs: others, sessions: sessions),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        );
      },
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 22, AppSpacing.gutter, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chats',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            'Pick up where you left off, or ask a new document.',
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 20, AppSpacing.gutter, 10),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: context.colors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class _DocList extends StatelessWidget {
  const _DocList({required this.docs, required this.sessions});

  final List<DocumentItem> docs;
  final ChatSessions sessions;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      sliver: SliverList.separated(
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _ConversationTile(
          doc: docs[i],
          session: sessions.existing(docs[i].id!),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.doc, required this.session});

  final DocumentItem doc;
  final ChatCubit? session;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    final content = session == null
        ? _tile(context, const ChatState(), radius)
        : BlocBuilder<ChatCubit, ChatState>(
            bloc: session,
            builder: (context, s) => _tile(context, s, radius),
          );
    return content;
  }

  Widget _tile(BuildContext context, ChatState s, BorderRadius radius) {
    final last = s.messages.isEmpty ? null : s.messages.last;
    final subtitle = switch (last) {
      null => doc.lastOpenedAt == null
          ? 'Tap to ask a question'
          : 'Opened ${Format.relative(doc.lastOpenedAt!).toLowerCase()}',
      ChatMessage(isStreaming: true) => 'Answering…',
      ChatMessage(sender: Sender.user, :final text) => 'You: $text',
      ChatMessage(:final text) => text,
    };
    final count = s.messages.where((m) => m.sender == Sender.user).length;

    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: context.colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Pressable(
        borderRadius: radius,
        onTap: () => DocumentActions.openChat(context, doc),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              FileBadge(fileName: doc.title, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.replaceAll('\n', ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: last?.isStreaming == true
                            ? context.colors.accent
                            : context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (count > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 26),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded,
                    color: context.colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoDocuments extends StatelessWidget {
  const _NoDocuments({required this.onAddDocument});

  final VoidCallback onAddDocument;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 56, color: context.colors.accent),
          const SizedBox(height: 16),
          Text('No conversations yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Add a document, then ask it anything.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Add Document',
            icon: Icons.add_rounded,
            onPressed: onAddDocument,
          ),
        ],
      ),
    );
  }
}
