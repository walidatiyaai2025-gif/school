import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/screens/play_screen.dart';
import 'package:school_pdf/widgets/game_3d_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppStore> storeForTest() async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.settings
      ..english = true
      ..level = 'primary'
      ..schoolClass = 'Year 6';
    return store;
  }

  testWidgets('three 3D cards navigate to playable Math Match',
      (tester) async {
    final store = await storeForTest();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PlayScreen(store: store))));
    expect(find.byKey(const Key('xo-game-card')), findsOneWidget);
    expect(find.byKey(const Key('math-match-card')), findsOneWidget);
    expect(find.byKey(const Key('word-hunt-card')), findsOneWidget);
    expect(find.byType(Game3DArt), findsNWidgets(3));

    await tester.ensureVisible(find.byKey(const Key('math-match-card')));
    await tester.tap(find.byKey(const Key('math-match-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('math-question')), findsOneWidget);
    expect(find.byKey(const Key('math-next')), findsOneWidget);
    await tester.tap(find.byKey(const Key('math-choice-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('math-feedback')), findsOneWidget);
    await tester.tap(find.byKey(const Key('math-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('math-question')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Word Hunt opens letter grid, gives feedback, resets',
      (tester) async {
    final store = await storeForTest();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PlayScreen(store: store))));
    await tester.ensureVisible(find.byKey(const Key('word-hunt-card')));
    await tester.tap(find.byKey(const Key('word-hunt-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('word-cell-0')), findsOneWidget);
    expect(find.byKey(const Key('word-cell-48')), findsOneWidget);
    await tester.tap(find.byKey(const Key('word-cell-0')));
    await tester.tap(find.byKey(const Key('word-cell-7')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('word-feedback')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('word-target-CAT')),
      180, scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('word-target-CAT')), findsOneWidget);
    await tester.tap(find.byKey(const Key('word-reset')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('word-feedback')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
