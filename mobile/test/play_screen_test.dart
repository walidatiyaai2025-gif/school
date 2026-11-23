import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/screens/play_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Play tab opens a mode popup then a working XO game', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: PlayScreen(store: store),
    )));
    expect(find.text('XO • Tic Tac Toe'), findsOneWidget);
    await tester.tap(find.byKey(const Key('xo-game-card')));
    await tester.pumpAndSettle();
    expect(find.text('Play with a friend'), findsOneWidget);
    expect(find.text('Play against computer'), findsOneWidget);
    await tester.tap(find.text('Play with a friend'));
    await tester.pumpAndSettle();
    expect(find.text('Player X'), findsOneWidget);
    await tester.tap(find.byKey(const Key('xo-cell-0')));
    await tester.pumpAndSettle();
    expect(find.text('Player O'), findsOneWidget);
    await tester.tap(find.byKey(const Key('xo-reset')));
    await tester.pumpAndSettle();
    expect(find.text('Player X'), findsOneWidget);
  });

  testWidgets('XO popup can be cancelled without navigation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlayScreen(store: store))));
    await tester.tap(find.byKey(const Key('xo-game-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Play & Learn'), findsOneWidget);
    expect(find.text('Player X'), findsNothing);
  });
}
