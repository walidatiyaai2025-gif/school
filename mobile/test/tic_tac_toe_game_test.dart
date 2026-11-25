import 'package:flutter_test/flutter_test.dart';
import 'package:school_pdf/games/tic_tac_toe.dart';

void main() {
  test('friend mode alternates X and O and detects a row win', () {
    final game = TicTacToeGame(GameMode.friend);
    expect(game.play(0), true);
    expect(game.currentPlayer, 'O');
    expect(game.play(0), false);
    expect(game.play(3), true);
    expect(game.play(1), true);
    expect(game.play(4), true);
    expect(game.play(2), true);
    expect(game.winner, 'X');
    expect(game.finished, true);
    expect(game.play(5), false);
    game.reset();
    expect(game.finished, false);
    expect(game.currentPlayer, 'X');
    expect(game.cells.every((cell) => cell.isEmpty), true);
  });

  test('detects diagonal victory and rejects invalid indices', () {
    final game = TicTacToeGame(GameMode.friend);
    expect(game.play(-1), false);
    expect(game.play(9), false);
    for (final i in [0, 1, 4, 2, 8]) {
      expect(game.play(i), true);
    }
    expect(game.winner, 'X');
    expect(game.isDraw, false);
  });

  test('full board with no line is a draw', () {
    final game = TicTacToeGame(GameMode.friend);
    for (final i in [0, 1, 2, 4, 3, 5, 7, 6, 8]) {
      expect(game.play(i), true);
    }
    expect(game.isDraw, true);
    expect(game.winner, isNull);
    expect(game.play(0), false);
  });

  test('computer responds as O and blocks a winning move', () {
    final game = TicTacToeGame(GameMode.computer);
    expect(game.play(0), true);
    expect(game.cells.where((c) => c == 'O').length, 1);
    expect(game.currentPlayer, 'X');
    expect(game.play(1), true);
    expect(game.cells[2], 'O');
  });

  test('computer never loses to any human legal sequence', () {
    void visit(List<int> humanMoves) {
      final game = TicTacToeGame(GameMode.computer);
      for (final index in humanMoves) {
        expect(game.play(index), true);
      }
      expect(game.winner, isNot('X'));
      if (game.finished) return;
      for (var i = 0; i < 9; i++) {
        if (game.cells[i].isEmpty) visit([...humanMoves, i]);
      }
    }
    visit([]);
  });
}
