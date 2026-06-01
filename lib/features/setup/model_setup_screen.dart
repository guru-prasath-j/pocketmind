import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants.dart';
import '../../core/service_locator.dart';
import '../library/library_screen.dart';
import 'model_setup_cubit.dart';

class ModelSetupScreen extends StatelessWidget {
  const ModelSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ModelSetupCubit(ServiceLocator.instance.modelManager)
            ..checkInstalled(),
      child: const _SetupView(),
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ModelSetupCubit, ModelSetupState>(
      listener: (context, state) {
        if (state.status == SetupStatus.ready) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LibraryScreen()),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<ModelSetupCubit>();
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
                  if (state.status == SetupStatus.downloading) ...[
                    LinearProgressIndicator(value: state.progress),
                    const SizedBox(height: 12),
                    Text('${(state.progress * 100).toStringAsFixed(0)}%'),
                  ] else if (state.status == SetupStatus.error) ...[
                    Text('Download failed: ${state.error}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: cubit.download,
                      child: const Text('Retry'),
                    ),
                  ] else
                    FilledButton.icon(
                      onPressed: cubit.download,
                      icon: const Icon(Icons.download),
                      label: const Text('Download model'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
