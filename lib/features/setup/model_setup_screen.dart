import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/service_locator.dart';
import '../library/library_screen.dart';
import 'model_setup_controller.dart';

class ModelSetupScreen extends StatelessWidget {
  const ModelSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ModelSetupController(ServiceLocator.instance.modelManager)
            ..checkInstalled(),
      child: const _SetupView(),
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ModelSetupController>();

    if (c.status == SetupStatus.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LibraryScreen()),
        );
      });
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology_alt, size: 72),
              const SizedBox(height: 16),
              Text(AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'PocketMind runs an AI model entirely on your device. '
                'Download it once, then use it fully offline.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (c.status == SetupStatus.downloading) ...[
                LinearProgressIndicator(value: c.progress),
                const SizedBox(height: 12),
                Text('${(c.progress * 100).toStringAsFixed(0)}%'),
              ] else if (c.status == SetupStatus.error) ...[
                Text('Download failed: ${c.error}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: c.download,
                  child: const Text('Retry'),
                ),
              ] else
                FilledButton.icon(
                  onPressed: c.download,
                  icon: const Icon(Icons.download),
                  label: const Text('Download model'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
