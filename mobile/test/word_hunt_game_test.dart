import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/games/word_hunt.dart';

void main() {
  test('Word Hunt places three target words in a solvable grid', () {
    for (final level in ['primary', 'middle', 'secondary', 'university']) {
      final game = WordHuntGame(level: level);
      expect(game.letters.length, WordHuntGame.size * WordHuntGame.size);
      expect(game.targets.length, 3);
      expect(game.tap(-1), isFalse);
      for (var i = 0; i < game.targets.length; i++) {
        final word = game.targets[i];
        final row = i * 2;
        final letters = game.letters
            .skip(row * WordHuntGame.size)
            .take(WordHuntGame.size).join();
        final offset = letters.indexOf(word);
        expect(offset, greaterThanOrEqualTo(0));
        final first = row * WordHuntGame.size + offset;
        expect(game.tap(first), isTrue);
        expect(game.tap(first + word.length - 1), isTrue);
        expect(game.found.contains(word), isTrue);
      }
      expect(game.progress, 3);
      expect(game.finished, isTrue);
      expect(game.tap(0), isFalse);
      game.reset();
      expect(game.finished, isFalse);
      expect(game.progress, 0);
    }
  });

  test('incorrect selections do not clear progress', () {
    final game = WordHuntGame(level: 'primary');
    expect(game.tap(0), isTrue);
    expect(game.tap(WordHuntGame.size), isTrue);
    expect(game.lastMiss, isTrue);
    expect(game.progress, 0);
    expect(game.start, isNull);
  });
}
