/// Three short, independently unlockable stages per offline minigame.
class GameStages {
  static const int count = 3;

  static int clamp(int value) => value < 1 ? 1 : value > count ? count : value;

  static int mathRounds(int stage) => 3 + 2 * clamp(stage);
  static int xoRounds(int stage) => clamp(stage) + 1;

  /// Complete the stage rather than merely opening the game.
  static bool mathPassed({required int correct, required int total}) =>
      total > 0 && correct * 5 >= total * 3;
}
