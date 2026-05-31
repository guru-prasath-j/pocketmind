import '../data/document_repository.dart';
import '../data/local_db.dart';
import 'llm/gemma_llm_service.dart';
import 'llm/llm_service.dart';
import 'llm/model_manager.dart';
import 'rag/embedding_service.dart';
import 'rag/rag_pipeline.dart';
import 'rag/text_chunker.dart';
import 'rag/vector_store.dart';

/// A tiny manual dependency-injection container. It builds every service once
/// and hands the same instances to the rest of the app. Keeping construction in
/// one place makes the data flow obvious and the pieces easy to swap or mock.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  late final LocalDb db;
  late final ModelManager modelManager;
  late final LlmService llm;
  late final EmbeddingService embedder;
  late final VectorStore vectorStore;
  late final TextChunker chunker;
  late final DocumentRepository documentRepository;
  late final RagPipeline rag;

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;

    db = LocalDb();
    await db.open();

    modelManager = ModelManager();
    llm = GemmaLlmService();
    embedder = HashingEmbeddingService();
    chunker = const TextChunker();
    vectorStore = VectorStore(db);

    documentRepository = DocumentRepository(
      db: db,
      chunker: chunker,
      embedder: embedder,
      vectorStore: vectorStore,
    );
    rag = RagPipeline(embedder: embedder, vectorStore: vectorStore, llm: llm);

    _ready = true;
  }
}
