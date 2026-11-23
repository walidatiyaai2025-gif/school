import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/games/math_match.dart';

void main() {
  test('Math Match creates four unique choices with exactly one answer', () {
    for (final level in ['primary', 'middle', 'secondary', 'university']) {
      final game = MathMatchGame(level: level, schoolClass: 'Year 6');
      for (var i = 0; i < game.totalRounds; i++) {
        final q = game.question;
        expect(q.choices.length, 4);
        expect(q.choices.toSet().length, 4);
        expect(q.choices.contains(q.answer), isTrue);
        expect(q.choices.every((v) => v >= 0), isTrue);
        expect(game.choose(q.answer), isTrue);
        expect(game.choose(q.answer), isFalse);
        if (i < game.totalRounds - 1) {
          expect(game.next(), isTrue);
        }
      }
      expect(game.finished, isTrue);
      expect(game.score, game.totalRounds);
      expect(game.next(), isFalse);
      game.reset();
      expect(game.score, 0);
      expect(game.round, 1);
      expect(game.finished, isFalse);
    }
  });

  test('wrong answer is accepted once, but does not increase score', () {
    final game = MathMatchGame(level: 'primary', schoolClass: 'Year 2');
    final wrong = game.question.choices.firstWhere(
        (v) => v != game.question.answer);
    expect(game.next(), isFalse);
    expect(game.choose(wrong), isTrue);
    expect(game.correct, isFalse);
    expect(game.score, 0);
    expect(game.choose(game.question.answer), isFalse);
    expect(game.next(), isTrue);
    expect(game.answered, isFalse);
  });

  test('early-primary questions use only addition and subtraction', () {
    final game = MathMatchGame(level: 'primary', schoolClass: 'Year 1');
    for (var i = 0; i < game.totalRounds; i++) {
      expect(game.question.expression.contains('×'), isFalse);
      expect(game.question.expression.contains('÷'), isFalse);
      game.choose(game.question.answer);
      if (!game.finished) game.next();
    }
  });
}
