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

/// A class which upon calling run() replaces the current pending action with a new one,
/// and executes the pending action when the current future is done.
/// It differes from a debouncer in that it doesnt use any timers.
class OneAsyncAtATime {
  Completer? _currentCompleter;
  Future Function()? _nextAction;

  OneAsyncAtATime();

  Future<void> runWhenCurrentIsDone(Future Function() action) async {
    _nextAction = action;
    if (_currentCompleter == null) {
      await _goNext();
    }
  }

  Future<void> _goNext() async {
    if (_nextAction == null) return;
    _currentCompleter = Completer();
    try {
      final action = _nextAction;
      _nextAction = null;
      await action!();
      _currentCompleter?.complete();
    } catch (e) {
      _currentCompleter?.completeError(e);
    }
    _currentCompleter = null;
    _goNext();
  }

  void reset() {
    _nextAction = null;
    _currentCompleter?.completeError('disposed');
    _currentCompleter = null;
  }

  bool get hasPending => _nextAction != null;
}
