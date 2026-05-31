# PocketMind — Architecture & Development Walkthrough

This document explains how PocketMind was built **twice**: once in plain
language (the generic flow) so anyone can follow the idea, and once in technical
detail (the technical flow) so you can defend every decision in an interview.

---

## Part 1 — The generic flow (plain language)

Imagine you have a thick PDF and you want to ask it questions like a person.
A normal chatbot would either (a) need the internet and a paid API, or (b) try
to answer from memory and make things up. PocketMind does neither. It keeps a
small AI model **on your phone** and teaches it to answer **only from your
document**. Here is the journey of a single question:

1. **You add a document.** The app reads the text out of the file.
2. **The app cuts the text into small cards.** A 40-page PDF is too big to hand
   to the AI all at once, so we slice it into bite-sized passages ("chunks").
   The slices overlap a little so we never cut a sentence in half and lose it.
3. **Each card gets a "fingerprint."** We turn every chunk into a list of
   numbers that captures what it's about. Similar text gets similar numbers.
4. **You ask a question.** We give the question the same kind of fingerprint.
5. **We find the matching cards.** We compare the question's fingerprint to
   every chunk's fingerprint and pick the few that match best. This is the
   "retrieval" step — like flipping straight to the right pages.
6. **We hand those cards to the AI.** We write a short instruction: "Answer using
   only these passages." Then we attach the matching chunks.
7. **The AI writes the answer, live.** Words stream onto the screen one at a
   time, and we show how many passages the answer leaned on.

The key insight: the AI isn't remembering your document — it's **reading the
relevant part fresh, every time**. That's why answers stay grounded and private.

---

## Part 2 — The technical flow

### 2.1 High-level pipeline

```
File → [extract text] → [chunk] → [embed] → [store in SQLite]
                                                     │
Question → [embed] → [vector search top-K] ─────────┘
                          │
                          └→ [build grounded prompt] → [LLM stream] → UI
```

This is **Retrieval-Augmented Generation (RAG)** running fully on-device.

### 2.2 Layered design

The codebase is split into three layers with one-directional dependencies:

- **`core/`** — framework-agnostic logic: LLM access, embeddings, chunking,
  retrieval, the RAG orchestrator, and DI.
- **`data/`** — persistence and the import pipeline (SQLite + repository).
- **`features/`** — UI, one folder per screen, each with a `ChangeNotifier`
  controller and a widget. UI depends on `core`/`data`, never the reverse.

Dependencies are wired manually in `ServiceLocator` (a singleton built once in
`main()`), which keeps construction explicit and testable without a DI package.

### 2.3 The LLM layer

`LlmService` is an abstract interface:

```dart
abstract class LlmService {
  Future<void> warmUp();
  Stream<String> generate(String prompt);
  Future<void> dispose();
  bool get isReady;
}
```

`GemmaLlmService` implements it on top of `flutter_gemma` (which wraps Google's
MediaPipe LLM Inference). It creates a model with `ModelType.gemmaIt` and a GPU
preferred backend, opens a session with a temperature and top-K sampling, pushes
the prompt with `addQueryChunk(Message.text(...))`, and re-exposes the plugin's
`getResponseAsync()` token stream. **Streaming is end-to-end**: tokens flow from
the model → through the RAG pipeline → into the controller → onto the screen,
so the UI never blocks on a full generation.

Because all model specifics are isolated here, supporting a new `flutter_gemma`
version or a different on-device model is a single-file change.

### 2.4 Embeddings — the honest default

`EmbeddingService` is the embedding interface. The default implementation,
`HashingEmbeddingService`, uses the **hashing trick (feature hashing)**:

- Tokenise text, and also generate character tri-grams (which give robustness to
  typos and word inflections).
- Hash each feature into a fixed-size vector index, using **signed hashing**
  (the low bit of the hash chooses +1/−1) to reduce collision bias.
- **L2-normalise** the vector, so cosine similarity reduces to a dot product.

Why this instead of a neural embedder by default? It is **deterministic, tiny,
and needs zero extra download**, so the app works the instant it's installed. Its
limitation is that it captures *lexical* similarity (word overlap), not deep
*semantic* similarity. The interface makes the upgrade path explicit: drop in a
sentence-transformer such as **all-MiniLM-L6-v2** via `tflite_flutter`,
implement `EmbeddingService`, register it in the `ServiceLocator` — nothing else
changes. Naming this trade-off openly is itself an interview talking point.

### 2.5 Storage & vector search

`LocalDb` (sqflite) has two tables: `documents` and `chunks`. Each chunk row
stores its embedding as a JSON-encoded list of doubles. `VectorStore.search()`
loads the candidate chunks (optionally filtered to one document), computes cosine
similarity against the query vector, sorts, and returns the top-K.

This is a **brute-force** search. For a personal corpus of a few documents that
is comfortably fast and avoids the complexity of an ANN index (HNSW/IVF). If the
corpus grew large, this is the seam where you'd introduce an approximate index —
and being able to articulate *when* brute force stops being appropriate is the
point.

### 2.6 The RAG pipeline

`RagPipeline.ask()` performs the three canonical RAG steps: embed the question,
retrieve top-K chunks, and build a **grounded prompt** that instructs the model
to "answer using ONLY the context below" and to admit when the answer isn't
present. It returns a `RagResult` carrying the token `Stream<String>` plus the
list of source chunks, so the UI can show provenance.

### 2.7 The import pipeline

`DocumentRepository.importFile()` extracts text (`syncfusion_flutter_pdf`'s
`PdfTextExtractor` for PDFs, plain read otherwise), chunks it, embeds the chunks
in a batch, and persists everything in one transaction-friendly flow.

### 2.8 State management & UI

Each screen has a `ChangeNotifier` controller exposed through
`ChangeNotifierProvider`. Controllers hold no Flutter widgets — they call into
`core`/`data` and call `notifyListeners()`. The chat controller appends a
placeholder assistant message, then rewrites it with `copyWith` on each streamed
token, giving the live "typing" effect. This keeps business logic unit-testable
and the widgets thin.

### 2.9 Testing

`test/rag_test.dart` covers the deterministic core: the chunker (short text,
empty text, overlapping windows respecting max size) and the embedder
(dimension, self-similarity ≈ 1 after normalisation, related text scoring higher
than unrelated text). These are the pieces with clear invariants; the LLM and UI
layers are kept thin precisely so the logic worth testing lives here.

---

## Part 3 — Decisions & trade-offs at a glance

| Decision                         | Why                                            | Trade-off / upgrade path                         |
|----------------------------------|------------------------------------------------|--------------------------------------------------|
| On-device LLM (`flutter_gemma`)  | Privacy, offline, no API cost                  | Larger app/model footprint; device-dependent speed |
| Hashing embeddings by default    | Zero download, deterministic, instant          | Lexical not semantic → swap in MiniLM via interface |
| Brute-force vector search        | Simple, fast enough for personal corpus        | Add ANN index (HNSW/IVF) if corpus grows         |
| `provider` + manual DI           | Lightweight, explicit, testable                | Could move to Riverpod/get_it at scale           |
| Interfaces for LLM & embeddings  | Swap implementations without touching UI       | Slight upfront abstraction cost                  |
