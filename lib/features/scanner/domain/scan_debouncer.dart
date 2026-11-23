/// Drops repeated reads of the same barcode within [window].
///
/// Cameras report the same code many times per second while it stays in
/// view; without this, one scan would add several items to the cart. A
/// *different* code is accepted immediately, and the same code is accepted
/// again after [window] (continuous scan mode: each deliberate scan adds 1).
class ScanDebouncer {
  ScanDebouncer(this.window);

  final Duration window;
  String? _lastCode;
  DateTime? _lastAt;

  /// Returns true if [code] seen at [now] should be handled.
  bool accept(String code, DateTime now) {
    final lastAt = _lastAt;
    if (code == _lastCode &&
        lastAt != null &&
        now.difference(lastAt) < window) {
      return false;
    }
    _lastCode = code;
    _lastAt = now;
    return true;
  }

  void reset() {
    _lastCode = null;
    _lastAt = null;
  }
}
