import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketmind/core/llm/llm_service.dart';
import 'package:pocketmind/core/rag/embedding_service.dart';
import 'package:pocketmind/core/rag/rag_pipeline.dart';
import 'package:pocketmind/core/rag/text_chunker.dart';
import 'package:pocketmind/core/rag/vector_store.dart';
import 'package:pocketmind/core/theme/app_theme.dart';
import 'package:pocketmind/core/theme/theme_cubit.dart';
import 'package:pocketmind/data/document_repository.dart';
import 'package:pocketmind/data/local_db.dart';
import 'package:pocketmind/data/models.dart';
import 'package:pocketmind/features/chat/chat_screen.dart';
import 'package:pocketmind/features/chat/chat_sessions.dart';
import 'package:pocketmind/features/conversations/conversations_tab.dart';
import 'package:pocketmind/features/library/library_cubit.dart';
import 'package:pocketmind/features/library/library_screen.dart';
import 'package:pocketmind/features/settings/settings_tab.dart';

// ---------------------------------------------------------------------------
// In-memory fakes: no SQLite, no native model.
// ---------------------------------------------------------------------------

class FakeRepo extends DocumentRepository {
  FakeRepo(this.docs)
      : super(
          db: LocalDb(),
          chunker: const TextChunker(),
          embedder: HashingEmbeddingService(),
          vectorStore: VectorStore(LocalDb()),
        );

  final List<DocumentItem> docs;
  final starredCalls = <int, bool>{};

  @override
  Future<List<DocumentItem>> all() async => List.of(docs);
  @override
  Future<void> setStarred(int id, bool starred) async =>
      starredCalls[id] = starred;
  @override
  Future<void> markOpened(int id, DateTime at) async {}
  @override
  Future<void> delete(int id) async => docs.removeWhere((d) => d.id == id);
  @override
  Future<void> deleteAll() async => docs.clear();
}

class FakeVectorStore extends VectorStore {
  FakeVectorStore() : super(LocalDb());

  @override
  Future<List<ScoredChunk>> search(List<double> queryVec,
          {int topK = 4, int? documentId}) async =>
      [
        ScoredChunk(
          DocChunk(
            documentId: documentId ?? 1,
            text: 'An array stores elements in contiguous memory.',
            embedding: const [],
          ),
          0.9,
        ),
      ];
}

class FakeLlm implements LlmService {
  final prompts = <String>[];

  @override
  Stream<String> generate(String prompt) {
    prompts.add(prompt);
    return Stream.fromIterable([
      '## Summary\n',
      '- **Arrays** store items in order\n',
      '- Use `int[] numbers` in Java\n\n',
      '```java\nint[] numbers = {1, 2, 3}; // a very long line of code that should scroll horizontally\n```\n',
      'Done.',
    ]);
  }

  @override
  Future<void> warmUp() async {}
  @override
  Future<void> dispose() async {}
  @override
  bool get isReady => true;
}

List<DocumentItem> sampleDocs() => [
      DocumentItem(
        id: 1,
        title: 'DSA_Full_Notes_Java_with_a_really_long_file_name.pdf',
        sourcePath: '/x/dsa.pdf',
        chunkCount: 44,
        createdAt: DateTime(2026, 11, 1),
        fileSize: 2200000,
      ),
      DocumentItem(
        id: 2,
        title: 'AWS_EC2 LEARNING.pdf',
        sourcePath: '/x/aws.pdf',
        chunkCount: 8,
        createdAt: DateTime(2026, 11, 2),
        fileSize: 876000,
        starred: true,
        lastOpenedAt: DateTime(2026, 11, 3),
      ),
      DocumentItem(
        id: 3,
        title: 'notes.md',
        sourcePath: '/x/notes.md',
        chunkCount: 1,
        createdAt: DateTime(2026, 11, 4),
      ),
    ];

class Harness {
  Harness() {
    repo = FakeRepo(sampleDocs());
    llm = FakeLlm();
    library = LibraryCubit(repo);
    sessions = ChatSessions(RagPipeline(
      embedder: HashingEmbeddingService(),
      vectorStore: FakeVectorStore(),
      llm: llm,
    ));
  }

  late final FakeRepo repo;
  late final FakeLlm llm;
  late final LibraryCubit library;
  late final ChatSessions sessions;

