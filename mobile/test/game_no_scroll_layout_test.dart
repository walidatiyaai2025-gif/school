import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/core/brand.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/games/tic_tac_toe.dart';
import 'package:school_pdf/screens/play_screen.dart';
import 'package:school_pdf/screens/math_match_screen.dart';
import 'package:school_pdf/screens/tic_tac_toe_screen.dart';
import 'package:school_pdf/screens/sudoku_screen.dart';
import 'package:school_pdf/screens/word_hunt_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppStore> makeStore() async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.settings
      ..english = true
      ..level = 'primary'
      ..schoolClass = 'Year 6';
    return store;
  }

  void setSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
  }

  void assertVisible(WidgetTester tester, String key, Size size,
      {double reservedBottom = 0}) {
    final finder = find.byKey(Key(key));
    expect(finder, findsOneWidget);
    final rect = tester.getRect(finder);
    expect(rect.left, greaterThanOrEqualTo(-0.5),
        reason: '$key outside left edge');
    expect(rect.right, lessThanOrEqualTo(size.width + 0.5),
        reason: '$key outside right edge');
    expect(rect.top, greaterThanOrEqualTo(-0.5),
        reason: '$key outside top edge');
    expect(rect.bottom, lessThanOrEqualTo(size.height - reservedBottom + 0.5),
        reason: '$key obscured by bottom bar');
  }

  for (final size in [const Size(360, 640), const Size(412, 820)]) {
    testWidgets('Play 2x2 fits without scroll or covered cards at $size',
        (tester) async {
      setSize(tester, size);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final store = await makeStore();
      await tester.pumpWidget(MaterialApp(theme: Brand.theme,
        home: Scaffold(
          appBar: AppBar(toolbarHeight: 48),
          body: PlayScreen(store: store),
          bottomNavigationBar: const SizedBox(height: 160),
        )));
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsNothing);
      expect(find.byKey(const Key('play-fit-canvas')), findsOneWidget);
      expect(find.byKey(const Key('play-2x2-grid')), findsOneWidget);
      for (final name in ['xo-game-card', 'math-match-card',
          'word-hunt-card', 'sudoku-game-card']) {
        assertVisible(tester, name, size, reservedBottom: 160);
        expect(find.byKey(Key(name)).hitTestable(), findsOneWidget);
      }
      assertVisible(tester, 'play-progress-summary', size,
          reservedBottom: 160);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Math answers and next control fit without scroll at $size',
        (tester) async {
      setSize(tester, size);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final store = await makeStore();
      await tester.pumpWidget(MaterialApp(theme: Brand.theme,
          home: MathMatchScreen(store: store)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ListView), findsNothing);
      for (final key in ['math-fit-canvas', 'math-question',
          'math-choice-0', 'math-choice-3', 'math-next']) {
        assertVisible(tester, key, size);
      }
      expect(find.byKey(const Key('math-choice-0')).hitTestable(),
        findsOneWidget);
      await tester.tap(find.byKey(const Key('math-choice-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('math-feedback')), findsOneWidget);
      await tester.tap(find.byKey(const Key('math-next')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('XO board and replay fit without scroll at $size',
        (tester) async {
      setSize(tester, size);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final store = await makeStore();
      await tester.pumpWidget(MaterialApp(theme: Brand.theme,
          home: TicTacToeScreen(mode: GameMode.friend,
            english: true, store: store)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ListView), findsNothing);
      for (final key in ['xo-fit-canvas', 'xo-cell-0',
          'xo-cell-8', 'xo-reset']) {
        assertVisible(tester, key, size);
      }
      expect(find.byKey(const Key('xo-cell-8')).hitTestable(),
        findsOneWidget);
      await tester.tap(find.byKey(const Key('xo-cell-8')));
      await tester.pump();
      expect(find.text('Player O'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Word Hunt board and footer remain accessible at $size',
        (tester) async {
      setSize(tester, size);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final store = await makeStore();
      await tester.pumpWidget(MaterialApp(theme: Brand.theme,
          home: WordHuntScreen(store: store)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ListView), findsNothing);
      for (final key in ['word-fit-canvas', 'word-cell-0',
          'word-cell-48', 'word-reset']) {
        assertVisible(tester, key, size);
      }
      expect(find.byKey(const Key('word-cell-48')).hitTestable(),
        findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Sudoku keypad, hints and board fit without scroll at $size',
        (tester) async {
      setSize(tester, size);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final store = await makeStore();
      await tester.pumpWidget(MaterialApp(theme: Brand.theme,
          home: SudokuScreen(store: store)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ListView), findsNothing);
      for (final key in ['sudoku-fit-canvas', 'sudoku-board',
          'sudoku-digit-1', 'sudoku-hint', 'sudoku-restart']) {
        assertVisible(tester, key, size);
      }
      expect(find.byKey(const Key('sudoku-digit-1')).hitTestable(),
        findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
