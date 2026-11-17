# PocketMind — On-Device AI Study Assistant

> A fully offline AI study assistant that runs a local LLM directly on your phone — no internet, no API keys, no data sent to the cloud.

**Flutter** · **flutter_gemma (on-device inference)** · **RAG** · **Dart**

## Why On-Device?

Most AI apps send your data to remote servers. PocketMind keeps everything local — your study notes never leave your device. It runs a quantized Gemma model through [`flutter_gemma`](https://pub.dev/packages/flutter_gemma) (MediaPipe LLM Inference under the hood), making it useful even without network access.

## Features

- 📚 **Local RAG** — import PDF/text documents, chunk them, and query them semantically against an on-device vector store
- 🤖 **On-device LLM** — runs a quantized Gemma 3 1B model locally via MediaPipe (Android/iOS)
- 🔒 **100% offline** — no API calls, no telemetry, no cloud dependency
- 📝 **Document library** — import, list, and delete study documents
- ⚡ **Instant responses** — no network latency
- 🌐 **Web-aware** — builds for web with a clear "not supported" message, since on-device inference requires native platform support

## Architecture

```
User Query
    ↓
On-Device Embedding Model
    ↓
Local Vector Store (cosine similarity, SQLite-backed)
    ↓
Top-K Relevant Chunks
    ↓
On-Device LLM (Gemma 3, quantized, via flutter_gemma/MediaPipe)
    ↓
Answer (fully local, no internet)
```

State is managed with `flutter_bloc` Cubits (`ChatCubit`, `LibraryCubit`, `ModelSetupCubit`), wired up through a lightweight `ServiceLocator` at startup.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| UI Framework | Flutter 3 (Dart) |
| State Management | flutter_bloc (Cubits) + equatable |
| On-device LLM | flutter_gemma (Gemma 3 1B, MediaPipe LLM Inference) |
| Vector Store | Local cosine-similarity search |
| Storage | sqflite (local SQLite) |
| Document Import | file_picker + syncfusion_flutter_pdf (PDF text extraction) |
| Platform | Android + iOS (web builds, but inference is disabled in-browser) |

## Getting Started

```bash
flutter pub get
flutter run
```

> Note: First run downloads and initializes the local model weights. Subsequent launches are instant. Running on web (`flutter run -d chrome`) shows an informational screen instead of the app, since on-device LLM inference isn't available in the browser.

## Related Projects

- [brainsync-ai-app](https://github.com/guru-prasath-j/brainsync-ai-app) — Cloud-connected AI study companion with GPT-4 + RAG + Flutter
- [self-healing-rag-eval](https://github.com/guru-prasath-j/self-healing-rag-eval) — Production RAG pipeline with LangGraph + self-healing critic
