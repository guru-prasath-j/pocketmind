import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants.dart';
import '../../core/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/buttons.dart';
import '../home/home_shell.dart';
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
            MaterialPageRoute(builder: (_) => const HomeShell()),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<ModelSetupCubit>();
        return Scaffold(
          body: AmbientBackground(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const AppLogo(size: 84),
                      const SizedBox(height: 24),
                      const BrandTitle(fontSize: 32),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.tagline,
                        style: TextStyle(color: context.colors.accent),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'PocketMind runs an AI model entirely on your device. '
                        'Install the bundled model once and use it fully offline.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.colors.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 40),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _action(context, state, cubit),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _action(
      BuildContext context, ModelSetupState state, ModelSetupCubit cubit) {
    switch (state.status) {
      case SetupStatus.downloading:
        return Column(
          key: const ValueKey('downloading'),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: state.progress, minHeight: 6),
            ),
            const SizedBox(height: 12),
            Text('${(state.progress * 100).toStringAsFixed(0)}%'),
          ],
        );
      case SetupStatus.installing:
        return Column(
          key: const ValueKey('installing'),
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Installing model, please wait…',
                style: TextStyle(color: context.colors.textSecondary)),
          ],
        );
      case SetupStatus.error:
        return Column(
          key: const ValueKey('error'),
          children: [
            Text(
              'Setup failed: ${state.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: cubit.installFromAsset,
            ),
          ],
        );
      case SetupStatus.idle:
      case SetupStatus.ready:
        return GradientButton(
          key: const ValueKey('install'),
          label: 'Install model',
          icon: Icons.download_rounded,
          onPressed: cubit.installFromAsset,
        );
    }
  }
}
