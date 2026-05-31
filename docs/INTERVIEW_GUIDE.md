# PocketMind — Interview Guide

A cheat-sheet for explaining PocketMind confidently. Read the
[Architecture doc](ARCHITECTURE.md) first; this is the "say it out loud" layer.

---

## The 30-second pitch

> "PocketMind is a Flutter app that lets you chat with your own PDFs and notes
> using an AI model that runs **entirely on the phone** — no server, no API key,
> fully private. It's an end-to-end RAG pipeline on-device: I extract and chunk
> the document, embed each chunk, retrieve the most relevant passages for a
> question with vector similarity, and feed those into a local Gemma model that
> streams a grounded answer with sources."

## The 2-minute version

Start with the *problem* (cloud chatbots are a privacy and cost problem; raw
LLMs hallucinate), then walk the pipeline: import → chunk → embed → store →
retrieve → grounded prompt → stream. End with the *architecture* point: every
swappable part (the LLM, the embedder) is behind an interface, so the design
survives changing models.

---

## Likely questions & strong answers

**Q: What is RAG and why use it here?**
Retrieval-Augmented Generation. Instead of trusting the model's memory, I
retrieve the relevant passages from the user's document and put them in the
prompt, instructing the model to answer only from that context. It grounds
answers, reduces hallucination, and means the model doesn't need to be retrained
on the user's data.

**Q: How does the on-device inference work?**
Through `flutter_gemma`, which wraps Google's MediaPipe LLM Inference runtime. I
load a quantised Gemma 2 2B int4 model, open a session with a set temperature and
top-K sampling, and stream tokens out. It's isolated behind my `LlmService`
interface so the rest of the app doesn't know which model it's talking to.

**Q: How do embeddings work in your app?**
By default I use the hashing trick: I hash tokens and character tri-grams into a
fixed-size vector with signed hashing, then L2-normalise it. It's deterministic
and needs no extra download, so the app works immediately. The honest trade-off
is that it's lexical, not semantic — so I built an `EmbeddingService` interface
and documented exactly how to swap in a MiniLM sentence-transformer via
`tflite_flutter`. *(Knowing the limitation is the point.)*

**Q: Why cosine similarity, and why is it just a dot product here?**
Cosine similarity measures the angle between two vectors, ignoring magnitude —
ideal for comparing text meaning. Because I L2-normalise every vector, the
magnitudes are 1, so cosine similarity reduces to the dot product, which is
cheaper to compute.

**Q: Your vector search is brute force — isn't that slow?**
For a personal corpus of a handful of documents, scanning every chunk is fast
and avoids the complexity of an approximate index. I know the seam where it
breaks down: if the corpus grew large I'd add an ANN index like HNSW or IVF. I
chose simplicity deliberately for the actual use case.

**Q: Why chunk, and why overlap?**
A full document won't fit in the context window, and retrieval is sharper when
each unit is small and focused. Overlap prevents losing a sentence that straddles
a chunk boundary.

**Q: How do you prevent hallucination?**
The prompt explicitly says "answer using ONLY the context" and "say you don't
have that information if it's not there," and I surface the source passages so
the user can verify. Retrieval plus grounded prompting is the mechanism.

**Q: How is state managed?**
`provider` with `ChangeNotifier` controllers, one per screen. Controllers hold no
widgets — they call into the core/data layers and notify listeners. That keeps
logic unit-testable and widgets thin. For the chat stream I rewrite the assistant
message on each token with `copyWith` to get the live typing effect.

**Q: How is it architected for change?**
Three layers — core, data, features — with one-directional dependencies, and
manual DI in a `ServiceLocator`. The LLM and embedder are interfaces, so I can
replace either without touching the UI. Supporting a new model version is a
single-file change.

**Q: What did you test and why?**
The deterministic core: the chunker and the embedder, since they have clear
invariants (chunk size limits, self-similarity ≈ 1, related > unrelated). The LLM
and UI are intentionally thin so the logic worth testing lives in pure Dart.

**Q: What would you do next?**
Swap in MiniLM embeddings for semantic retrieval, add multi-document chat,
persist chat history, add an ANN index, and benchmark tokens/sec across devices.

---

## Words to use (and own)

RAG, retrieval, grounding, hallucination, embeddings, vector space, cosine
similarity, L2 normalisation, feature hashing, chunking with overlap, top-K,
quantisation (int4), streaming inference, dependency injection, interface
segregation, separation of concerns.

## Traps to avoid

- Don't claim the hashing embedder is semantic — call it lexical and name the
  upgrade.
- Don't claim brute-force search scales — name the threshold and the ANN fix.
- Don't say the model "knows" the document — it reads retrieved chunks each time.
