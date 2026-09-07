import 'package:flutter/foundation.dart';
import 'dart:async';

/// If two calls are made within [milliseconds], the first one will be cancelled.
/// If [debounceInitial] is true (default is false), the first call will also have a delay
class Debouncer {
  final int milliseconds;
  Timer? _timer;
  VoidCallback? _currentAction;
  bool debounceInitial;

  Debouncer({
    required this.milliseconds,
    this.debounceInitial = true,
  });

  run(VoidCallback action) {
    // If first call
    if (debounceInitial == false && _timer?.isActive != true) {
      action();
      _currentAction = () {};
    } else {
      _currentAction = action;
    }
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), _currentAction!);
  }

  forceEarly() {
    _timer?.cancel();
    _currentAction?.call();
  }
}

/// A class which upon calling [runWhenCurrentIsDone] replaces the current
/// pending action with a new one, and executes the pending action when the
/// current future is done.
///
/// It differs from a debouncer in that it doesn't use any timers. Used for
/// scrubbing: intermediate seek targets are dropped rather than queued, so the
/// player only ever chases the latest one.
class OneAsyncAtATime {
  bool _isRunning = false;
  Future Function()? _nextAction;

  OneAsyncAtATime();

  Future<void> runWhenCurrentIsDone(Future Function() action) async {
    _nextAction = action;
    if (!_isRunning) {
      await _goNext();
    }
  }

  Future<void> _goNext() async {
    if (_nextAction == null) return;
    _isRunning = true;
    try {
      final action = _nextAction;
      _nextAction = null;
      await action!();
    } catch (e, stack) {
      // Swallowed deliberately: callers fire this off without awaiting (see
      // `scrubTo`), so rethrowing surfaces as an unhandled async error, and a
      // failed seek must not stop the queued one from running.
      //
      // This used to be routed into a Completer that nothing ever awaited,
      // which raised an unhandled error regardless of the catch.
      debugPrint('bccm: queued action failed: $e\n$stack');
    } finally {
      _isRunning = false;
    }
    // Not awaited on purpose: awaiting would extend the await chain by a frame
    // per queued action, for as long as the user keeps scrubbing.
    _goNext();
  }

  /// Drops the pending action. An action already in flight runs to completion.
  void reset() {
    _nextAction = null;
  }

  bool get hasPending => _nextAction != null;
}
