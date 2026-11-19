/// Move one PDF page to a user-selected zero-based position without copying
/// or losing the original ScanPage reference and its edit state.
void moveToPosition<T>(List<T> pages, int from, int to) {
  if (from < 0 || from >= pages.length || to < 0 || to >= pages.length) {
    throw RangeError('Page position is out of range');
  }
  if (from == to) return;
  pages.insert(to, pages.removeAt(from));
}
