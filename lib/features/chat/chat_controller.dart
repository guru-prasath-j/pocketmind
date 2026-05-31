import 'package:flutter/foundation.dart';

import '../../core/rag/rag_pipeline.dart';
import '../../data/models.dart';

/// Owns one document's conversation. Plain language: when you type a question,
/// it shows your message, then streams the AI's answer word-by-word and lists
/// which parts of the document the answer was based on.
class ChatController extends ChangeNotifier {
  ChatController(this._rag, this.documentId);

  final RagPipeline _rag;
  final int documentId;

  final List<ChatMessage> messages = [];
  bool busy = false;

  Future<void> send(String text) async {
    final question = text.trim();
    if (question.isEmpty || busy) return;

    messages.add(ChatMessage(sender: Sender.user, text: question));
    final assistant = ChatMessage(
      sender: Sender.assistant,
      text: '',
      isStreaming: true,
    );
    messages.add(assistant);
    busy = true;
    notifyListeners();

    try {
      final result = await _rag.ask(question, documentId: documentId);
      final buffer = StringBuffer();
      await for (final token in result.answer) {
        buffer.write(token);
        final idx = messages.indexOf(assistant);
        messages[idx] = assistant.copyWith(text: buffer.toString());
        notifyListeners();
      }
      final idx = messages.indexOf(assistant);
      messages[idx] = messages[idx]
          .copyWith(isStreaming: false, sources: result.sources);
    } catch (e) {
      final idx = messages.indexOf(assistant);
      messages[idx] = assistant.copyWith(
        text: 'Something went wrong: $e',
        isStreaming: false,
      );
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
