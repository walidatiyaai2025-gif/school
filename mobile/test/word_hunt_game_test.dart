import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/games/word_hunt.dart';

void main() {
  test('straight selections include rows, columns and diagonals both ways',
      () {
    expect(WordHuntGame.straightPath(0, 3), [0, 1, 2, 3]);
    expect(WordHuntGame.straightPath(0, 21), [0, 7, 14, 21]);
    expect(WordHuntGame.straightPath(0, 24), [0, 8, 16, 24]);
    expect(WordHuntGame.straightPath(6, 24), [6, 12, 18, 24]);
    expect(WordHuntGame.straightPath(24, 6), [24, 18, 12, 6]);
    expect(WordHuntGame.straightPath(0, 9), isEmpty);
  });

  test('early puzzles include horizontal, vertical and diagonal solutions',
      () {
    for (final level in ['primary', 'middle', 'secondary', 'university']) {
      final axes = <WordOrientation>{};
      for (final seed in [2026, 13, 17, 99]) {
        final game = WordHuntGame(level: level, stage: 1, seed: seed);
        for (final word in game.targets) {
          axes.add(game.orientationOf(word));
        }
      }
      expect(axes, containsAll(WordOrientation.values));
    }
  });

  test('every word has a placed, tappable solution across stage difficulties',
      () {
    for (final level in ['primary', 'middle', 'secondary', 'university']) {
      for (final stage in [1, 2, 3, 4, 30, 81, 267, 750, 1000]) {
        final game = WordHuntGame(
          level: level, stage: stage, seed: 2026 + stage);
        expect(game.tap(-1), isFalse);
        for (final word in game.targets) {
          final path = game.wordPath(word);
          expect(path.length, word.length);
          for (var i = 0; i < path.length; i++) {
            expect(game.letters[path[i]], word[i]);
          }
          final previous = game.score;
          expect(game.tap(path.last), isTrue); // reverse endpoints
          expect(game.tap(path.first), isTrue);
          expect(game.lastFound, word);
          expect(game.score, greaterThan(previous));
          expect(game.lastFoundCells, path);
        }
        expect(game.finished, isTrue);
        expect(game.bestCombo, game.targets.length);
        expect(game.tap(0), isFalse);
        game.reset();
        expect(game.score, 0);
        expect(game.combo, 0);
        expect(game.progress, 0);
      }
    }
  });

  test('incorrect angled guesses break combo without clearing finds', () {
    final game = WordHuntGame(level: 'primary', stage: 4, seed: 16);
    final path = game.wordPath(game.targets.first);
    game.tap(path.first);
    game.tap(path.last);
    expect(game.progress, 1);
    expect(game.combo, 1);
    final found = game.foundCells.toSet();
    game.tap(0);
    game.tap(9); // not a straight line
    expect(game.lastMiss, isTrue);
    expect(game.combo, 0);
    expect(game.misses, 1);
    expect(game.foundCells, found);
  });

  test('hint points to the actual start of the next hidden word', () {
    final game = WordHuntGame(level: 'secondary', stage: 997);
    for (final word in game.targets) {
      expect(game.hintCell, game.wordPath(word).first);
      final path = game.wordPath(word);
      game.tap(path.first);
      game.tap(path.last);
    }
    expect(game.hintCell, isNull);
  });
}