  final themeCubit = ThemeCubit(storage: () async => prefsFile);
  static final prefsFile = File(
      '${Directory.systemTemp.createTempSync('pm_prefs').path}/prefs.json');

  Widget wrap(Widget child,
      {double textScale = 1, ThemeMode? themeMode}) {
    if (themeMode != null) themeCubit.emit(themeMode);
    return BlocProvider.value(
      value: themeCubit,
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode == ThemeMode.system ? ThemeMode.dark : mode,
          builder: (context, c) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: c!,
          ),
          home: RepositoryProvider.value(
            value: sessions,
            child: BlocProvider.value(value: library, child: child),
          ),
        ),
      ),
    );
  }
}

const screenSizes = {
  'small 320x568': Size(320, 568),
  'phone 360x640': Size(360, 640),
  'large 412x915': Size(412, 915),
  'tablet 800x1280': Size(800, 1280),
};

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Advances time without pumpAndSettle (the illustration animates forever).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget tab(Widget child) => Scaffold(body: SafeArea(child: child));

void main() {
  group('Library tab', () {
    for (final entry in screenSizes.entries) {
      testWidgets('renders without overflow on ${entry.key}', (tester) async {
        setSize(tester, entry.value);
        final h = Harness();
        await h.library.load();
        await tester.pumpWidget(h.wrap(tab(const LibraryTab())));
        await settle(tester);

        expect(find.text('My Documents'), findsOneWidget);
        expect(find.text('AWS_EC2 LEARNING.pdf'), findsOneWidget);
        expect(find.text('8 chunks  •  855 KB'), findsOneWidget);
        expect(find.text('1 chunk'), findsOneWidget); // no size known
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('large text on a small screen does not overflow',
        (tester) async {
      setSize(tester, const Size(320, 568));
      final h = Harness();
      await h.library.load();
      await tester.pumpWidget(h.wrap(tab(const LibraryTab()), textScale: 1.3));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Starred and Recent tabs filter the list', (tester) async {
      setSize(tester, const Size(412, 915));
      final h = Harness();
      await h.library.load();
      await tester.pumpWidget(h.wrap(tab(const LibraryTab())));
      await settle(tester);

      await tester.tap(find.text('Starred'));
      await settle(tester);
      expect(find.text('AWS_EC2 LEARNING.pdf'), findsOneWidget);
      expect(find.text('notes.md'), findsNothing);

      await tester.tap(find.text('Recent'));
      await settle(tester);
      expect(find.text('AWS_EC2 LEARNING.pdf'), findsOneWidget);
      expect(find.text('notes.md'), findsNothing);
    });

    testWidgets('search filters by name and close restores the list',
        (tester) async {
      setSize(tester, const Size(412, 915));
      final h = Harness();
      await h.library.load();
      await tester.pumpWidget(h.wrap(tab(const LibraryTab())));
      await settle(tester);

      await tester.tap(find.byTooltip('Search documents'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'aws');
      await settle(tester);
      expect(find.text('AWS_EC2 LEARNING.pdf'), findsOneWidget);
      expect(find.text('notes.md'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await settle(tester);
      expect(find.text('No matches'), findsOneWidget);

      await tester.tap(find.byTooltip('Close search'));
      await settle(tester);
      expect(find.text('notes.md'), findsOneWidget);
    });

    testWidgets('card menu stars a document', (tester) async {
      setSize(tester, const Size(412, 915));
      final h = Harness();
      await h.library.load();
      await tester.pumpWidget(h.wrap(tab(const LibraryTab())));
      await settle(tester);

      // notes.md is newest, so it's the first card.
      await tester.tap(find.byTooltip('Document options').first);
      await settle(tester);
      await tester.tap(find.text('Add to Starred'));
      await settle(tester);

      expect(h.repo.starredCalls[3], isTrue);
      expect(h.library.state.byId(3)!.starred, isTrue);
    });

    testWidgets('sort by name reorders the list', (tester) async {
      setSize(tester, const Size(412, 915));
      final h = Harness();
      await h.library.load();
      await tester.pumpWidget(h.wrap(tab(const LibraryTab())));
      await settle(tester);

      await tester.tap(find.byTooltip('More options'));
      await settle(tester);
      await tester.tap(find.text('Sort by name'));
      await settle(tester);

      final titles = h.library.state.visibleDocuments.map((d) => d.title);
      expect(titles.first, 'AWS_EC2 LEARNING.pdf');
      expect(titles.last, 'notes.md');
    });
  });

  group('Chat screen', () {
    for (final entry in screenSizes.entries) {
      testWidgets('empty state renders on ${entry.key}', (tester) async {
        setSize(tester, entry.value);
        final h = Harness();
        await h.library.load();
        await tester.pumpWidget(
            h.wrap(ChatScreen(document: h.library.state.byId(1)!)));
        await settle(tester);

        expect(find.text('Start a conversation'), findsOneWidget);
        expect(find.text('Summarize this document'), findsOneWidget);
        expect(find.text('Generate notes'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('suggestion sends a prompt and renders a Markdown answer',
        (tester) async {
      setSize(tester, const Size(360, 640));
      final h = Harness();
      await h.library.load();
      await tester
          .pumpWidget(h.wrap(ChatScreen(document: h.library.state.byId(1)!)));
      await settle(tester);

      await tester.tap(find.text('Summarize this document'));
      await settle(tester);

      expect(h.llm.prompts.single, contains('Summarize this document'));
      // Markdown: heading text and list content, without raw markers.
      expect(find.text('Summary'), findsOneWidget);
      expect(find.textContaining('## Summary'), findsNothing);
      expect(find.text('1 source'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Sources expand to show the retrieved chunk.
      await tester.tap(find.text('1 source'));
      await settle(tester);
      expect(find.textContaining('contiguous memory'), findsOneWidget);

      // Conversation survives leaving the screen (session is kept).
      expect(h.sessions.existing(1)!.state.messages, hasLength(2));
    });

    testWidgets('typing and tapping send works; Ask anything focuses input',
        (tester) async {
      setSize(tester, const Size(412, 915));
      final h = Harness();
      await h.library.load();
      await tester
          .pumpWidget(h.wrap(ChatScreen(document: h.library.state.byId(1)!)));
      await settle(tester);

      await tester.tap(find.text('Ask anything…'));
      await settle(tester);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.focusNode!.hasFocus, isTrue);

      await tester.enterText(find.byType(TextField), 'What is an array?\nShort answer');
      await settle(tester);
      await tester.tap(find.byTooltip('Send message'));
      await settle(tester);

      expect(h.llm.prompts.single, contains('What is an array?'));
      expect(find.text('What is an array?\nShort answer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bookmark toggles Starred', (tester) async {
      setSize(tester, const Size(412, 915));
      final h = Harness();
      await h.library.load();
      await tester
          .pumpWidget(h.wrap(ChatScreen(document: h.library.state.byId(1)!)));
      await settle(tester);

      await tester.tap(find.byTooltip('Add to Starred'));
      await settle(tester);
      expect(h.library.state.byId(1)!.starred, isTrue);
      expect(find.byTooltip('Remove from Starred'), findsOneWidget);
    });

    testWidgets('large text with keyboard-sized viewport does not overflow',
        (tester) async {
      setSize(tester, const Size(320, 360));
      final h = Harness();
      await h.library.load();
      await tester.pumpWidget(h.wrap(
          ChatScreen(document: h.library.state.byId(1)!),
          textScale: 1.3));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('Chat and Settings tabs', () {
    for (final entry in screenSizes.entries) {
      testWidgets('render on ${entry.key}', (tester) async {
        setSize(tester, entry.value);
        final h = Harness();
        await h.library.load();

        await tester.pumpWidget(
            h.wrap(tab(ConversationsTab(onAddDocument: () {}))));
        await settle(tester);
        expect(find.text('Chats'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(h.wrap(
            tab(SettingsTab(isModelInstalled: () async => true))));
        await settle(tester);
        expect(find.text('Installed'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Documents'), 200,
            scrollable: find.byType(Scrollable).first);
        expect(find.text('3'), findsOneWidget); // documents count
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Chat tab lists active conversations first', (tester) async {
      setSize(tester, const Size(412, 915));
      final h = Harness();
      await h.library.load();
      await h.sessions.forDocument(3).send('hello');

      await tester
          .pumpWidget(h.wrap(tab(ConversationsTab(onAddDocument: () {}))));
      await settle(tester);
      expect(find.text('ACTIVE CONVERSATIONS'), findsOneWidget);
      expect(find.textContaining('Done.'), findsOneWidget); // last answer preview
    });
  });

  group('Light theme', () {
    for (final entry in {
      'small 320x568': const Size(320, 568),
      'large 412x915': const Size(412, 915),
    }.entries) {
      testWidgets('every screen renders on ${entry.key}', (tester) async {
        setSize(tester, entry.value);
        final h = Harness();
        await h.library.load();
        final screens = <Widget>[
          tab(const LibraryTab()),
          ChatScreen(document: h.library.state.byId(1)!),
          tab(ConversationsTab(onAddDocument: () {})),
          tab(SettingsTab(isModelInstalled: () async => true)),
        ];
        for (final screen in screens) {
          await tester.pumpWidget(h.wrap(screen, themeMode: ThemeMode.light));
          await settle(tester);
          expect(Theme.of(tester.element(find.byWidget(screen))).brightness,
              Brightness.light);
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('chat answer renders in light theme', (tester) async {
      setSize(tester, const Size(360, 640));
      final h = Harness();
      await h.library.load();
      await tester.pumpWidget(h.wrap(
          ChatScreen(document: h.library.state.byId(1)!),
          themeMode: ThemeMode.light));
      await settle(tester);
      await tester.ensureVisible(find.text('Generate notes'));
      await tester.drag(find.text('Start a conversation'), const Offset(0, -200));
      await settle(tester);
      await tester.tap(find.text('Generate notes'));
      await settle(tester);
      expect(h.llm.prompts.single, contains('study notes'));
      expect(find.text('Summary'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Appearance selector switches theme and saves it',
        (tester) async {
      setSize(tester, const Size(412, 915));
      final h = Harness();
      await h.library.load();
      await tester.pumpWidget(h.wrap(
          tab(SettingsTab(isModelInstalled: () async => true)),
          themeMode: ThemeMode.dark));
      await settle(tester);

      Brightness brightness() =>
          Theme.of(tester.element(find.text('Settings'))).brightness;
      expect(brightness(), Brightness.dark);

      await tester.tap(find.text('Light'));
      await settle(tester);
      expect(h.themeCubit.state, ThemeMode.light);
      expect(brightness(), Brightness.light);

      // (Persistence is covered by the ThemeCubit unit test — real file I/O
      // doesn't complete inside a widget test's fake-async zone.)
      await tester.tap(find.text('Dark'));
      await settle(tester);
      expect(brightness(), Brightness.dark);
    });
  });

  group('ThemeCubit', () {
    test('missing or corrupt preferences fall back to System', () async {
      final dir = Directory.systemTemp.createTempSync('pm_theme');
      final file = File('${dir.path}/p.json');
      final cubit = ThemeCubit(storage: () async => file);
      await cubit.load();
      expect(cubit.state, ThemeMode.system);

      file.writeAsStringSync('{not json');
      await cubit.load();
      expect(cubit.state, ThemeMode.system);

      await cubit.setMode(ThemeMode.dark);
      final again = ThemeCubit(storage: () async => file);
      await again.load();
      expect(again.state, ThemeMode.dark);
    });
  });

  group('GenerationLock', () {
    test('a second document cannot generate while one is streaming', () async {
      final h = Harness();
      final gate = Completer<void>();
      final slowRag = RagPipeline(
        embedder: HashingEmbeddingService(),
        vectorStore: FakeVectorStore(),
        llm: _GatedLlm(gate.future),
      );
      final sessions = ChatSessions(slowRag);
      final first = sessions.forDocument(1).send('one');
      await Future<void>.delayed(Duration.zero);
      await sessions.forDocument(2).send('two');
      expect(sessions.forDocument(2).state.notice, isNotNull);
      expect(sessions.forDocument(2).state.messages, isEmpty);
      gate.complete();
      await first;
      await sessions.forDocument(2).send('two again');
      expect(sessions.forDocument(2).state.messages, hasLength(2));
      h.sessions.dispose();
    });
  });
}

class _GatedLlm extends FakeLlm {
  _GatedLlm(this.gate);
  final Future<void> gate;

  @override
  Stream<String> generate(String prompt) async* {
    await gate;
    yield 'ok';
  }
}
