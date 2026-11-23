import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_pdf/data/app_store.dart';
import 'package:school_pdf/games/game_stages.dart';
import 'package:school_pdf/games/math_match.dart';
import 'package:school_pdf/games/word_hunt.dart';
import 'package:school_pdf/games/tic_tac_toe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('three stages progress by real completions, never by opening screens',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    expect(store.unlockedGameStage('xo'), 1);
    expect(store.unlockedGameStage('math'), 1);
    expect(store.unlockedGameStage('words'), 1);
    await store.completeGameStage('math', 2); // locked, ignore
    expect(store.unlockedGameStage('math'), 1);
    await store.completeGameStage('math', 1);
    expect(store.unlockedGameStage('math'), 2);
    expect(store.unlockedGameStage('words'), 1);
    final fresh = await AppStore.load();
    expect(fresh.unlockedGameStage('math'), 2);
    await fresh.completeGameStage('math', 1); // stale repeat
    expect(fresh.unlockedGameStage('math'), 2);
    await fresh.completeGameStage('math', 2);
    await fresh.completeGameStage('math', 3);
    expect(fresh.unlockedGameStage('math'), 4);
    expect(GameStages.count, 1000);
    fresh.settings.level = 'middle';
    expect(fresh.unlockedGameStage('math'), 1);
  });

  test('math stages have growing rounds and pass threshold', () {
    expect(GameStages.mathRounds(1), 5);
    expect(GameStages.mathRounds(2), 7);
    expect(GameStages.mathRounds(3), 9);
    expect(GameStages.mathRounds(1000), lessThanOrEqualTo(12));
    expect(GameStages.secondsFor('words', 1000), greaterThan(0));
    expect(GameStages.mathPassed(correct: 3, total: 5), isTrue);
    expect(GameStages.mathPassed(correct: 2, total: 5), isFalse);
    for (var stage = 1; stage <= GameStages.count; stage++) {
      final game = MathMatchGame(level: 'primary', schoolClass: 'Year 6',
        stage: stage, totalRounds: GameStages.mathRounds(stage), seed: stage);
      expect(game.question.choices.length, 4);
      expect(game.question.choices.toSet().length, 4);
    }
  });

  test('word stages use increasingly challenging but placeable words', () {
    for (final level in ['primary', 'middle', 'secondary', 'university']) {
      for (var stage = 1; stage <= GameStages.count; stage++) {
        final words = WordHuntGame.wordsFor(level, stage: stage);
        expect(words.length, stage <= 3 ? 3 : stage < 12 ? 3 : stage < 80 ? 4 : 5);
        expect(words.every((w) => w.length <= WordHuntGame.size), isTrue);
        final game = WordHuntGame(level: level, stage: stage, seed: 40);
        for (final word in words) {
          expect(game.letters.join().contains(word), isTrue);
        }
      }
      expect(WordHuntGame.wordsFor(level, stage: 1),
        isNot(WordHuntGame.wordsFor(level, stage: 3)));
    }
  });

  test('XO stages vary computer strength without changing default AI', () {
    final easy = TicTacToeGame(GameMode.computer, difficulty: 1);
    expect(easy.play(4), isTrue);
    expect(easy.cells[0], 'O');
    final medium = TicTacToeGame(GameMode.computer, difficulty: 2);
    expect(medium.play(4), isTrue);
    expect(medium.cells.where((e) => e == 'O').length, 1);
    final classic = TicTacToeGame(GameMode.computer);
    expect(classic.play(0), isTrue);
    expect(classic.cells[4], 'O');
    expect(GameStages.xoRounds(1), lessThan(GameStages.xoRounds(3)));
  });
}
