import '../llm/llm_service.dart';
import 'embedding_service.dart';
import 'vector_store.dart';

class RagResult {
  final Stream<String> answer; // streamed token-by-token
  final List<String> sources; // the chunks used to ground the answer
  RagResult(this.answer, this.sources);
}

/// The heart of "Retrieval-Augmented Generation": instead of asking the model to
/// answer from memory, we (1) find the most relevant chunks of the user's own
/// documents, (2) put them in the prompt as context, and (3) ask the model to
/// answer using only that context. This grounds answers and reduces made-up facts.
class RagPipeline {
  final EmbeddingService embedder;
  final VectorStore vectorStore;
  final LlmService llm;

  RagPipeline({
    required this.embedder,
    required this.vectorStore,
    required this.llm,
  });

  Future<RagResult> ask(String question, {int topK = 4, int? documentId}) async {
    // 1. Embed the question into the same vector space as the chunks.
    final qVec = embedder.embed(question);
    // 2. Retrieve the most similar chunks.
    final hits = await vectorStore.search(qVec, topK: topK, documentId: documentId);
    final context = hits.map((h) => h.chunk.text).toList();
    // 3. Build a grounded prompt and stream the answer.
    final prompt = _buildPrompt(question, context);
    return RagResult(llm.generate(prompt), context);
  }

  String _buildPrompt(String question, List<String> context) {
    final ctx = context.isEmpty
        ? 'No relevant notes found.'
        : context
            .asMap()
            .entries
            .map((e) => '[${e.key + 1}] ${e.value}')
            .join('\n\n');
    return '''You are PocketMind, a concise study assistant. Answer the question using ONLY the context below. If the answer is not in the context, say you don't have that information.

Context:
$ctx

Question: $question

Answer:''';
  }
}
