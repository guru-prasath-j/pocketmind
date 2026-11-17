import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants.dart';
import 'core/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/widgets/brand.dart';
import 'features/home/home_shell.dart';
import 'features/setup/model_setup_screen.dart';

class PocketMindApp extends StatelessWidget {
  const PocketMindApp({super.key, required this.themeCubit});

  /// Created (and its saved choice loaded) in main(), before the first frame,
  /// so the app never flashes the wrong theme.
  final ThemeCubit themeCubit;

  static final _light = AppTheme.light();
  static final _dark = AppTheme.dark();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: themeCubit,
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) => MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: _light,
          darkTheme: _dark,
          themeMode: mode,
          builder: (context, child) => _SystemBars(child: child!),
          home: const _Root(),
        ),
      ),
    );
  }
}

/// Keeps status/navigation bar icons readable in both themes.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: base.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: context.colors.backgroundDeep,
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
      ),
      child: child,
    );
  }
}

/// Decides the first screen: setup (install the model) vs. the main app.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const _Splash(
        message: 'PocketMind runs on Android, iOS, and desktop.\n'
            'On-device AI inference is not supported in the browser.',
      );
    }
    return FutureBuilder<bool>(
      future: ServiceLocator.instance.modelManager.isModelInstalled(),
      builder: (context, snap) {
        if (!snap.hasData) return const _Splash();
        return snap.data! ? const HomeShell() : const ModelSetupScreen();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 72),
                const SizedBox(height: 20),
                const BrandTitle(fontSize: 30),
                const SizedBox(height: 24),
                if (message == null)
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
