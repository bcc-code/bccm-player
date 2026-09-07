import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fake_platform.dart';
import '../utils/fixtures.dart';

void main() {
  late FakeBccmPlayerInterface fake;
  late BccmPlayerController controller;
  late PlayerStateNotifier notifier;

  // Built outside the testWidgets body so the notifier's periodic timer does
  // not land in the test's fake-async zone.
  setUp(() async {
    fake = FakeBccmPlayerInterface.install();
    controller = BccmPlayerController(mediaItem(id: 'a'));
    await controller.initialize();
    notifier = fake.stateNotifier.getPlayerNotifier(controller.value.playerId)!;
  });

  tearDown(() => fake.restore());

  /// Mounts the widget and records every (progress, duration) it builds with.
  Future<List<Duration>> pumpProgress(WidgetTester tester) async {
    final progresses = <Duration>[];
    await tester.pumpWidget(MaterialApp(
      home: SmoothVideoProgress(
        controller: controller,
        builder: (context, progress, duration, child) {
          progresses.add(progress);
          return const SizedBox.shrink();
        },
      ),
    ));
    return progresses;
  }

  void setState({
    required PlaybackState playbackState,
    double? durationMs,
    double? positionMs,
  }) {
    notifier.setStateFromSnapshot(snapshot(
      playerId: controller.value.playerId,
      playbackState: playbackState,
      currentMediaItem: durationMs == null ? null : mediaItem(durationMs: durationMs),
      playbackPositionMs: positionMs,
    ));
  }

  testWidgets('reports the position it was given while paused', (tester) async {
    setState(playbackState: PlaybackState.paused, durationMs: 100000, positionMs: 25000);

    final progresses = await pumpProgress(tester);

    expect(progresses.last, const Duration(milliseconds: 25000));
  });

  testWidgets('interpolates forward between position updates while playing', (tester) async {
    setState(playbackState: PlaybackState.playing, durationMs: 100000, positionMs: 10000);
    final progresses = await pumpProgress(tester);

    // Nudge the position so the widget starts animating from it, then let time
    // pass without any further update from the player.
    setState(playbackState: PlaybackState.playing, durationMs: 100000, positionMs: 11000);
    await tester.pump();
    final atStart = progresses.last;

    await tester.pump(const Duration(seconds: 2));

    expect(progresses.last, greaterThan(atStart),
        reason: 'progress advances on its own between player updates');
  });

  testWidgets('stops advancing once paused', (tester) async {
    setState(playbackState: PlaybackState.playing, durationMs: 100000, positionMs: 10000);
    final progresses = await pumpProgress(tester);
    setState(playbackState: PlaybackState.playing, durationMs: 100000, positionMs: 11000);
    await tester.pump();

    setState(playbackState: PlaybackState.paused, durationMs: 100000, positionMs: 11000);
    await tester.pump();
    final atPause = progresses.last;

    await tester.pump(const Duration(seconds: 2));

    expect(progresses.last, atPause);
  });

  testWidgets('a zero duration does not produce a NaN progress', (tester) async {
    // targetRelativePosition divides by duration, so this is the guard that
    // keeps NaN out of the animation controller.
    setState(playbackState: PlaybackState.playing, positionMs: 0);

    final progresses = await pumpProgress(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(progresses, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('survives a position update arriving before the duration is known', (tester) async {
    // The normal startup order: the player reports a position while
    // metadata.durationMs is still null, so position/duration is Infinity and
    // reaches AnimationController.forward(from:).
    setState(playbackState: PlaybackState.playing, positionMs: 0);
    await pumpProgress(tester);

    setState(playbackState: PlaybackState.playing, positionMs: 1000);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('retains the last non-zero progress rather than snapping to zero', (tester) async {
    // Between a media-item change and the first position report the animation
    // reads zero; showing that would make the bar jump backwards.
    setState(playbackState: PlaybackState.paused, durationMs: 100000, positionMs: 40000);
    final progresses = await pumpProgress(tester);
    expect(progresses.last, const Duration(milliseconds: 40000));

    setState(playbackState: PlaybackState.paused, durationMs: 100000, positionMs: 0);
    await tester.pump();

    expect(progresses.last, const Duration(milliseconds: 40000),
        reason: 'a zero progress is replaced by the last non-zero one');
  });

  testWidgets('passes the child through to the builder', (tester) async {
    setState(playbackState: PlaybackState.paused, durationMs: 100000, positionMs: 0);
    await tester.pumpWidget(MaterialApp(
      home: SmoothVideoProgress(
        controller: controller,
        child: const Text('child'),
        builder: (context, progress, duration, child) => child!,
      ),
    ));

    expect(find.text('child'), findsOneWidget);
  });

  testWidgets('reports the media duration alongside the progress', (tester) async {
    setState(playbackState: PlaybackState.paused, durationMs: 100000, positionMs: 0);
    final durations = <Duration>[];
    await tester.pumpWidget(MaterialApp(
      home: SmoothVideoProgress(
        controller: controller,
        builder: (context, progress, duration, child) {
          durations.add(duration);
          return const SizedBox.shrink();
        },
      ),
    ));

    expect(durations.last, const Duration(milliseconds: 100000));
  });
}
