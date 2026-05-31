import 'package:flutter/foundation.dart';

import '../../core/llm/model_manager.dart';

enum SetupStatus { idle, downloading, ready, error }

/// Drives the one-time model download. Plain language: this is the "first run"
/// helper that fetches the AI brain onto the phone so everything afterward
/// works fully offline.
class ModelSetupController extends ChangeNotifier {
  ModelSetupController(this._modelManager);

  final ModelManager _modelManager;

  SetupStatus status = SetupStatus.idle;
  double progress = 0;
  String? error;

  Future<void> checkInstalled() async {
    if (await _modelManager.isModelInstalled()) {
      status = SetupStatus.ready;
      notifyListeners();
    }
  }

  Future<void> download() async {
    status = SetupStatus.downloading;
    progress = 0;
    error = null;
    notifyListeners();
    try {
      await for (final pct in _modelManager.downloadModel()) {
        progress = pct;
        notifyListeners();
      }
      status = SetupStatus.ready;
    } catch (e) {
      error = e.toString();
      status = SetupStatus.error;
    }
    notifyListeners();
  }
}
