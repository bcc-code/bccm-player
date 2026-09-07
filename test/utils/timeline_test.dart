import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/controls.dart';
import 'package:flutter/widgets.dart' hide RepeatMode;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_platform.dart';
import 'fixtures.dart';

void main() {
  late FakeBccmPlayerInterface fake;
  late BccmPlayerController controller;
  late PlayerStateNotifier notifier;

  setUp(() async {
    fake = FakeBccmPlayerInterface.install();
    controller = BccmPlayerController(mediaItem(id: 'a'));
    await controller.initialize();
    notifier = fake.stateNotifier.getPlayerNotifier(controller.value.playerId)!;
  });

  tearDown(() => fake.restore());

  /// Mounts [useTimeline] and returns a getter for the latest helper plus a
  /// build counter.
  Future<_Harness> pumpTimeline(WidgetTester tester) async {
    final harness = _Harness();
    await tester.pumpWidget(HookBuilder(builder: (context) {
      harness.builds++;
      harness.timeline = useTimeline(controller);
      return const SizedBox.shrink();
    }));
    return harness;
  }

  group('range resolution', () {
    testWidgets('VOD uses the media duration and starts at zero', (tester) async {
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        currentMediaItem: mediaItem(durationMs: 100000),
        playbackPositionMs: 50000,
      ));
      final harness = await pumpTimeline(tester);

      expect(harness.timeline.rangeStartMs, 0);
      expect(harness.timeline.rangeEndMs, 100000);
      expect(harness.timeline.timeFraction, 0.5);
    });

    testWidgets('the native seekable range wins over the media duration', (tester) async {
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        currentMediaItem: mediaItem(durationMs: 100000),
        playbackPositionMs: 50000,
        seekableRangeStartMs: 0,
        seekableRangeEndMs: 400000,
      ));
      final harness = await pumpTimeline(tester);

      expect(harness.timeline.rangeEndMs, 400000);
      expect(harness.timeline.timeFraction, 0.125);
    });

    testWidgets('a live DVR window is measured from its start, not from zero', (tester) async {
      // The whole point of the seekable range: for a DVR window running
      // 100s..200s, being at 150s is halfway along the bar, not three quarters.
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        playbackPositionMs: 150000,
        seekableRangeStartMs: 100000,
        seekableRangeEndMs: 200000,
      ));
      final harness = await pumpTimeline(tester);

      expect(harness.timeline.rangeStartMs, 100000);
      expect(harness.timeline.rangeEndMs, 200000);
      expect(harness.timeline.timeFraction, 0.5);
      expect(harness.timeline.duration, 200000, reason: 'duration aliases rangeEndMs');
    });

    testWidgets('falls back to the current position when nothing else is known', (tester) async {
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        playbackPositionMs: 7000,
      ));
      final harness = await pumpTimeline(tester);

      expect(harness.timeline.rangeEndMs, 7000);
      expect(harness.timeline.timeFraction, 1.0);
    });

    testWidgets('degrades to an empty range before anything has loaded', (tester) async {
      final harness = await pumpTimeline(tester);

      expect(harness.timeline.rangeStartMs, 0);
      expect(harness.timeline.actualTimeMs, 0);
      expect(harness.timeline.timeFraction, 0.0);
    });

    testWidgets('clamps a negative range start to zero', (tester) async {
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        playbackPositionMs: 500,
        seekableRangeStartMs: -5000,
        seekableRangeEndMs: 1000,
      ));
      final harness = await pumpTimeline(tester);

      expect(harness.timeline.rangeStartMs, 0);
      expect(harness.timeline.timeFraction, 0.5);
    });

    testWidgets('never lets the range end fall below its start', (tester) async {
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        playbackPositionMs: 5000,
        seekableRangeStartMs: 8000,
        seekableRangeEndMs: 2000,
      ));
      final harness = await pumpTimeline(tester);

      expect(harness.timeline.rangeEndMs, 8000);
      expect(harness.timeline.timeFraction, 0.0, reason: 'a zero-width range has no meaningful fraction');
    });

    testWidgets('clamps the fraction when the position sits outside the range', (tester) async {
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        playbackPositionMs: 500000,
        seekableRangeStartMs: 1000,
        seekableRangeEndMs: 2000,
      ));
      final harness = await pumpTimeline(tester);

      expect(harness.timeline.timeFraction, 1.0);
    });
  });

  group('positionFromFraction', () {
    testWidgets('is the exact inverse of timeFraction across a DVR window', (tester) async {
      // Regression: the seekbar multiplied the fraction by the range *end*,
      // ignoring the start. The thumb sat at 0.5 but dragging to 0.5 seeked to
      // 100s into a window that begins at 100s.
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        playbackPositionMs: 150000,
        seekableRangeStartMs: 100000,
        seekableRangeEndMs: 200000,
      ));
      final harness = await pumpTimeline(tester);
      final timeline = harness.timeline;

      expect(timeline.positionFromFraction(timeline.timeFraction), 150000);
      expect(timeline.positionFromFraction(0), 100000);
      expect(timeline.positionFromFraction(0.5), 150000);
      expect(timeline.positionFromFraction(1), 200000);
    });

    testWidgets('is a plain scale for VOD', (tester) async {
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        currentMediaItem: mediaItem(durationMs: 100000),
        playbackPositionMs: 0,
      ));
      final harness = await pumpTimeline(tester);

      expect(harness.timeline.positionFromFraction(0.25), 25000);
    });

    testWidgets('clamps fractions outside [0,1]', (tester) async {
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        currentMediaItem: mediaItem(durationMs: 100000),
        playbackPositionMs: 0,
      ));
      final harness = await pumpTimeline(tester);

      expect(harness.timeline.positionFromFraction(-1), 0);
      expect(harness.timeline.positionFromFraction(2), 100000);
    });
  });

  group('rebuild throttling', () {
    testWidgets('position changes within the same 500ms bucket do not rebuild', (tester) async {
      // Regression: `positionMs ?? 0 / 500` parsed as `positionMs ?? (0 / 500)`,
      // so the selector key was the raw position and the controls rebuilt on
      // every single millisecond reported by the player.
      final harness = await pumpTimeline(tester);
      final initialBuilds = harness.builds;

      notifier.setPlaybackPosition(100);
      await tester.pump();
      notifier.setPlaybackPosition(200);
      await tester.pump();

      expect(harness.builds, initialBuilds, reason: 'both positions round into bucket 0');
    });

    testWidgets('crossing a bucket boundary does rebuild', (tester) async {
      final harness = await pumpTimeline(tester);
      final initialBuilds = harness.builds;

      notifier.setPlaybackPosition(400);
      await tester.pump();

      expect(harness.builds, initialBuilds + 1);
    });

    testWidgets('a change of seekable range rebuilds', (tester) async {
      final harness = await pumpTimeline(tester);
      final initialBuilds = harness.builds;

      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        seekableRangeStartMs: 1000,
        seekableRangeEndMs: 9000,
      ));
      await tester.pump();

      expect(harness.builds, greaterThan(initialBuilds));
    });
  });

  group('scrubbing', () {
    testWidgets('scrubTo seeks and reports the scrub position while in flight', (tester) async {
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        currentMediaItem: mediaItem(durationMs: 100000),
        playbackPositionMs: 0,
      ));
      final harness = await pumpTimeline(tester);

      harness.timeline.scrubTo(60000);
      await tester.pump();

      expect(fake.seekToCalls.single.positionMs, 60000);
    });

    testWidgets('scrubTo ignores targets within 500ms of the last one mid-gesture', (tester) async {
      // The dead-zone exists because Slider.onChanged fires continuously during
      // a drag. It is measured against the previous scrub *target*, so it only
      // suppresses within one gesture — no pumping between these calls.
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        currentMediaItem: mediaItem(durationMs: 100000),
        playbackPositionMs: 0,
      ));
      final harness = await pumpTimeline(tester);

      harness.timeline.scrubTo(60000);
      harness.timeline.scrubTo(60200);
      harness.timeline.scrubTo(60400);
      await tester.pump();

      expect(fake.seekToCalls, hasLength(1), reason: 'the two nearby targets were swallowed');
      expect(fake.seekToCalls.single.positionMs, 60000);
    });

    testWidgets('the very first scrub near zero is swallowed by the dead-zone', (tester) async {
      // A consequence of comparing against the previous target rather than the
      // playhead: currentScrub starts at 0, so dragging to under 500ms does
      // nothing at all.
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        currentMediaItem: mediaItem(durationMs: 100000),
        playbackPositionMs: 30000,
      ));
      final harness = await pumpTimeline(tester);

      harness.timeline.scrubTo(400);
      await tester.pump();

      expect(fake.seekToCalls, isEmpty);
    });

    testWidgets('a completed seek clears the scrub state', (tester) async {
      // seekToScrubbed resets seeking/currentScrub in a post-frame callback once
      // the platform round-trip finishes, which is what hands display back to
      // the player's own reported position.
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        currentMediaItem: mediaItem(durationMs: 100000),
        playbackPositionMs: 0,
      ));
      final harness = await pumpTimeline(tester);

      harness.timeline.scrubTo(60000);
      await tester.pump();
      expect(harness.timeline.seeking, isTrue);

      await tester.pump();

      expect(harness.timeline.seeking, isFalse);
      expect(harness.timeline.currentScrub, 0);
    });

    testWidgets('scrubTo clamps into the seekable range', (tester) async {
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        playbackPositionMs: 150000,
        seekableRangeStartMs: 100000,
        seekableRangeEndMs: 200000,
      ));
      final harness = await pumpTimeline(tester);

      harness.timeline.scrubTo(999999);
      await tester.pump();
      expect(fake.seekToCalls.last.positionMs, 200000);

      harness.timeline.scrubTo(-999999);
      await tester.pump();
      expect(fake.seekToCalls.last.positionMs, 100000);
    });

    testWidgets('scrubToRelative offsets the actual position when not seeking', (tester) async {
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        currentMediaItem: mediaItem(durationMs: 100000),
        playbackPositionMs: 30000,
      ));
      final harness = await pumpTimeline(tester);

      harness.timeline.scrubToRelative(15000);
      await tester.pump();

      expect(fake.seekToCalls.single.positionMs, 45000);
    });

    testWidgets('scrubToRelative accumulates while a seek is still in flight', (tester) async {
      // Tapping +15s twice before the first seek lands has to reach +30s, which
      // is why the base is currentScrub rather than the playhead once seeking
      // has begun. No pump between the taps: after one completes the scrub state
      // is cleared and the base returns to the player's reported position.
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        currentMediaItem: mediaItem(durationMs: 100000),
        playbackPositionMs: 30000,
      ));
      final harness = await pumpTimeline(tester);

      harness.timeline.scrubToRelative(15000);
      harness.timeline.scrubToRelative(15000);
      await tester.pump();
      await tester.pump();

      expect(fake.seekToCalls.last.positionMs, 60000);
    });
  });
}

class _Harness {
  int builds = 0;
  late TimelineHelper timeline;
}
