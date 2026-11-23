import 'dart:math';

/// Offline arithmetic puzzles, scaled to the student's school stage.
class MathQuestion {
  const MathQuestion({
    required this.expression,
    required this.answer,
    required this.choices,
  });
  final String expression;
  final int answer;
  final List<int> choices;
}

class MathMatchGame {
  MathMatchGame({
    required this.level,
    this.schoolClass = '',
    this.totalRounds = 8,
    int seed = 2026,
  }) : assert(totalRounds > 0), _random = Random(seed) {
    _question = _generate();
  }

  final String level;
  final String schoolClass;
  final int totalRounds;
  final Random _random;
  late MathQuestion _question;
  int _roundIndex = 0;
  int _score = 0;
  int? _selected;

  int get round => _roundIndex + 1;
  int get score => _score;
  int? get selected => _selected;
  bool get answered => _selected != null;
  bool get correct => answered && _selected == _question.answer;
  bool get finished => _roundIndex == totalRounds - 1 && answered;
  MathQuestion get question => _question;

  bool choose(int value) {
    if (answered || !_question.choices.contains(value)) return false;
    _selected = value;
    if (correct) _score++;
    return true;
  }

  /// Advances only after an answer. The final round stays visible until reset.
  bool next() {
    if (!answered || finished) return false;
    _roundIndex++;
    _selected = null;
    _question = _generate();
    return true;
  }

  void reset() {
    _roundIndex = 0;
    _score = 0;
    _selected = null;
    _question = _generate();
  }

  int get _grade {
    final match = RegExp(r'\d+').firstMatch(schoolClass);
    return int.tryParse(match?.group(0) ?? '') ?? 1;
  }

  MathQuestion _generate() {
    final isPrimary = level == 'primary';
    final isYoung = isPrimary && _grade < 4;
    final max = isYoung ? 12 : isPrimary ? 30 : level == 'middle' ? 45 : 90;
    final operators = isYoung ? <String>['+', '−'] :
        isPrimary ? <String>['+', '−', '×'] :
        <String>['+', '−', '×', '÷'];
    final operator = operators[_random.nextInt(operators.length)];
    var left = _random.nextInt(max) + 1;
    var right = _random.nextInt(max) + 1;
    late int answer;
    switch (operator) {
      case '−':
        if (right > left) {
          final temp = left;
          left = right;
          right = temp;
        }
        answer = left - right;
      case '×':
        left = _random.nextInt(isPrimary ? 10 : 12) + 1;
        right = _random.nextInt(isPrimary ? 10 : 12) + 1;
        answer = left * right;
      case '÷':
        right = _random.nextInt(11) + 1;
        answer = _random.nextInt(12) + 1;
        left = right * answer;
      default:
        answer = left + right;
    }

    final options = <int>{answer};
    var delta = 1;
    while (options.length < 4) {
      // Non-negative distractors, even when subtraction answers zero.
      options.add(answer + delta);
      if (options.length < 4 && answer >= delta) {
        options.add(answer - delta);
      }
      delta++;
    }
    final shuffled = options.toList()..shuffle(_random);
    return MathQuestion(
      expression: '$left $operator $right = ?',
      answer: answer,
      choices: List<int>.unmodifiable(shuffled),
    );
  }
}
