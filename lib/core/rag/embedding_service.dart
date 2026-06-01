import 'dart:math';

import '../constants.dart';

/// Turns text into a fixed-length numeric vector so we can measure how related
/// two pieces of text are by the distance between their vectors.
abstract class EmbeddingService {
  int get dim;
  List<double> embed(String text);
  List<List<double>> embedBatch(List<String> texts) => texts.map(embed).toList();
}

/// Default, zero-download embedder.
///
/// It hashes each word and its character tri-grams into a fixed-size vector
/// (the "hashing trick" / feature hashing) and L2-normalises the result. It is
/// tiny, deterministic, and fully offline, so the app works the moment it is
/// installed — no second model to download.
///
/// Trade-off: it captures lexical (word-overlap) similarity, not deep semantic
/// similarity. For semantic retrieval, implement [EmbeddingService] with a
/// sentence-transformer (e.g. all-MiniLM-L6-v2) running through `tflite_flutter`
/// and register it in the ServiceLocator. Nothing else in the app changes.
class HashingEmbeddingService extends EmbeddingService {
  @override
  final int dim;

  HashingEmbeddingService({this.dim = AppConstants.embeddingDim});

  @override
  List<double> embed(String text) {
    final vec = List<double>.filled(dim, 0.0);
    for (final token in _tokenize(text)) {
      _add(vec, token, 1.0);
      for (final tri in _charNGrams(token, 3)) {
        _add(vec, tri, 0.5); // sub-word features help with typos/inflections
      }
    }
    return _l2normalize(vec);
  }

  List<String> _tokenize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  Iterable<String> _charNGrams(String s, int n) sync* {
    if (s.length < n) {
      yield s;
      return;
    }
    for (var i = 0; i <= s.length - n; i++) {
      yield s.substring(i, i + n);
    }
  }

  void _add(List<double> vec, String feature, double weight) {
    final h = feature.hashCode;
    final idx = (h & 0x7fffffff) % dim;
    final sign = (h & 1) == 0 ? 1.0 : -1.0; // signed hashing limits collision bias
    vec[idx] += sign * weight;
  }

  List<double> _l2normalize(List<double> v) {
    var norm = 0.0;
    for (final x in v) {
      norm += x * x;
    }
    norm = sqrt(norm);
    if (norm == 0) return v;
    for (var i = 0; i < v.length; i++) {
      v[i] /= norm;
    }
    return v;
  }
}

/// Cosine similarity. For L2-normalised vectors this is just the dot product,
/// returning a value in [-1, 1] where higher means more similar.
double cosineSimilarity(List<double> a, List<double> b) {
  var dot = 0.0;
  final n = min(a.length, b.length);
  for (var i = 0; i < n; i++) {
    dot += a[i] * b[i];
  }
  return dot;
}
