/// Pure Dart rules for an offline, two-player or single-player XO game.
enum GameMode { friend, computer }

class TicTacToeGame {
  TicTacToeGame(this.mode);

  final GameMode mode;
  final List<String> _cells = List<String>.filled(9, '');
  String _turn = 'X';
  String? _winner;
  bool _draw = false;

  List<String> get cells => List<String>.unmodifiable(_cells);
  String get currentPlayer => _turn;
  String? get winner => _winner;
  bool get isDraw => _draw;
  bool get finished => _winner != null || _draw;

  void reset() {
    for (var i = 0; i < _cells.length; i++) {
      _cells[i] = '';
    }
    _turn = 'X';
    _winner = null;
    _draw = false;
  }

  /// In computer mode the human plays X and the computer answers as O.
  /// Returns false for invalid moves or attempts after the game has ended.
  bool play(int index) {
    if (finished || index < 0 || index >= 9 || _cells[index].isNotEmpty) {
      return false;
    }
    _place(index, _turn);
    if (mode == GameMode.computer && !finished) {
      _place(_bestComputerMove(), 'O');
    }
    return true;
  }

  void _place(int index, String mark) {
    _cells[index] = mark;
    if (_wins(mark)) {
      _winner = mark;
    } else if (!_cells.contains('')) {
      _draw = true;
    } else {
      _turn = mark == 'X' ? 'O' : 'X';
    }
  }

  static const _lines = <List<int>>[
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  bool _wins(String mark) => _lines.any((line) =>
      line.every((index) => _cells[index] == mark));

  static const _moveOrder = <int>[4, 0, 2, 6, 8, 1, 3, 5, 7];

  int _bestComputerMove() {
    var bestMove = -1;
    var bestScore = -1000;
    for (final index in _moveOrder) {
      if (_cells[index].isNotEmpty) continue;
      _cells[index] = 'O';
      final score = _minimax(false, 1);
      _cells[index] = '';
      if (score > bestScore) {
        bestScore = score;
        bestMove = index;
      }
    }
    return bestMove;
  }

  int _minimax(bool computerTurn, int depth) {
    if (_wins('O')) return 10 - depth;
    if (_wins('X')) return depth - 10;
    if (!_cells.contains('')) return 0;

    var best = computerTurn ? -1000 : 1000;
    for (final index in _moveOrder) {
      if (_cells[index].isNotEmpty) continue;
      _cells[index] = computerTurn ? 'O' : 'X';
      final score = _minimax(!computerTurn, depth + 1);
      _cells[index] = '';
      if (computerTurn && score > best) best = score;
      if (!computerTurn && score < best) best = score;
    }
    return best;
  }
}
