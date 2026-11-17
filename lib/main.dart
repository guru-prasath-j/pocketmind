import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'app.dart';
import 'core/service_locator.dart';
import 'core/theme/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeCubit = ThemeCubit();
  if (!kIsWeb) {
    await FlutterGemma.initialize();
    // Wire up the database, model manager, RAG pipeline, etc. once at startup.
    // Skipped on web — this app requires on-device storage and LLM inference.
    await ServiceLocator.instance.init();
    await themeCubit.load();
  }
  runApp(PocketMindApp(themeCubit: themeCubit));
}
