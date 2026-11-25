import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/core/brand.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/screens/word_hunt_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Word Hunt fits without a scrolling page at 360x720',
      (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.settings
      ..english = true
      ..level = 'primary'
      ..schoolClass = 'Year 6';
    await tester.pumpWidget(MaterialApp(
      theme: Brand.theme, home: WordHuntScreen(store: store)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('word-fit-canvas')), findsOneWidget);
    expect(find.byKey(const Key('word-letter-grid')), findsOneWidget);
    expect(find.byKey(const Key('word-cell-48')), findsOneWidget);
    expect(find.descendant(
      of: find.byType(WordHuntScreen),
      matching: find.byType(ListView)), findsNothing);
    final board = tester.getRect(find.byKey(const Key('word-letter-grid')));
    final button = tester.getRect(find.byKey(const Key('word-reset')));
    expect(board.bottom, lessThan(button.top));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('word-cell-0')));
    await tester.tap(find.byKey(const Key('word-cell-9')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('word-feedback')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
