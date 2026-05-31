import 'package:flutter/material.dart';

import 'app.dart';
import 'core/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Wire up the database, model manager, RAG pipeline, etc. once at startup.
  await ServiceLocator.instance.init();
  runApp(const PocketMindApp());
}
