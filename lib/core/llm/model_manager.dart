import 'package:flutter_gemma/flutter_gemma.dart';

import '../constants.dart';

/// Responsible for getting the model weights onto the device and reporting
/// whether the model is ready. The download happens once; after that the app
/// needs no network at all.
class ModelManager {
  final _modelManager = FlutterGemmaPlugin.instance.modelManager;

  Future<bool> isModelInstalled() async {
    try {
      return await _modelManager.isModelInstalled;
    } catch (_) {
      return false;
    }
  }

  /// Emits download progress as a percentage (0–100) for a progress bar.
  Stream<int> downloadModel() {
    return _modelManager
        .installModelFromNetworkWithProgress(AppConstants.modelDownloadUrl);
  }

  /// Alternative to downloading: ship the model bundled as a Flutter asset.
  Future<void> installFromAsset() =>
      _modelManager.installModelFromAsset(AppConstants.modelFileName);

  Future<void> deleteModel() => _modelManager.deleteModel();
}
