/// Central place for tunable values so behaviour is easy to reason about.
class AppConstants {
  static const String appName = 'PocketMind';
  static const String tagline = 'Offline AI for your documents';

  // --- Model -----------------------------------------------------------------
  // An instruction-tuned, mobile-sized model in a MediaPipe-compatible format.
  // Swap for whichever quantised model you ship/download.
  static const String modelFileName = 'gemma3-1b-it-int4.task';
  static const String modelDownloadUrl =
      'https://example.com/models/gemma2-2b-it-int4.bin'; // replace with your host

  // --- Retrieval (RAG) -------------------------------------------------------
  static const int chunkSize = 600; // characters per chunk
  static const int chunkOverlap = 100; // characters shared between neighbours
  static const int topK = 4; // chunks fed to the model as context
  static const int embeddingDim = 256; // length of each embedding vector

  // --- Inference -------------------------------------------------------------
  static const int maxTokens = 1024;
  static const double temperature = 0.4;
  static const int topKSampling = 40;
}
