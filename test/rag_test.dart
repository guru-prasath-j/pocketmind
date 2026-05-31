import 'package:flutter_test/flutter_test.dart';
import 'package:pocketmind/core/rag/embedding_service.dart';
import 'package:pocketmind/core/rag/text_chunker.dart';

void main() {
  group('TextChunker', () {
    const chunker = TextChunker();

    test('returns single chunk for short text', () {
      final chunks = chunker.chunk('hello world');
      expect(chunks.length, 1);
      expect(chunks.first, 'hello world');
    });

    test('returns empty list for blank text', () {
      expect(chunker.chunk('   '), isEmpty);
    });

    test('splits long text into overlapping chunks', () {
      final text = List.filled(500, 'word').join(' ');
      final chunks = chunker.chunk(text, size: 100, overlap: 20);
      expect(chunks.length, greaterThan(1));
      // every chunk respects the max size
      for (final c in chunks) {
        expect(c.length, lessThanOrEqualTo(100));
      }
    });
  });

  group('HashingEmbeddingService', () {
    final embedder = HashingEmbeddingService(dim: 256);

    test('produces vector of the configured dimension', () {
      expect(embedder.embed('quick brown fox').length, 256);
    });

    test('vectors are L2-normalised (self-similarity ~= 1)', () {
      final v = embedder.embed('retrieval augmented generation');
      expect(cosineSimilarity(v, v), closeTo(1.0, 1e-9));
    });

    test('related text is more similar than unrelated text', () {
      final query = embedder.embed('how do neural networks learn');
      final related =
          embedder.embed('neural networks learn weights via training');
      final unrelated = embedder.embed('the price of bananas in the market');
      expect(cosineSimilarity(query, related),
          greaterThan(cosineSimilarity(query, unrelated)));
    });
  });
}
