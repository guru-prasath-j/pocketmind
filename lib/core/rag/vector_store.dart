import '../../data/local_db.dart';
import '../../data/models.dart';
import 'embedding_service.dart';

class ScoredChunk {
  final DocChunk chunk;
  final double score;
  ScoredChunk(this.chunk, this.score);
}

/// Finds the chunks most similar to a query vector.
///
/// This does a brute-force cosine scan in Dart. For a personal-document app the
/// corpus is small (hundreds–thousands of chunks), so a linear scan is plenty
/// fast and keeps everything on-device. If the corpus grew huge, you would swap
/// in an ANN index such as `sqlite-vec` or HNSW behind this same class.
class VectorStore {
  final LocalDb _db;
  VectorStore(this._db);

  Future<List<ScoredChunk>> search(
    List<double> queryVec, {
    int topK = 4,
    int? documentId,
  }) async {
    final chunks = await _db.getChunks(documentId: documentId);
    final scored = chunks
        .map((c) => ScoredChunk(c, cosineSimilarity(queryVec, c.embedding)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).toList();
  }
}
