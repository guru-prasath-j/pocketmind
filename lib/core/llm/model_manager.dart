import 'package:flutter_gemma/flutter_gemma.dart';

import '../constants.dart';

class ModelManager {
  final _manager = FlutterGemmaPlugin.instance.modelManager;

  Future<bool> isModelInstalled() async {
    try {
      final installed = await _manager.getInstalledModels(ModelManagementType.inference);
      return installed.contains(AppConstants.modelFileName);
    } catch (_) {
      return false;
    }
  }

  Future<void> installFromAsset() =>
      FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.task,
      ).fromAsset(AppConstants.modelFileName).install();

  Future<void> deleteModel() async {}
}
