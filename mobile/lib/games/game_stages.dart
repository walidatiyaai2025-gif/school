/// Procedurally generated, offline, progressively harder stages.
/// Only unlocked/selected stage numbers are persisted; no 1000-item list.
class GameStages {
  static const int count = 1000;
  static int clamp(int value) => value.clamp(1, count).toInt();

  /// Three earlier stages preserve their historical puzzle counts.
  /// Later stages gain variety but stay short enough for mobile play.
  static int mathRounds(int stage) => stage <= 3
      ? 3 + 2 * clamp(stage)
      : (6 + ((clamp(stage) - 1) ~/ 40)).clamp(6, 12).toInt();
  static int xoRounds(int stage) => stage <= 3
      ? clamp(stage) + 1 : (2 + clamp(stage) ~/ 75).clamp(2, 5).toInt();

  /// Generate real difficulty bands across all 1000 levels.
  static int difficultyBand(int stage) =>
      (1 + (clamp(stage) - 1) ~/ 25).clamp(1, 40).toInt();

  /// Time is always finite, even at stage 1000. Advanced stages are faster.
  static int secondsFor(String game, int stage) {
    final band = difficultyBand(stage);
    switch (game) {
      case 'xo': return (68 - band * 2).clamp(25, 66).toInt();
      case 'math': return (125 - band * 2).clamp(50, 123).toInt();
      case 'sudoku': return (680 - band * 8).clamp(330, 680).toInt();
      default: return (150 - band * 3).clamp(45, 147).toInt();
    }
  }

  static bool mathPassed({required int correct, required int total}) =>
      total > 0 && correct * 5 >= total * 3;
}
