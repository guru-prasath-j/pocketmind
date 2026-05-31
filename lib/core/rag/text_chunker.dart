import '../constants.dart';

/// Splits long document text into overlapping windows ("chunks").
///
/// Why chunk? Two reasons: (1) a whole document won't fit in the model's
/// context window, and (2) retrieval is sharper when each unit of text is small
/// and topically focused. The overlap keeps sentences that straddle a boundary
/// from being lost.
class TextChunker {
  const TextChunker();

  List<String> chunk(String text, {int? size, int? overlap}) {
    final chunkSize = size ?? AppConstants.chunkSize;
    final step = chunkSize - (overlap ?? AppConstants.chunkOverlap);
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (clean.isEmpty) return const [];
    if (clean.length <= chunkSize) return [clean];

    final chunks = <String>[];
    var start = 0;
    while (start < clean.length) {
      final end = (start + chunkSize).clamp(0, clean.length);
      chunks.add(clean.substring(start, end));
      if (end == clean.length) break;
      start += step;
    }
    return chunks;
  }
}
