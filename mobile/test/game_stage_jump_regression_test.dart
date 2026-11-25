import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/core/brand.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/screens/math_match_screen.dart';
import 'package:school_pdf/widgets/game_stage_strip.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Jump opens and cancels safely with keyboard focus', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(MaterialApp(
      theme: Brand.theme,
      home: Scaffold(body: GameStageStrip(
        current: 1, unlocked: 3, english: true,
        onSelect: selected.add,
      )),
    ));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('game-stage-jump')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('game-stage-input')), findsOneWidget);
      await tester.tap(find.byKey(const Key('game-stage-input')));
      await tester.enterText(
          find.byKey(const Key('game-stage-input')), '2');
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('game-stage-input')), findsNothing);
      expect(tester.takeException(), isNull);
    }
    expect(selected, isEmpty);
  });

  testWidgets('Jump refuses locked levels, then selects unlocked level',
      (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(MaterialApp(
      theme: Brand.theme,
      home: Scaffold(body: GameStageStrip(
        current: 1, unlocked: 3, english: true,
        onSelect: selected.add,
      )),
    ));
    await tester.tap(find.byKey(const Key('game-stage-jump')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('game-stage-input')), '999');
    await tester.tap(find.byKey(const Key('game-stage-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('game-stage-input')), findsOneWidget);
    expect(selected, isEmpty);
    await tester.enterText(
      find.byKey(const Key('game-stage-input')), '2');
    await tester.tap(find.byKey(const Key('game-stage-submit')));
    await tester.pumpAndSettle();
    expect(selected, [2]);
    expect(find.byKey(const Key('game-stage-input')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Math Match Jump opens and closes without red-screen assertion',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.settings
      ..english = true
      ..level = 'primary'
      ..schoolClass = 'Year 6';
    await tester.pumpWidget(MaterialApp(
      theme: Brand.theme,
      home: MathMatchScreen(store: store),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const Key('game-stage-jump')));
    await tester.pumpAndSettle();
    expect(find.text('Jump to a level'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('math-question')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('game-stage-jump')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('game-stage-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('game-stage-input')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
