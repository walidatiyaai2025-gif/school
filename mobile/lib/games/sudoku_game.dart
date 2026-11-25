import 'dart:math';

import 'game_stages.dart';

/// Offline number-placement puzzles, generated from a valid solution.
/// Each published puzzle has exactly one solution (verified during carving).
/// Beginner primary levels start with 4×4 and progress to standard 9×9.
class SudokuGame {
  SudokuGame({
    required this.level,
    this.stage = 1,
    int seed = 2026,
  }) : _random = Random(seed + stage * 7919 + _levelSalt(level)) {
    _generate();
  }

  final String level;
  final int stage;
  final Random _random;
  late final int size;
  late final int boxSize;
  late final List<int> solution;
  late final List<int> givens;
  late List<int> entries;
  final List<_SudokuMove> _history = [];
  final Map<int, Set<int>> _notes = {};
  int mistakes = 0;
  int hintsUsed = 0;

  static int _levelSalt(String level) =>
      level.codeUnits.fold<int>(0, (a, b) => (a * 37 + b) % 1000003);

  bool get completed =>
      entries.asMap().entries.every((e) => e.value == solution[e.key]);
  bool get solved => completed;
  int get filled => entries.where((n) => n != 0).length;
  int get editableCount => givens.where((n) => n == 0).length;
  bool isGiven(int i) => i >= 0 && i < givens.length && givens[i] != 0;
  bool isCorrect(int i) => entries[i] == 0 || entries[i] == solution[i];
  bool get canUndo => _history.isNotEmpty;
  Set<int> notesAt(int i) => Set<int>.unmodifiable(_notes[i] ?? {});
  int get maxHints => 2;

  static int gridSizeFor(String level, int stage) =>
      level == 'primary' && stage <= 40 ? 4 : 9;

  /// Advanced tiers request fewer clues, but always retain uniqueness.
  static int targetCluesFor(String level, int stage) {
    final size = gridSizeFor(level, stage);
    if (size == 4) {
      return (13 - (stage - 1) ~/ 9).clamp(8, 13).toInt();
    }
    final band = GameStages.difficultyBand(stage);
    return (49 - band ~/ 2).clamp(29, 49).toInt();
  }

  void _generate() {
    size = gridSizeFor(level, stage);
    boxSize = sqrt(size).toInt();
    final base = List<int>.generate(size * size, (index) {
      final row = index ~/ size, col = index % size;
      return (row * boxSize + row ~/ boxSize + col) % size + 1;
    });
    final digitOrder = List<int>.generate(size, (i) => i + 1)
      ..shuffle(_random);
    final rows = _shuffledGroups();
    final cols = _shuffledGroups();
    final transposed = _random.nextBool();
    solution = List<int>.generate(size * size, (index) {
      final r = rows[index ~/ size];
      final c = cols[index % size];
      final i = transposed ? c * size + r : r * size + c;
      return digitOrder[base[i] - 1];
    });
    final puzzle = List<int>.of(solution);
    final indices = List<int>.generate(size * size, (i) => i)
      ..shuffle(_random);
    final target = targetCluesFor(level, stage);
    var remaining = puzzle.length;
    for (final index in indices) {
      if (remaining <= target) break;
      final old = puzzle[index];
      puzzle[index] = 0;
      if (countSolutions(puzzle, size, maxCount: 2) != 1) {
        puzzle[index] = old;
      } else {
        remaining--;
      }
    }
    // Even when a target isn't reached, puzzle remains uniquely solvable.
    givens = List<int>.unmodifiable(puzzle);
    entries = List<int>.of(givens);
  }

  List<int> _shuffledGroups() {
    final groups = List<int>.generate(boxSize, (i) => i)..shuffle(_random);
    return [
      for (final group in groups)
        for (final offset in (List<int>.generate(boxSize, (i) => i)
          ..shuffle(_random)))
          group * boxSize + offset,
    ];
  }

