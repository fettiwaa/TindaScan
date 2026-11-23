import 'dart:async';

/// Minimal behavior-subject for tests: new listeners immediately receive the
/// latest value, so emissions are not lost while providers (re)subscribe.
class ReplayStream<T> {
  final StreamController<T> _controller = StreamController<T>.broadcast();
  bool _hasValue = false;
  late T _latest;

  void add(T value) {
    _hasValue = true;
    _latest = value;
    _controller.add(value);
  }

  Stream<T> get stream => Stream<T>.multi((listener) {
    if (_hasValue) listener.add(_latest);
    final sub = _controller.stream.listen(
      listener.add,
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.onCancel = sub.cancel;
  });

  /// Emits an error to current listeners (not replayed).
  void addError(Object error) => _controller.addError(error);

  Future<void> close() => _controller.close();
}
