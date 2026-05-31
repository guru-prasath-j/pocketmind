import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/rag/rag_pipeline.dart';
import '../../data/models.dart';

/// Immutable state for one document's conversation.
class ChatState extends Equatable {
  const ChatState({this.messages = const [], this.busy = false});

  final List<ChatMessage> messages;
  final bool busy;

  ChatState copyWith({List<ChatMessage>? messages, bool? busy}) {
    return ChatState(
      messages: messages ?? this.messages,
      busy: busy ?? this.busy,
    );
  }

  @override
  List<Object?> get props => [messages, busy];
}

/// Owns one document's conversation. Plain language: when you type a question,
/// it shows your message, then streams the AI's answer word-by-word and lists
/// which parts of the document the answer was based on.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._rag, this.documentId) : super(const ChatState());

  final RagPipeline _rag;
  final int documentId;

  Future<void> send(String text) async {
    final question = text.trim();
    if (question.isEmpty || state.busy) return;

    final userMsg = ChatMessage(sender: Sender.user, text: question);
    var assistant = ChatMessage(
      sender: Sender.assistant,
      text: '',
      isStreaming: true,
    );
    final messages = [...state.messages, userMsg, assistant];
    final assistantIndex = messages.length - 1;
    emit(state.copyWith(messages: messages, busy: true));

    void replaceAssistant(ChatMessage updated) {
      assistant = updated;
      final next = [...state.messages];
      next[assistantIndex] = updated;
      emit(state.copyWith(messages: next));
    }

    try {
      final result = await _rag.ask(question, documentId: documentId);
      final buffer = StringBuffer();
      await for (final token in result.answer) {
        buffer.write(token);
        replaceAssistant(assistant.copyWith(text: buffer.toString()));
      }
      replaceAssistant(
        assistant.copyWith(isStreaming: false, sources: result.sources),
      );
    } catch (e) {
      replaceAssistant(
        assistant.copyWith(text: 'Something went wrong: $e', isStreaming: false),
      );
    } finally {
      emit(state.copyWith(busy: false));
    }
  }
}
