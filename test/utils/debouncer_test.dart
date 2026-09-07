import 'dart:async';

import 'package:bccm_player/src/utils/debouncer.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer', () {
    test('collapses rapid calls into the last one', () {
      fakeAsync((async) {
        final calls = <int>[];
        final debouncer = Debouncer(milliseconds: 100);

        debouncer.run(() => calls.add(1));
        async.elapse(const Duration(milliseconds: 50));
        debouncer.run(() => calls.add(2));
        async.elapse(const Duration(milliseconds: 50));
        debouncer.run(() => calls.add(3));
        async.elapse(const Duration(milliseconds: 100));

        expect(calls, [3]);
      });
    });

    test('debounces the first call too, by default', () {
      // The doc comment above the class claims the default is false. It is not —
      // pinned here because the default is what every call site relies on.
      fakeAsync((async) {
        final calls = <int>[];
        final debouncer = Debouncer(milliseconds: 100);

        debouncer.run(() => calls.add(1));

        expect(calls, isEmpty, reason: 'default debounceInitial: true delays the first call');
        async.elapse(const Duration(milliseconds: 100));
        expect(calls, [1]);
      });
    });

    test('runs the first call immediately when debounceInitial is false', () {
      fakeAsync((async) {
        final calls = <int>[];
        final debouncer = Debouncer(milliseconds: 100, debounceInitial: false);

        debouncer.run(() => calls.add(1));
        expect(calls, [1]);

        // The leading call already fired, so the trailing timer must not repeat it.
        async.elapse(const Duration(milliseconds: 100));
        expect(calls, [1]);
      });
    });

    test('forceEarly runs the pending action now', () {
      fakeAsync((async) {
        final calls = <int>[];
        final debouncer = Debouncer(milliseconds: 1000);
        debouncer.run(() => calls.add(1));

        debouncer.forceEarly();

        expect(calls, [1]);
        async.elapse(const Duration(seconds: 2));
        expect(calls, [1], reason: 'the cancelled timer must not fire as well');
      });
    });
  });

  group('OneAsyncAtATime', () {
    test('runs a single action straight away', () async {
      final scheduler = OneAsyncAtATime();
      final calls = <int>[];

      await scheduler.runWhenCurrentIsDone(() async => calls.add(1));

      expect(calls, [1]);
      expect(scheduler.hasPending, isFalse);
    });

    test('keeps only the newest pending action while one is in flight', () async {
      // This is what makes scrubbing feel responsive: intermediate seek targets
      // are dropped rather than queued, so the player only chases the latest one.
      final scheduler = OneAsyncAtATime();
      final calls = <int>[];
      final gate = Completer<void>();

      final first = scheduler.runWhenCurrentIsDone(() async {
        calls.add(1);
        await gate.future;
      });

      scheduler.runWhenCurrentIsDone(() async => calls.add(2));
      scheduler.runWhenCurrentIsDone(() async => calls.add(3));
      expect(scheduler.hasPending, isTrue);
      expect(calls, [1], reason: 'nothing else runs until the first completes');

      gate.complete();
      await first;
      await Future.delayed(Duration.zero);

      expect(calls, [1, 3], reason: '2 was superseded by 3 before it ever ran');
      expect(scheduler.hasPending, isFalse);
    });

    test('a failing action is swallowed and does not block the next one', () async {
      // Regression: the error was pushed into a Completer nothing awaited, which
      // raised an unhandled async error. Callers fire these off unawaited, so a
      // throw must not escape.
      final scheduler = OneAsyncAtATime();
      final calls = <int>[];

      await expectLater(
        scheduler.runWhenCurrentIsDone(() async => throw Exception('boom')),
        completes,
      );
      await scheduler.runWhenCurrentIsDone(() async => calls.add(1));

      expect(calls, [1]);
    });

    test('reset drops the pending action', () async {
      final scheduler = OneAsyncAtATime();
      final calls = <int>[];
      final gate = Completer<void>();

      final first = scheduler.runWhenCurrentIsDone(() async {
        calls.add(1);
        await gate.future;
      });
      scheduler.runWhenCurrentIsDone(() async => calls.add(2));

      // Regression: reset() used to completeError('disposed') on that same
      // unawaited Completer. useTimeline calls reset() on dispose, so navigating
      // away mid-scrub raised it every time.
      scheduler.reset();
      expect(scheduler.hasPending, isFalse);

      gate.complete();
      await first;
      await Future.delayed(Duration.zero);

      expect(calls, [1], reason: 'the pending action was discarded by reset');
    });
  });
}
