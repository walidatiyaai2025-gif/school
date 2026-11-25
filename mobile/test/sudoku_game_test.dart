import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/games/sudoku_game.dart';

void main() {
  test('4x4 beginner progresses to 9x9 and 1000 Sudoku stages', () {
    expect(SudokuGame.gridSizeFor('primary', 1), 4);
    expect(SudokuGame.gridSizeFor('primary', 40), 4);
    expect(SudokuGame.gridSizeFor('primary', 41), 9);
    expect(SudokuGame.gridSizeFor('middle', 1), 9);
    expect(SudokuGame.gridSizeFor('university', 1000), 9);
    expect(SudokuGame.targetCluesFor('primary', 1),
      greaterThan(SudokuGame.targetCluesFor('primary', 39)));
    expect(SudokuGame.targetCluesFor('secondary', 1000),
      lessThan(SudokuGame.targetCluesFor('secondary', 1)));
  });

  test('randomized Sudoku puzzles are all valid with unique solutions', () {
    for (final level in ['primary','middle','secondary','university']) {
      for (final stage in [1, 2, 10, 39, 40, 41, 70, 160, 500, 1000]) {
        final game = SudokuGame(level: level, stage: stage,
          seed: 171 + stage);
        final n = game.size, box = game.boxSize;
        final expected = Set<int>.from(List.generate(n, (i) => i + 1));
        expect(game.givens.length, n*n);
        expect(game.editableCount, greaterThan(0));
        for (var row = 0; row < n; row++) {
          expect(
            {for (var col = 0; col < n; col++)
              game.solution[row*n+col]}, expected);
          expect(
            {for (var col = 0; col < n; col++)
              game.solution[col*n+row]}, expected);
        }
        for (var r = 0; r < n; r += box) {
          for (var c = 0; c < n; c += box) {
            expect({
              for (var y = 0; y < box; y++)
                for (var x = 0; x < box; x++)
                  game.solution[(r+y)*n+c+x],
            }, expected);
          }
        }
        expect(SudokuGame.countSolutions(game.givens, n), 1,
          reason: '$level stage $stage');
        expect(game.completed, isFalse);
        for (var i = 0; i < n*n; i++) {
          if (game.isGiven(i)) {
            expect(game.put(i, 0), isFalse);
            expect(game.givens[i], game.solution[i]);
          }
        }
      }
    }
  });

  test('notes, wrong attempts, undo and assisted completion work', () {
    final game = SudokuGame(level: 'primary', stage: 1);
    final i = game.entries.indexOf(0);
    final correct = game.solution[i];
    final wrong = correct % game.size + 1;
    expect(game.put(i, wrong, pencil: true), isTrue);
    expect(game.notesAt(i), contains(wrong));
    expect(game.entries[i], 0);
    expect(game.put(i, wrong), isTrue);
    expect(game.mistakes, 1);
    expect(game.isCorrect(i), isFalse);
    expect(game.undo(), isTrue);
    expect(game.entries[i], 0);
    expect(game.revealHint(), isNotNull);
    expect(game.hintsUsed, 1);
    expect(game.revealHint(), isNotNull);
    expect(game.revealHint(), isNull);
    for (var c = 0; c < game.entries.length; c++) {
      if (game.isGiven(c) || game.entries[c] == game.solution[c]) continue;
      expect(game.put(c, game.solution[c]), isTrue);
    }
    expect(game.completed, isTrue);
    expect(game.starsForClear(100), 1);
    expect(game.put(i, 0), isFalse);
    expect(game.undo(), isTrue);
    expect(game.completed, isFalse);
  });

  test('blank or duplicate Sudoku inputs cannot claim a win', () {
    final game = SudokuGame(level: 'middle', stage: 25);
    expect(game.starsForClear(120), 0);
    expect(game.put(-1, 1), isFalse);
    expect(game.put(81, 1), isFalse);
    expect(game.put(0, 10), isFalse);
    expect(SudokuGame.countSolutions(List.filled(81, 0), 9,
      maxCount: 2), 2);
    expect(SudokuGame.countSolutions([1,1,...List.filled(14, 0)], 4), 0);
  });
}