  /// Exact uniqueness check via minimum-remaining-values backtracking.
  /// Zero means invalid/no solution, two means multiple solutions.
  static int countSolutions(List<int> board, int size, {int maxCount = 2}) {
    if ((size != 4 && size != 9) || board.length != size * size) return 0;
    final box = sqrt(size).toInt();
    final mask = (1 << size) - 1;
    final rows = List<int>.filled(size, 0);
    final cols = List<int>.filled(size, 0);
    final boxes = List<int>.filled(size, 0);
    final pending = <int>[];
    for (var i = 0; i < board.length; i++) {
      final digit = board[i];
      if (digit == 0) {
        pending.add(i);
        continue;
      }
      if (digit < 1 || digit > size) return 0;
      final bit = 1 << (digit - 1);
      final r = i ~/ size, c = i % size;
      final b = (r ~/ box) * box + c ~/ box;
      if (((rows[r] | cols[c] | boxes[b]) & bit) != 0) return 0;
      rows[r] |= bit; cols[c] |= bit; boxes[b] |= bit;
    }
    var solutions = 0;
    void solve(int depth) {
      if (solutions >= maxCount) return;
      if (depth == pending.length) { solutions++; return; }
      var best = -1, bestMask = 0, bestCount = size + 1;
      for (var j = depth; j < pending.length; j++) {
        final pos = pending[j], r = pos ~/ size, c = pos % size;
        final boxIndex = (r ~/ box) * box + c ~/ box;
        final choices = mask & ~(rows[r] | cols[c] | boxes[boxIndex]);
        final count = _bitCount(choices);
        if (count < bestCount) {
          best = j; bestMask = choices; bestCount = count;
          if (count <= 1) break;
        }
      }
      if (bestCount == 0) return;
      final temp = pending[depth];
      pending[depth] = pending[best];
      pending[best] = temp;
      final i = pending[depth], r = i ~/ size, c = i % size;
      final b = (r ~/ box) * box + c ~/ box;
      var bits = bestMask;
      while (bits != 0 && solutions < maxCount) {
        final bit = bits & -bits;
        bits -= bit;
        rows[r] |= bit; cols[c] |= bit; boxes[b] |= bit;
        solve(depth + 1);
        rows[r] &= ~bit; cols[c] &= ~bit; boxes[b] &= ~bit;
      }
      pending[best] = pending[depth];
      pending[depth] = temp;
    }
    solve(0);
    return solutions;
  }

  static int _bitCount(int bits) {
    var n = 0;
    while (bits != 0) { bits &= bits - 1; n++; }
    return n;
  }

  bool put(int index, int value, {bool pencil = false}) {
    if (index < 0 || index >= entries.length || isGiven(index) ||
        value < 0 || value > size || completed) return false;
    if (pencil && value != 0) {
      final set = _notes.putIfAbsent(index, () => <int>{});
      if (!set.add(value)) set.remove(value);
      return true;
    }
    if (entries[index] == value) return false;
    _history.add(_SudokuMove(index, entries[index]));
    entries[index] = value;
    _notes.remove(index);
    if (value != 0 && value != solution[index]) mistakes++;
    return true;
  }

  bool undo() {
    if (_history.isEmpty) return false;
    final move = _history.removeLast();
    entries[move.index] = move.oldValue;
    return true;
  }

  int? revealHint() {
    if (hintsUsed >= maxHints || completed) return null;
    final emptyOrWrong = [
      for (var i = 0; i < entries.length; i++)
        if (!isGiven(i) && entries[i] != solution[i]) i,
    ];
    if (emptyOrWrong.isEmpty) return null;
    final index = emptyOrWrong[_random.nextInt(emptyOrWrong.length)];
    _history.add(_SudokuMove(index, entries[index]));
    entries[index] = solution[index];
    _notes.remove(index);
    hintsUsed++;
    return index;
  }

  /// A hint-assisted or error-filled clear earns fewer stars.
  int starsForClear(int secondsLeft) {
    if (!completed) return 0;
    if (mistakes == 0 && hintsUsed == 0 && secondsLeft > 20) return 3;
    if (mistakes <= 2 && hintsUsed <= 1) return 2;
    return 1;
  }
}

class _SudokuMove {
  const _SudokuMove(this.index, this.oldValue);
  final int index;
  final int oldValue;
}
