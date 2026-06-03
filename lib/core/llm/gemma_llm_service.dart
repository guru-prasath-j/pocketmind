import 'package:flutter_gemma/flutter_gemma.dart';

import '../constants.dart';
import 'llm_service.dart';

/// On-device LLM backed by the `flutter_gemma` plugin, which wraps Google's
/// MediaPipe LLM Inference API. Once the model file is on the device, this runs
/// completely offline — no tokens ever leave the phone.
///
/// NOTE: `flutter_gemma`'s public API has shifted between releases. This adapter
/// targets the 0.8.x line. If you pin a different version, the only file you
/// need to touch is this one — everything else talks to [LlmService].
class GemmaLlmService implements LlmService {
  InferenceModel? _model;
  InferenceModelSession? _session;

  @override
  bool get isReady => _model != null;

  @override
  Future<void> warmUp() async {
    if (_model != null) return;
    final gemma = FlutterGemmaPlugin.instance;
    _model = await gemma.createModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.task,
      preferredBackend: PreferredBackend.gpu,
      maxTokens: AppConstants.maxTokens,
    );
  }

  @override
  Stream<String> generate(String prompt) async* {
    await warmUp();
    _session = await _model!.createSession(
      temperature: AppConstants.temperature,
      topK: AppConstants.topKSampling,
    );
    try {
      await _session!.addQueryChunk(Message(text: prompt, isUser: true));
      yield* _session!.getResponseAsync();
    } finally {
      await _session?.close();
      _session = null;
    }
  }

  @override
  Future<void> dispose() async {
    await _session?.close();
    await _model?.close();
    _session = null;
    _model = null;
  }
}
