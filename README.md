# PocketMind — On-Device AI Study Assistant

> A fully offline AI study assistant that runs a local LLM directly on your phone — no internet, no API keys, no data sent to the cloud.

**Flutter** · **Local LLM (on-device inference)** · **RAG** · **Dart**

## Why On-Device?

Most AI apps send your data to remote servers. PocketMind keeps everything local — your study notes never leave your device. It runs quantized LLM inference using on-device ML runtimes, making it useful even without network access.

## Features

- 📚 **Local RAG** — index your notes into an on-device vector store and query them semantically
- 🤖 **On-device LLM** — runs a quantized language model locally on Android/iOS hardware
- 🔒 **100% offline** — no API calls, no telemetry, no cloud dependency
- 📝 **Note management** — add, search, and delete study notes
- ⚡ **Instant responses** — no network latency

## Architecture

```
User Query
    ↓
On-Device Embedding Model
    ↓
Local Vector Store (cosine similarity)
    ↓
Top-K Relevant Chunks
    ↓
On-Device LLM (quantized GGUF / TFLite)
    ↓
Answer (fully local, no internet)
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| UI Framework | Flutter 3 (Dart) |
| On-device LLM | Local quantized model inference |
| Embeddings | On-device embedding model |
| Vector Store | Local FAISS-style similarity search |
| Storage | SQLite (local) |
| Platform | Android + iOS |

## Getting Started

```bash
flutter pub get
flutter run
```

> Note: First run downloads and initializes the local model weights. Subsequent launches are instant.

## Related Projects

- [brainsync-ai-app](https://github.com/guru-prasath-j/brainsync-ai-app) — Cloud-connected AI study companion with GPT-4 + RAG + Flutter
- [self-healing-rag-eval](https://github.com/guru-prasath-j/self-healing-rag-eval) — Production RAG pipeline with LangGraph + self-healing critic
