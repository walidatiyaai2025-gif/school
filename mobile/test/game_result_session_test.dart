import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/games/stage_clock.dart';
import 'package:school_pdf/services/game_audio.dart';
import 'package:school_pdf/widgets/game_result_dialog.dart';
import 'package:school_pdf/widgets/motion_fx.dart';
import 'package:school_pdf/widgets/clean_3d_dialog.dart';
import 'package:school_pdf/core/brand.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('stage countdown expires and can be paused', (tester) async {
    final clock = StageClock();
    var expired = 0;
    clock.start(3, () => expired++);
    await tester.pump(const Duration(seconds: 1));
    expect(clock.seconds.value, 2);
    clock.pause();
    await tester.pump(const Duration(seconds: 5));
    expect(clock.seconds.value, 2);
    clock.resume();
    await tester.pump(const Duration(seconds: 2));
    expect(expired, 1);
    expect(clock.seconds.value, 0);
    clock.dispose();
  });

  test('generated offline win, loss, hint, and tap WAVs have valid headers',
      () {
    for (final effect in GameSound.values) {
      final bytes = GameAudio.makeWav(effect);
      expect(bytes.length, greaterThan(44));
      expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF');
      expect(ascii.decode(bytes.sublist(8, 12)), 'WAVE');
      expect(ascii.decode(bytes.sublist(36, 40)), 'data');
    }
    expect(GameAudio.makeWav(GameSound.win),
      isNot(GameAudio.makeWav(GameSound.lose)));
  });

  test('every audio cue is shorter than a quarter second, not music', () {
    for (final sound in GameSound.values) {
      final pcm = GameAudio.makeWav(sound);
      expect(pcm.length, lessThan(44 + 22050 ~/ 2));
      expect(pcm.length, greaterThan(44));
    }
  });

  testWidgets('entry and touch animation settle without looping',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: MotionReveal(order: 3, child: MotionPress(
        onTap: () => taps++,
        child: const SizedBox(width: 150, height: 100,
          child: Center(child: Text('Tap'))),
      )),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Tap'), findsOneWidget);
    await tester.tap(find.text('Tap'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('Clean 3D choice dialog has a dismissible shadowed surface',
      (tester) async {
    await tester.pumpWidget(MaterialApp(theme: Brand.theme,
      home: Scaffold(body: Builder(builder: (ctx) => ElevatedButton(
        onPressed: () => showClean3DDialog<bool>(
          context: ctx, builder: (popupContext) => AlertDialog(
            title: const Text('Opponent'),
            content: const Text('Player or computer?'),
            actions: [TextButton(
              onPressed: () => Navigator.pop(popupContext, true),
              child: const Text('Select'))])),
        child: const Text('Open')),
      ))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(Theme.of(tester.element(find.byType(AlertDialog)))
      .dialogTheme.elevation, greaterThan(0));
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Clean 3D popup displays result and next-stage action',
      (tester) async {
    Future<GameResultAction>? result;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (ctx) => ElevatedButton(
        onPressed: () {
          result = GameResultDialog.show(ctx,
            game: 'Math Match', outcome: GameOutcome.win,
            english: true, result: '8 / 9', stage: 3,
            stars: 3, remaining: 42, hasNext: true);
        }, child: const Text('Show')),
    ))));
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('game-result-popup')), findsOneWidget);
    expect(find.text('Great Job!'), findsOneWidget);
    expect(find.text('8 / 9'), findsOneWidget);
    await tester.tap(find.byKey(const Key('game-result-primary')));
    await tester.pumpAndSettle();
    expect(await result, GameResultAction.next);
  });

  testWidgets('loss popup offers replay rather than skipping a locked level',
      (tester) async {
    Future<GameResultAction>? result;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (ctx) => ElevatedButton(
        onPressed: () {
          result = GameResultDialog.show(ctx,
            game: 'XO', outcome: GameOutcome.loss,
            english: true, result: 'Winner: O', stage: 99,
            stars: 1, remaining: 0, hasNext: false);
        }, child: const Text('Show')),
    ))));
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.text('Good Try!'), findsOneWidget);
    await tester.tap(find.byKey(const Key('game-result-primary')));
    await tester.pumpAndSettle();
    expect(await result, GameResultAction.retry);
  });
}
