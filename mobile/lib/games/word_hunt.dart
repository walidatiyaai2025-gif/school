import 'dart:math';

import 'game_stages.dart';

/// Eight-direction word search: horizontal, vertical, both diagonals,
/// including backwards at higher levels. First and last tile select a path.
/// Every target has an explicit guaranteed placement, never an accidental
/// substring hidden by the filler characters.
enum WordOrientation { horizontal, vertical, diagonal }

class WordHuntGame {
  WordHuntGame({required this.level, this.stage = 1, int seed = 2026})
      : _random = Random(seed) {
    reset();
  }

  final String level;
  final int stage;
  final Random _random;
  static const int size = 7;

  // (row increment, column increment)
  static const List<(int, int)> _directions = [
    (0, 1), (1, 0), (1, 1), (1, -1),
    (0, -1), (-1, 0), (-1, -1), (-1, 1),
  ];

  late List<String> _letters;
  late List<String> _targets;
  final Map<String, List<int>> _placements = {};
  final Set<String> _found = <String>{};
  final Set<int> _foundCells = <int>{};
  List<int> _lastFoundCells = const [];
  int? _start;
  String? _lastFound;
  WordOrientation? _lastOrientation;
  bool _lastMiss = false;
  int _combo = 0;
  int _bestCombo = 0;
  int _score = 0;
  int _misses = 0;

  List<String> get letters => List.unmodifiable(_letters);
  List<String> get targets => List.unmodifiable(_targets);
  Set<String> get found => Set.unmodifiable(_found);
  Set<int> get foundCells => Set.unmodifiable(_foundCells);
  List<int> get lastFoundCells => List.unmodifiable(_lastFoundCells);
  int? get start => _start;
  String? get lastFound => _lastFound;
  WordOrientation? get lastOrientation => _lastOrientation;
  bool get lastMiss => _lastMiss;
  bool get finished => _found.length == _targets.length;
  int get progress => _found.length;
  int get combo => _combo;
  int get bestCombo => _bestCombo;
  int get score => _score;
  int get misses => _misses;

  /// Read-only verification of a generated solution; never displayed in UI.
  List<int> wordPath(String word) =>
      List<int>.unmodifiable(_placements[word] ?? const <int>[]);

  WordOrientation orientationOf(String word) {
    final path = _placements[word];
    if (path == null || path.length < 2) {
      throw ArgumentError.value(word, 'word', 'Unknown word');
    }
    final delta = path[1] - path[0];
    if (delta == 1 || delta == -1) return WordOrientation.horizontal;
    if (delta == size || delta == -size) return WordOrientation.vertical;
    return WordOrientation.diagonal;
  }

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


  /// Single hint highlights only the start of a remaining target.
  int? get hintCell {
    for (final word in _targets) {
      if (!_found.contains(word)) return _placements[word]?.first;
    }
    return null;
  }

  void reset() {
    _targets = wordsFor(level, stage: stage);
    _found.clear();
    _foundCells.clear();
    _lastFoundCells = const [];
    _start = null;
    _lastFound = null;
    _lastOrientation = null;
    _lastMiss = false;
    _combo = 0;
    _bestCombo = 0;
    _score = 0;
    _misses = 0;
    _generatePuzzle();
  }

