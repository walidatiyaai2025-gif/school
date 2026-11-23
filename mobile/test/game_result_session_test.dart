import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/games/stage_clock.dart';
import 'package:school_pdf/services/game_audio.dart';
import 'package:school_pdf/widgets/game_result_dialog.dart';

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
