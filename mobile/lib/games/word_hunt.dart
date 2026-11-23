import 'dart:math';

import 'game_stages.dart';

/// An offline word search: tap the first and last letter in the same row.
/// Puzzles are deliberately short for touch screens and younger students.
class WordHuntGame {
  WordHuntGame({required this.level, this.stage = 1, int seed = 2026})
      : _random = Random(seed) {
    reset();
  }

  final String level;
  final int stage;
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

  static List<String> wordsFor(String level, {int stage = 1}) {
    // Keep the first 3 existing puzzles. From level 4 onward produce
    // deterministic, varied puzzles across 1000 levels, without downloads.
    final n = GameStages.clamp(stage);
    if (n <= 3) {
      final index = n - 1;
      switch (level) {
        case 'middle':
          return const [
            ['PLANET', 'WATER', 'ATOM'],
            ['GRAVITY', 'OXYGEN', 'TISSUE'],
            ['CLIMATE', 'MAGNET', 'PROTON'],
          ][index];
        case 'secondary':
          return const [
            ['ENERGY', 'ORBIT', 'CELL'],
            ['PHOTON', 'CARBON', 'GENOME'],
            ['ISOTOPE', 'NUCLEUS', 'NEUTRON'],
          ][index];
        case 'university':
          return const [
            ['VECTOR', 'MATRIX', 'LOGIC'],
            ['BINARY', 'SCALAR', 'KERNEL'],
            ['NETWORK', 'QUANTUM', 'ALGEBRA'],
          ][index];
        default:
          return const [
            ['CAT', 'DOG', 'SUN'],
            ['TREE', 'BOOK', 'MOON'],
            ['PLANET', 'FLOWER', 'SCHOOL'],
          ][index];
      }
    }
    final pool = switch (level) {
      'middle' => const ['PLANET','ENERGY','WATER','OXYGEN','ATOM','MAGNET','PROTON',
        'FORCE','MOTION','TISSUE','GRAVITY','LIGHT','CLIMATE','CELLS','ORBIT','SOLAR'],
      'secondary' => const ['PHOTON','CARBON','GENOME','ENERGY','ATOMIC','NEUTRON',
        'PROTON','MATRIX','NUCLEUS','ISOTOPE','VECTOR','PLASMA','ORBIT','MOTION','OPTICS'],
      'university' => const ['VECTOR','MATRIX','LOGIC','BINARY','SCALAR','KERNEL',
        'NETWORK','ALGEBRA','QUANTUM','ATOMIC','TENSOR','LINEAR','CRYPTO','SYNTAX'],
      _ => const ['CAT','DOG','SUN','TREE','BOOK','MOON','SCHOOL','FLOWER',
        'PLANET','WATER','APPLE','TRAIN','CLOUD','PENCIL','STAR','LIGHT','FRIEND'],
    };
    final count = n < 12 ? 3 : n < 80 ? 4 : 5;
    final band = GameStages.difficultyBand(n);
    final sorted = pool.toList()..sort((a,b) => band.isEven
        ? b.length.compareTo(a.length) : a.length.compareTo(b.length));
    final offset = (n * 7 + band) % sorted.length;
    final picked = <String>{};
    for (var i = 0; picked.length < count; i++) {
      picked.add(sorted[(offset + i * 3) % sorted.length]);
    }
    return picked.toList(growable: false);
  }

  /// A single hint per level: show the first letter of the next hidden word.
  /// The screen controls persistence and never deducts an unlocked level.
  int? get hintCell {
    final remaining = _targets.where((word) => !_found.contains(word));
    if (remaining.isEmpty) return null;
    final word = remaining.first;
    final row = _targets.indexOf(word);
    final actualRow = stage <= 3 ? row * 2 : row;
    final letters = _letters.sublist(actualRow * size,
      actualRow * size + size).join();
    final column = letters.indexOf(word);
    return column < 0 ? null : actualRow * size + column;
  }

  void reset() {
    _targets = wordsFor(level, stage: stage);
    _letters = List.generate(size * size,
        (_) => String.fromCharCode(65 + _random.nextInt(26)));
    _found.clear();
    _foundCells.clear();
    _start = null;
    _lastFound = null;
    _lastMiss = false;
    for (var w = 0; w < _targets.length; w++) {
      final row = stage <= 3 ? w * 2 : w;
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
