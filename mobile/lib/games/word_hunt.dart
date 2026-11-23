import 'dart:math';

/// An offline word search: tap the first and last letter in the same row.
/// Puzzles are deliberately short for touch screens and younger students.
class WordHuntGame {
  WordHuntGame({required this.level, int seed = 2026})
      : _random = Random(seed) {
    reset();
  }

  final String level;
  final Random _random;
  static const int size = 7;

  late List<String> _letters;
  late List<String> _targets;
  final Set<String> _found = <String>{};
  final Set<int> _foundCells = <int>{};
  int? _start;
  String? _lastFound;
  bool _lastMiss = false;

  List<String> get letters => List.unmodifiable(_letters);
  List<String> get targets => List.unmodifiable(_targets);
  Set<String> get found => Set.unmodifiable(_found);
  Set<int> get foundCells => Set.unmodifiable(_foundCells);
  int? get start => _start;
  String? get lastFound => _lastFound;
  bool get lastMiss => _lastMiss;
  bool get finished => _found.length == _targets.length;
  int get progress => _found.length;

  static List<String> wordsFor(String level) {
    switch (level) {
      case 'middle': return const ['PLANET', 'WATER', 'ATOM'];
      case 'secondary': return const ['ENERGY', 'ORBIT', 'CELL'];
      case 'university': return const ['VECTOR', 'MATRIX', 'LOGIC'];
      default: return const ['CAT', 'DOG', 'SUN'];
    }
  }

  void reset() {
    _targets = wordsFor(level);
    _letters = List.generate(size * size,
        (_) => String.fromCharCode(65 + _random.nextInt(26)));
    _found.clear();
    _foundCells.clear();
    _start = null;
    _lastFound = null;
    _lastMiss = false;
    for (var w = 0; w < _targets.length; w++) {
      final row = w * 2;
      final word = _targets[w];
      final offset = _random.nextInt(size - word.length + 1);
      for (var c = 0; c < word.length; c++) {
        _letters[row * size + offset + c] = word[c];
      }
    }
  }

  /// The second tap completes one straight horizontal word selection.
  /// Wrong guesses never remove correctly found words.
  bool tap(int index) {
    if (finished || index < 0 || index >= _letters.length) return false;
    _lastFound = null;
    _lastMiss = false;
    if (_start == null) {
      _start = index;
      return true;
    }
    final first = _start!;
    _start = null;
    if (first ~/ size != index ~/ size) {
      _lastMiss = true;
      return true;
    }
    final a = min(first, index);
    final b = max(first, index);
    final selected = _letters.sublist(a, b + 1).join();
    final reversed = selected.split('').reversed.join();
    final match = _targets.where((w) =>
        !_found.contains(w) && (w == selected || w == reversed)).firstOrNull;
    if (match == null) {
      _lastMiss = true;
    } else {
      _found.add(match);
      _lastFound = match;
      for (var i = a; i <= b; i++) {
        _foundCells.add(i);
      }
    }
    return true;
  }
}
