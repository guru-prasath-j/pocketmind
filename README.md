# PocketMind — Offline, On-Device AI Study Assistant

PocketMind is a Flutter app that lets you import your own documents (PDF, text,
markdown) and **chat with them using an AI model that runs entirely on your
phone**. After a one-time model download, there is **no internet, no server, no
API key** — your documents never leave the device.

It is built around **on-device RAG** (Retrieval-Augmented Generation): the app
finds the passages of your document most relevant to your question, feeds them
to a local LLM, and streams back a grounded answer with its sources.

---

## Why this project is interesting

- **Truly offline & private.** Inference happens locally via `flutter_gemma`
  (MediaPipe LLM Inference under the hood). Nothing is uploaded.
- **End-to-end RAG on a phone.** Chunking → embeddings → vector search →
  grounded prompting → token streaming, all on-device.
- **Clean, swappable architecture.** Every moving part sits behind an interface
  (`LlmService`, `EmbeddingService`) so you can swap the model or the embedder
  without touching the UI.
- **Works out of the box.** Ships with a zero-download hashing embedder, with a
  documented extension point to plug in a real sentence-transformer (MiniLM).

---

## Features

- One-time guided model download with progress.
- Import PDF / TXT / MD; on-device PDF text extraction.
- Ask questions per document; answers stream word-by-word.
- Each answer shows how many document passages it was grounded in.
- Local SQLite storage of documents, chunks, and embeddings.
- Light & dark Material 3 theming.

---

## Tech stack

| Concern              | Choice                                            |
|----------------------|---------------------------------------------------|
| UI                   | Flutter, Material 3                               |
| State management     | `flutter_bloc` (Cubits + immutable states)        |
| On-device LLM        | `flutter_gemma` (Gemma 2 2B IT, int4)             |
| PDF extraction       | `syncfusion_flutter_pdf`                          |
| Storage              | `sqflite` (SQLite)                                |
| File import          | `file_picker`                                     |
| Embeddings (default) | Hashing trick (custom, zero-download)             |

---

## How it works (60-second version)

1. **Import** a document → text is extracted.
2. **Chunk** the text into small overlapping passages.
3. **Embed** each chunk into a numeric vector and store it.
4. **Ask** a question → it is embedded the same way.
5. **Retrieve** the top-K most similar chunks by cosine similarity.
6. **Prompt** the local LLM with those chunks as context.
7. **Stream** a grounded answer back, with sources.

A deeper walkthrough — both a technical flow and a plain-language flow — is in
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## Project structure

```
lib/
  main.dart                     App entry; initialises the ServiceLocator.
  app.dart                      MaterialApp + first-run routing.
  core/
    constants.dart              Tunable knobs (chunk size, top-K, model name…).
    service_locator.dart        Manual dependency injection.
    llm/
      llm_service.dart          Abstract LLM interface.
      gemma_llm_service.dart    flutter_gemma implementation.
      model_manager.dart        Model download / install / delete.
    rag/
      text_chunker.dart         Splits text into overlapping chunks.
      embedding_service.dart    Embedding interface + hashing embedder.
      vector_store.dart         Brute-force cosine similarity search.
      rag_pipeline.dart         Orchestrates retrieve → prompt → generate.
  data/
    models.dart                 Data classes (DocumentItem, DocChunk, …).
    local_db.dart               sqflite schema + queries.
    document_repository.dart    Import → extract → chunk → embed → store.
  features/
    setup/                      First-run model download (Cubit + screen).
    library/                    Document list + import (Cubit + screen).
    chat/                       Per-document chat (Cubit + screen).
test/
  rag_test.dart                 Unit tests for chunker + embedder.
```

---

## Getting started

```bash
flutter pub get
flutter run
```

On first launch, tap **Download model**. After that, the app is fully offline.

> **Model note:** set `AppConstants.modelDownloadUrl` in
> `lib/core/constants.dart` to a valid Gemma `.bin` URL (e.g. from Kaggle /
> Hugging Face), or bundle a model as an asset and use
> `ModelManager.installFromAsset()`.

### Run the tests

```bash
flutter test
```

---

## License

MIT — see [LICENSE](LICENSE).