  /// Word placement tries preferred directions first, with a bounded retry
  /// budget and fallback directions. Every committed path must be valid.
  void _generatePuzzle() {
    for (var attempt = 0; attempt < 32; attempt++) {
      final board = List<String?>.filled(size * size, null);
      _placements.clear();
      var success = true;
      for (var w = 0; w < _targets.length; w++) {
        final word = _targets[w];
        // Levels 1–3 already mix horizontal/vertical/diagonal. Subsequent
        // stages introduce the other diagonal and reverse words gradually.
        final preferred = stage <= 3 ? w % 3 :
            ((GameStages.clamp(stage) - 4) ~/ 14 + w) % 8;
        final choices = <int>[
          preferred,
          for (var d = 0; d < 8; d++)
            if (d != preferred && (stage > 15 || d < 4)) d,
        ];
        // Keep early learning levels approachable; advanced puzzles use
        // all eight possible directions, including backwards.
        final candidates = <({List<int> cells, int crossings})>[];
        var placed = false;
        for (final directionIndex in choices) {
          candidates.clear();
          final (dr, dc) = _directions[directionIndex];
          for (var row = 0; row < size; row++) {
            for (var col = 0; col < size; col++) {
              final cells = <int>[];
              var crossings = 0;
              var fits = true;
              for (var k = 0; k < word.length; k++) {
                final r = row + dr * k;
                final c = col + dc * k;
                if (r < 0 || r >= size || c < 0 || c >= size) {
                  fits = false;
                  break;
                }
                final idx = r * size + c;
                final previous = board[idx];
                if (previous != null && previous != word[k]) {
                  fits = false;
                  break;
                }
                if (previous != null) crossings++;
                cells.add(idx);
              }
              if (fits) candidates.add((cells: cells, crossings: crossings));
            }
          }
          if (candidates.isEmpty) continue;
          // Crossings add challenge at advanced stages without making a
          // puzzle unsolvable. Random choices vary with seed/stage.
          if (stage > 30 && _random.nextBool()) {
            candidates.sort((a, b) => b.crossings.compareTo(a.crossings));
          } else {
            candidates.shuffle(_random);
          }
          final selected = candidates.first.cells;
          for (var k = 0; k < selected.length; k++) {
            board[selected[k]] = word[k];
          }
          _placements[word] = List<int>.unmodifiable(selected);
          placed = true;
          break;
        }
        if (!placed) {
          success = false;
          break;
        }
      }
      if (!success) continue;
      _letters = List<String>.generate(size * size, (index) =>
          board[index] ?? String.fromCharCode(65 + _random.nextInt(26)));
      return;
    }
    // Never silently display a stage containing an unfindable word.
    throw StateError('Unable to generate Word Hunt stage $stage');
  }

  /// Return the complete straight path connecting two cells. Supports
  /// horizontal, vertical and both diagonals in either direction.
  static List<int> straightPath(int first, int last) {
    if (first < 0 || last < 0 || first >= size * size ||
        last >= size * size || first == last) return const [];
    final r1 = first ~/ size;
    final c1 = first % size;
    final r2 = last ~/ size;
    final c2 = last % size;
    final dr = r2 - r1;
    final dc = c2 - c1;
    if (dr != 0 && dc != 0 && dr.abs() != dc.abs()) return const [];
    final stepR = dr.sign;
    final stepC = dc.sign;
    final steps = max(dr.abs(), dc.abs());
    return List<int>.generate(steps + 1,
        (k) => (r1 + stepR * k) * size + c1 + stepC * k);
  }

  /// A second tap finishes a selection. Incorrect paths reset the combo
  /// without losing previously found words. Backwards endpoints are valid.
  bool tap(int index) {
    if (finished || index < 0 || index >= size * size) return false;
    _lastFound = null;
    _lastFoundCells = const [];
    _lastOrientation = null;
    _lastMiss = false;
    if (_start == null) {
      _start = index;
      return true;
    }
    final first = _start!;
    _start = null;
    final selected = straightPath(first, index);
    String? matched;
    if (selected.isNotEmpty) {
      for (final word in _targets) {
        if (_found.contains(word)) continue;
        final path = _placements[word]!;
        final forward = _samePath(path, selected);
        final reverse = _samePath(path.reversed.toList(), selected);
        if (forward || reverse) {
          matched = word;
          break;
        }
      }
    }
    if (matched == null) {
      _lastMiss = true;
      _misses++;
      _combo = 0;
      _score = max(0, _score - 10);
      return true;
    }
    _found.add(matched);
    _lastFound = matched;
    _lastFoundCells = _placements[matched]!;
    _lastOrientation = orientationOf(matched);
    _foundCells.addAll(_lastFoundCells);
    _combo++;
    _bestCombo = max(_bestCombo, _combo);
    final directionBonus = switch (_lastOrientation!) {
      WordOrientation.horizontal => 0,
      WordOrientation.vertical => 20,
      WordOrientation.diagonal => 35,
    };
    _score += 100 + 25 * (_combo - 1) + directionBonus;
    return true;
  }

  static bool _samePath(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
