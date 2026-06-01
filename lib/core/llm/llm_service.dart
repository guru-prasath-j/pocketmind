/// Contract for any on-device text-generation backend.
///
/// The whole app depends only on this interface, never on a specific plugin.
/// That means we can swap Gemma for another runtime (or a fake for tests)
/// without touching the UI or the RAG pipeline.
abstract class LlmService {
  /// Loads the model into memory. Safe to call multiple times.
  Future<void> warmUp();

  /// Streams the answer for [prompt] token-by-token, so the UI can render text
  /// as it is generated instead of waiting for the full response.
  Stream<String> generate(String prompt);

  /// Releases native resources (model + session).
  Future<void> dispose();

  bool get isReady;
}
