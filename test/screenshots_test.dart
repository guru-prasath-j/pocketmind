// Renders real-font screenshots of each screen in light and dark mode for
// visual review. Not part of the normal suite — run explicitly with:
//   flutter test test/screenshots_test.dart --dart-define=SCREENSHOTS=true
// PNGs are written to build/screenshots/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketmind/features/chat/chat_screen.dart';
import 'package:pocketmind/features/conversations/conversations_tab.dart';
import 'package:pocketmind/features/library/library_screen.dart';
import 'package:pocketmind/features/settings/settings_tab.dart';

import 'ui_test.dart' as ui_test;

const _enabled = bool.fromEnvironment('SCREENSHOTS');

Future<void> _loadFonts() async {
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? r'C:\flutter';
  final dir = '$sdk/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String f) async =>
      ByteData.sublistView(await File('$dir/$f').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final f in ['regular', 'medium', 'bold', 'italic']) {
    roboto.addFont(read('roboto-$f.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')
        ..addFont(read('materialicons-regular.otf')))
      .load();
  // Code blocks use the generic 'monospace' family; map it to Consolas when
  // available (Windows) so code renders instead of placeholder boxes.
  final mono = File(r'C:\Windows\Fonts\consola.ttf');
  if (mono.existsSync()) {
    await (FontLoader('monospace')
          ..addFont(Future.value(ByteData.sublistView(mono.readAsBytesSync()))))
        .load();
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('shot')));
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  final bytes = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png));
  final out = File('build/screenshots/$name.png')..createSync(recursive: true);
  out.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  setUpAll(() async {
    if (_enabled) await _loadFonts();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('screens in ${mode.name}', (tester) async {
      ui_test.setSize(tester, const Size(412, 915));
      final h = ui_test.Harness();
      await h.library.load();
      await h.library.toggleStar(2);
      await h.library.markOpened(2);

      Future<void> capture(String name, Widget screen,
          [Future<void> Function()? act]) async {
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('shot'),
          child: h.wrap(screen, themeMode: mode),
        ));
        await ui_test.settle(tester);
        if (act != null) {
          await act();
          await ui_test.settle(tester);
        }
        await _shot(tester, '${mode.name}_$name');
      }

      await capture('library', ui_test.tab(const LibraryTab()));
      await capture('chat_empty', ChatScreen(document: h.library.state.byId(1)!));
      await capture('chat_answer', ChatScreen(document: h.library.state.byId(1)!),
          () async {
        await tester.tap(find.text('Summarize this document'));
        await ui_test.settle(tester);
        await tester.tap(find.text('1 source'));
      });
      await capture('chats_tab', ui_test.tab(ConversationsTab(onAddDocument: () {})));
      await capture('settings',
          ui_test.tab(SettingsTab(isModelInstalled: () async => true)));
    }, skip: !_enabled);
  }
}
