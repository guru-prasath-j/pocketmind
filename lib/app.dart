import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/service_locator.dart';
import 'features/library/library_screen.dart';
import 'features/setup/model_setup_screen.dart';

class PocketMindApp extends StatelessWidget {
  const PocketMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF6750A4);
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seed, useMaterial3: true, brightness: Brightness.dark),
      home: const _Root(),
    );
  }
}

/// Decides the first screen: setup (download the model) vs. the document library.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text(
            'PocketMind runs on Android, iOS, and desktop.\n'
            'On-device AI inference is not supported in the browser.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return FutureBuilder<bool>(
      future: ServiceLocator.instance.modelManager.isModelInstalled(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.data! ? const LibraryScreen() : const ModelSetupScreen();
      },
    );
  }
}
