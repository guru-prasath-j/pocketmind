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

  Future<List<DocumentItem>> all() => db.getDocuments();

  Future<DocumentItem> importFile(String path, String title) async {
    final text = await _extractText(path);
    final pieces = chunker.chunk(text);

    final docId = await db.insertDocument(DocumentItem(
      title: title,
      sourcePath: path,
      chunkCount: pieces.length,
      createdAt: DateTime.now(),
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
