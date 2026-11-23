/// Game completions, not taps, turns, or app openings.
class XoAdFrequency {
  static const int roundsPerBreak = 6;

  static int recordCompleted(int previous) {
    if (previous >= roundsPerBreak) return roundsPerBreak;
    return previous < 0 ? 1 : previous + 1;
  }

  static bool isBreakDue(int completed) => completed >= roundsPerBreak;
}
