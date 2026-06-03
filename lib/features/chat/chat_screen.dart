import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/service_locator.dart';
import '../../data/models.dart';
import 'chat_cubit.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.documentId, required this.title});

  final int documentId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatCubit(ServiceLocator.instance.rag, documentId),
      child: _ChatView(title: title),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({required this.title});

  final String title;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    _input.clear();
    context.read<ChatCubit>().send(text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        backgroundColor: scheme.surfaceVariant.withOpacity(0.5),
        foregroundColor: scheme.onSurface,
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) => state.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: scheme.outlineVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start a conversation',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask questions about your document',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: state.messages.length,
                      itemBuilder: (_, i) => _Bubble(message: state.messages[i]),
                    ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant.withOpacity(0.2))),
              color: scheme.surface,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: 'Ask about this document…',
                          hintStyle: TextStyle(color: scheme.outlineVariant),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: scheme.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: scheme.surfaceVariant.withOpacity(0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    BlocBuilder<ChatCubit, ChatState>(
                      buildWhen: (a, b) => a.busy != b.busy,
                      builder: (context, state) => IconButton.filled(
                        onPressed: state.busy ? null : _send,
                        icon: state.busy
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(scheme.onPrimary),
                                ),
                              )
                            : const Icon(Icons.send),
                        tooltip: 'Send message',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatefulWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  bool _sourcesExpanded = false;

  String _stripAsterisks(String text) {
    // Remove all asterisks and markdown symbols
    return text
        .replaceAll(RegExp(r'\*\*'), '') // Remove **
        .replaceAll(RegExp(r'\*'), '') // Remove single *
        .replaceAll(RegExp(r'__'), '') // Remove __
        .replaceAll(RegExp(r'_'), ''); // Remove single _
  }

  List<TextSpan> _formatText(String text, TextStyle baseStyle) {
    // Strip all asterisks and markdown symbols
    final cleanText = _stripAsterisks(text);
    final spans = <TextSpan>[];
    final lines = cleanText.split('\n');
    int lineIndex = 0;

    for (final line in lines) {
      // Handle code blocks
      if (line.startsWith('```')) {
        final codeContent = line.replaceFirst('```', '').trim();
        spans.add(TextSpan(
          text: codeContent,
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.grey[800],
            color: Colors.grey[100],
          ),
        ));
      }
      // Handle quotes
      else if (line.startsWith('>')) {
        final quoteText = line.replaceFirst('>', '').trim();
        spans.add(TextSpan(
          text: quoteText,
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
            color: baseStyle.color?.withOpacity(0.7),
          ),
        ));
      }
      // Handle lists
      else if (line.startsWith('- ') || line.startsWith('• ')) {
        final listItem = line.replaceFirst(RegExp(r'^[-•]\s'), '');
        spans.add(TextSpan(
          text: '• $listItem',
          style: baseStyle,
        ));
      }
      // Handle regular text
      else {
        spans.add(TextSpan(
          text: line,
          style: baseStyle,
        ));
      }

      // Add newline except for last line
      lineIndex++;
      if (lineIndex < lines.length) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans.isNotEmpty
        ? spans
        : [TextSpan(text: cleanText, style: baseStyle)];
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.sender == Sender.user;
    final scheme = Theme.of(context).colorScheme;
    final baseStyle = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary.withOpacity(0.9) : scheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText.rich(
              TextSpan(
                children: widget.message.text.isEmpty && widget.message.isStreaming
                    ? [
                        TextSpan(text: '…', style: baseStyle.copyWith(
                          color: isUser ? scheme.onPrimary : baseStyle.color,
                          fontSize: 18,
                        ))
                      ]
                    : _formatText(widget.message.text, baseStyle.copyWith(
                        color: isUser ? scheme.onPrimary : baseStyle.color,
                      )),
              ),
              style: baseStyle.copyWith(
                height: 1.6,
                letterSpacing: 0.2,
                color: isUser ? scheme.onPrimary : baseStyle.color,
              ),
            ),
            if (widget.message.sources.isNotEmpty) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _sourcesExpanded = !_sourcesExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isUser ? scheme.primaryContainer : scheme.surface).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: scheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '📚 ${widget.message.sources.length} source(s)',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isUser ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _sourcesExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: isUser ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
