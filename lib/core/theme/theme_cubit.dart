import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Holds the user's appearance choice (System / Light / Dark) and remembers it
/// in a small JSON file in the app's documents folder.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({Future<File> Function()? storage})
      : _storage = storage ?? _defaultStorage,
        super(ThemeMode.system);

  final Future<File> Function() _storage;

  static Future<File> _defaultStorage() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'preferences.json'));
  }

  /// Restores the saved choice. Missing or unreadable file → System.
  Future<void> load() async {
    try {
      final file = await _storage();
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final saved = ThemeMode.values.asNameMap()[json['themeMode']];
      if (saved != null) emit(saved);
    } catch (_) {
      // Corrupt or inaccessible preferences: keep the default.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    try {
      final file = await _storage();
      await file.writeAsString(jsonEncode({'themeMode': mode.name}));
    } catch (_) {
      // Not fatal: the choice still applies for this session.
    }
  }
}
