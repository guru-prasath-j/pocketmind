import 'package:flutter/foundation.dart';

import '../../core/rag/rag_pipeline.dart';
import 'chat_cubit.dart';

/// Keeps one [ChatCubit] per document alive for the app session, so leaving a
/// chat and coming back (or switching via the Chat tab) keeps the conversation
/// — and an answer that is still streaming keeps streaming.
class ChatSessions {
  ChatSessions(this._rag);

  /// Fires when a conversation starts, is cleared or is removed.
  Listenable get changes => _changes;
  final _changes = ValueNotifier<int>(0);

  void _notify() => _changes.value++;

  final RagPipeline _rag;
  final GenerationLock _lock = GenerationLock();
  final Map<int, ChatCubit> _sessions = {};

  ChatCubit forDocument(int documentId) {
    return _sessions.putIfAbsent(documentId, () {
      final cubit = ChatCubit(_rag, documentId, lock: _lock);
      // Let listeners (the Chat tab) know when a conversation starts or ends.
      cubit.stream
          .map((s) => s.messages.isEmpty)
          .distinct()
          .listen((_) => _notify());
      return cubit;
    });
  }

  /// Existing session for [documentId], without creating one.
  ChatCubit? existing(int documentId) => _sessions[documentId];

  Iterable<int> get documentIdsWithMessages => _sessions.entries
      .where((e) => e.value.state.messages.isNotEmpty)
      .map((e) => e.key);

  /// Drops a document's conversation (used when the document is deleted).
  void remove(int documentId) {
    _sessions.remove(documentId)?.close();
    _notify();
  }

  /// Clears every conversation that isn't currently generating.
  void clearAll() {
    for (final cubit in _sessions.values) {
      cubit.clear();
    }
    _notify();
  }

  void closeAll() {
    for (final cubit in _sessions.values) {
      cubit.close();
    }
    _sessions.clear();
    _notify();
  }

  void dispose() {
    for (final cubit in _sessions.values) {
      cubit.close();
    }
    _sessions.clear();
    _changes.dispose();
  }
}
