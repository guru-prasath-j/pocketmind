import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/buttons.dart';
import '../../data/models.dart';
import '../library/document_actions.dart';
import '../library/library_cubit.dart';
import 'chat_cubit.dart';
import 'chat_sessions.dart';
import 'widgets/assistant_illustration.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/suggestion_grid.dart';

/// Conversation with one document. Expects [LibraryCubit] and [ChatSessions]
/// above it — use [DocumentActions.openChat] to navigate here.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.document});

  final DocumentItem document;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<ChatSessions>().forDocument(document.id!),
      child: _ChatView(initial: document),
    );
  }
}

enum _MenuAction { clear, details, delete }

class _ChatView extends StatefulWidget {
  const _ChatView({required this.initial});

  final DocumentItem initial;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = preset ?? _input.text;
    if (text.trim().isEmpty) return;
    if (preset == null) _input.clear();
    context.read<ChatCubit>().send(text);
    _scrollToBottom(force: true);
  }

  void _onSuggestion(Suggestion s) {
    if (s.prompt == null) {
      _focus.requestFocus();
    } else {
      _send(s.prompt);
    }
  }

  /// Follows the streaming answer, unless the user has scrolled up to read.
  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      final nearBottom = pos.maxScrollExtent - pos.pixels < 160;
      if (force || nearBottom) {
        _scroll.animateTo(
          pos.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onMenu(_MenuAction action, DocumentItem doc) async {
    switch (action) {
      case _MenuAction.clear:
        context.read<ChatCubit>().clear();
      case _MenuAction.details:
        await DocumentActions.showDetails(context, doc);
      case _MenuAction.delete:
        final deleted = await DocumentActions.confirmDelete(context, doc);
        if (deleted && mounted) Navigator.of(context).pop();
    }
  }

  void _toggleStar(DocumentItem doc) {
    context.read<LibraryCubit>().toggleStar(doc.id!);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(doc.starred ? 'Removed from Starred' : 'Added to Starred'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final doc = context.select<LibraryCubit, DocumentItem?>(
          (c) => c.state.byId(widget.initial.id!),
        ) ??
        widget.initial;

    return BlocListener<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state.notice != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.notice!)));
        }
        _scrollToBottom();
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: AmbientBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(
                  doc: doc,
                  onBack: () => Navigator.of(context).maybePop(),
                  onToggleStar: () => _toggleStar(doc),
                  onMenu: (a) => _onMenu(a, doc),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    behavior: HitTestBehavior.translucent,
                    child: BlocBuilder<ChatCubit, ChatState>(
                      builder: (context, state) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: state.messages.isEmpty
                            ? _EmptyState(
                                busy: state.busy,
                                onSuggestion: _onSuggestion,
                              )
                            : ListView.builder(
                                key: const ValueKey('messages'),
                                controller: _scroll,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemCount: state.messages.length,
                                itemBuilder: (_, i) =>
                                    MessageBubble(message: state.messages[i]),
                              ),
                      ),
                    ),
                  ),
                ),
                BlocSelector<ChatCubit, ChatState, bool>(
                  selector: (s) => s.busy,
                  builder: (context, busy) => ChatInputBar(
                    controller: _input,
                    focusNode: _focus,
                    busy: busy,
                    onSend: _send,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.doc,
    required this.onBack,
    required this.onToggleStar,
    required this.onMenu,
  });

  final DocumentItem doc;
  final VoidCallback onBack;
  final VoidCallback onToggleStar;
  final ValueChanged<_MenuAction> onMenu;

  @override
  Widget build(BuildContext context) {
    final hasMessages =
        context.select<ChatCubit, bool>((c) => c.state.messages.isNotEmpty);
    final busy = context.select<ChatCubit, bool>((c) => c.state.busy);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onPressed: onBack,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              doc.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          CircleIconButton(
            icon: doc.starred
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: doc.starred ? context.colors.accent : null,
            tooltip: doc.starred ? 'Remove from Starred' : 'Add to Starred',
            onPressed: onToggleStar,
          ),
          const SizedBox(width: 10),
          CircleMenuButton<_MenuAction>(
            tooltip: 'More options',
            onSelected: onMenu,
            items: [
              menuItem(
                _MenuAction.clear,
                Icons.refresh_rounded,
                'Clear conversation',
                enabled: hasMessages && !busy,
              ),
              menuItem(_MenuAction.details, Icons.info_outline_rounded,
                  'Document details'),
              menuItem(
                _MenuAction.delete,
                Icons.delete_outline_rounded,
                'Delete document',
                destructive: true,
                enabled: !busy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.busy, required this.onSuggestion});

  final bool busy;
  final ValueChanged<Suggestion> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey('empty'),
      builder: (context, c) {
        // Shrink the illustration on short screens / when the keyboard is up.
        final art = math.min(230.0, math.min(c.maxWidth * 0.6, c.maxHeight * 0.4));
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: math.max(0, c.maxHeight - 24)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (art >= 110) AssistantIllustration(size: art),
                const SizedBox(height: 20),
                Text(
                  'Start a conversation',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask questions about your document',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                ),
                const SizedBox(height: 28),
                SuggestionGrid(onSelected: onSuggestion, enabled: !busy),
              ],
            ),
          ),
        );
      },
    );
  }
}
