import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../core/rag/embedding_service.dart';
import '../core/rag/text_chunker.dart';
import '../core/rag/vector_store.dart';
import 'local_db.dart';
import 'models.dart';

/// The "ingestion" half of RAG. Given a file, it extracts the text, splits it
/// into chunks, embeds each chunk, and stores everything locally so it can be
/// searched later. All on-device.
class DocumentRepository {
  final LocalDb db;
  final TextChunker chunker;
  final EmbeddingService embedder;
  final VectorStore vectorStore;

  DocumentRepository({
    required this.db,
    required this.chunker,
    required this.embedder,
    required this.vectorStore,
  });

  Future<List<DocumentItem>> all() async {
    final docs = await db.getDocuments();
    // Documents imported before file sizes were tracked: backfill the size
    // from the cached file when it still exists.
    return Future.wait(docs.map((d) async {
      if (d.fileSize != null || d.id == null) return d;
      final size = await _sizeOf(d.sourcePath);
      if (size == null) return d;
      await db.updateDocument(d.id!, {'file_size': size});
      return d.copyWith(fileSize: size);
    }));
  }

  Future<void> setStarred(int id, bool starred) =>
      db.updateDocument(id, {'starred': starred ? 1 : 0});

  Future<void> markOpened(int id, DateTime at) =>
      db.updateDocument(id, {'last_opened_at': at.millisecondsSinceEpoch});

  Future<void> deleteAll() => db.deleteAllDocuments();

  Future<int?> _sizeOf(String path) async {
    try {
      final f = File(path);
      return await f.exists() ? await f.length() : null;
    } catch (_) {
      return null;
    }
  }

  Future<DocumentItem> importFile(String path, String title) async {
    final text = await _extractText(path);
    final pieces = chunker.chunk(text);
    final size = await _sizeOf(path);

    final docId = await db.insertDocument(DocumentItem(
      title: title,
      sourcePath: path,
      chunkCount: pieces.length,
      createdAt: DateTime.now(),
      fileSize: size,
    ));

    final vectors = embedder.embedBatch(pieces);
    final chunks = <DocChunk>[
      for (var i = 0; i < pieces.length; i++)
        DocChunk(documentId: docId, text: pieces[i], embedding: vectors[i]),
    ];
    await db.insertChunks(chunks);

    return DocumentItem(
      id: docId,
      title: title,
      sourcePath: path,
      chunkCount: pieces.length,
      createdAt: DateTime.now(),
      fileSize: size,
    );
  }

  Future<void> delete(int id) => db.deleteDocument(id);

  Future<String> _extractText(String path) async {
    if (path.toLowerCase().endsWith('.pdf')) {
      final bytes = await File(path).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();
      return text;
    }
    return File(path).readAsString();
  }
}
