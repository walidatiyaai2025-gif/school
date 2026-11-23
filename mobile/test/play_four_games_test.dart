import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/core/brand.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/screens/play_screen.dart';
import 'package:school_pdf/screens/sudoku_screen.dart';
import 'package:school_pdf/widgets/game_3d_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppStore> store() async {
    SharedPreferences.setMockInitialValues({});
    final s = await AppStore.load();
    s.settings
      ..english = true
      ..level = 'primary'
      ..schoolClass = 'Year 6';
    return s;
  }

  testWidgets('Play displays exactly four glossy cards in a 2x2 grid',
      (tester) async {
    final s = await store();
    await tester.pumpWidget(MaterialApp(
      theme: Brand.theme, home: Scaffold(body: PlayScreen(store: s))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('play-2x2-grid')), findsOneWidget);
    expect(find.byKey(const Key('play-fit-canvas')), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(find.byKey(const Key('xo-game-card')), findsOneWidget);
    expect(find.byKey(const Key('math-match-card')), findsOneWidget);
    expect(find.byKey(const Key('word-hunt-card')), findsOneWidget);
    expect(find.byKey(const Key('sudoku-game-card')), findsOneWidget);
    expect(find.byType(Game3DArt), findsNWidgets(4));
    final a = tester.getTopLeft(find.byKey(const Key('xo-game-card')));
    final b = tester.getTopLeft(find.byKey(const Key('math-match-card')));
    final c = tester.getTopLeft(find.byKey(const Key('word-hunt-card')));
    final d = tester.getTopLeft(find.byKey(const Key('sudoku-game-card')));
    expect((a.dy-b.dy).abs(), lessThan(3));
    expect((c.dy-d.dy).abs(), lessThan(3));
    expect(c.dy, greaterThan(a.dy));
    expect(find.byKey(const Key('play-progress-summary')), findsOneWidget);
    await tester.tap(find.byKey(const Key('play-achievements-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('badge-first-win')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sudoku opens and the number pad, notes and hint work',
      (tester) async {
    final s = await store();
    await tester.pumpWidget(MaterialApp(
      theme: Brand.theme, home: Scaffold(body: PlayScreen(store: s))));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsNothing);
    expect(find.byKey(const Key('play-fit-canvas')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sudoku-game-card')));
    await tester.pumpAndSettle();
    expect(find.byType(SudokuScreen), findsOneWidget);
    expect(find.byKey(const Key('sudoku-board')), findsOneWidget);
    expect(find.byKey(const Key('sudoku-cell-0')), findsOneWidget);
    expect(find.byKey(const Key('sudoku-fit-canvas')), findsOneWidget);
    expect(find.byKey(const Key('sudoku-digit-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sudoku-notes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sudoku-hint')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sudoku-mistakes')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
