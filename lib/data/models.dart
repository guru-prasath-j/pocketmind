/// A document the user imported (a PDF or text file).
class DocumentItem {
  final int? id;
  final String title;
  final String sourcePath;
  final int chunkCount;
  final DateTime createdAt;

  /// Size of the original file in bytes, when known.
  final int? fileSize;

  /// Pinned by the user (shown under the "Starred" tab).
  final bool starred;

  /// Last time the user opened this document's chat (drives "Recent").
  final DateTime? lastOpenedAt;

  DocumentItem({
    this.id,
    required this.title,
    required this.sourcePath,
    required this.chunkCount,
    required this.createdAt,
    this.fileSize,
    this.starred = false,
    this.lastOpenedAt,
  });

  DocumentItem copyWith({
    int? fileSize,
    bool? starred,
    DateTime? lastOpenedAt,
  }) =>
      DocumentItem(
        id: id,
        title: title,
        sourcePath: sourcePath,
        chunkCount: chunkCount,
        createdAt: createdAt,
        fileSize: fileSize ?? this.fileSize,
        starred: starred ?? this.starred,
        lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'source_path': sourcePath,
        'chunk_count': chunkCount,
        'created_at': createdAt.millisecondsSinceEpoch,
        'file_size': fileSize,
        'starred': starred ? 1 : 0,
        'last_opened_at': lastOpenedAt?.millisecondsSinceEpoch,
      };

  factory DocumentItem.fromMap(Map<String, Object?> m) => DocumentItem(
        id: m['id'] as int?,
        title: m['title'] as String,
        sourcePath: m['source_path'] as String,
        chunkCount: m['chunk_count'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        fileSize: m['file_size'] as int?,
        starred: (m['starred'] as int? ?? 0) == 1,
        lastOpenedAt: m['last_opened_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['last_opened_at'] as int),
      );
}

/// One chunk of a document plus its embedding vector.
class DocChunk {
  final int? id;
  final int documentId;
  final String text;
  final List<double> embedding;

  DocChunk({
    this.id,
    required this.documentId,
    required this.text,
    required this.embedding,
  });
}

enum Sender { user, assistant }

/// A single message in the chat. While the model is generating, [isStreaming]
/// is true and [text] grows token-by-token.
class ChatMessage {
  final Sender sender;
  final String text;
  final List<String> sources; // chunks used to ground the answer
  final bool isStreaming;

  ChatMessage({
    required this.sender,
    required this.text,
    this.sources = const [],
    this.isStreaming = false,
  });

  ChatMessage copyWith({String? text, bool? isStreaming, List<String>? sources}) =>
      ChatMessage(
        sender: sender,
        text: text ?? this.text,
        sources: sources ?? this.sources,
        isStreaming: isStreaming ?? this.isStreaming,
      );
}
