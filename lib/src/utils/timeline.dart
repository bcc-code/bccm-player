import 'dart:math';

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/utils/debouncer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flutter/material.dart';

import 'package:bccm_player/src/utils/num.dart';

class TimelineHelper {
  final bool seeking;
  final double currentScrub;

  /// End of the seekable range — for VOD this is the media duration, for
  /// HLS / DASH live this is the current live edge. Equivalent to
  /// `rangeEndMs`; kept under the `duration` name for backward compat.
  final double duration;

  /// Start of the seekable range in milliseconds. `0` for VOD, the start
  /// of the DVR window for live streams (advances as the window slides).
  final double rangeStartMs;

  /// End of the seekable range in milliseconds — alias for [duration].
  final double rangeEndMs;

  final int actualTimeMs;

  /// The fraction of the seekable range that the player is "currently"
  /// at, where 0 is [rangeStartMs] and 1 is [rangeEndMs]. By "currently"
  /// meaning the actual time or the requested time if seeking.
  final double timeFraction;
  final Future Function() seekToScrubbed;
  final void Function(double targetMs) scrubTo;
  final void Function(double milliseconds) scrubToRelative;

  TimelineHelper({
    required this.seeking,
    required this.currentScrub,
    required this.duration,
    required this.rangeStartMs,
    required this.rangeEndMs,
    required this.timeFraction,
    required this.actualTimeMs,
    required this.seekToScrubbed,
    required this.scrubTo,
    required this.scrubToRelative,
  });
}

class _TimelineHook extends Hook<TimelineHelper> {
  const _TimelineHook({
    required this.playerController,
    required this.seeking,
    required this.currentScrub,
    required this.seekScheduler,
  });

  final BccmPlayerController playerController;
  final ValueNotifier<bool> seeking;
  final ValueNotifier<double> currentScrub;
  final OneAsyncAtATime seekScheduler;

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends HookState<TimelineHelper, _TimelineHook> {
  @override
  void initHook() {
    super.initHook();
  }

  @override
  TimelineHelper build(BuildContext context) {
    final actualTimeMs = safeInt(hook.playerController.value.playbackPositionMs ?? 0);

    // Prefer the seekable range reported by the native player (HLS DVR
    // window for live, [0, durationMs] for VOD). Falls back to the
    // media-item duration / current position so behavior is unchanged
    // when the native side hasn't populated the range yet.
    final controller = hook.playerController;
    final rawRangeStart = controller.seekableRangeStartMs?.toDouble();
    final rawRangeEnd = controller.seekableRangeEndMs?.toDouble()
        ?? controller.value.currentMediaItem?.metadata?.durationMs
        ?? controller.value.playbackPositionMs?.toDouble()
        ?? 1.0;
    final rangeStart = max(0.0, safeDouble(rawRangeStart ?? 0.0));
    final rangeEnd = max(rangeStart, safeDouble(rawRangeEnd));
    final span = rangeEnd - rangeStart;
    final timeFraction = !rangeEnd.isFinite || span <= 0
        ? 0.0
        : clampDouble(
            ((hook.seeking.value ? hook.currentScrub.value : actualTimeMs.toDouble()) - rangeStart) / span,
            0,
            1,
          );

    Future<void> seekToScrubbed() async {
      if (!context.mounted) return;
      final actualTargetMs = hook.currentScrub.value;
      await hook.playerController.seekTo(Duration(milliseconds: (actualTargetMs).round()));
      if (context.mounted && !hook.seekScheduler.hasPending) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (!context.mounted) return;
          hook.currentScrub.value = 0;
          hook.seeking.value = false;
        });
      }
    }

    void scrubTo(double targetMs) {
      if ((hook.currentScrub.value - targetMs).abs() < 500) {
        return;
      }
      hook.seeking.value = true;
      hook.currentScrub.value = clampDouble(targetMs, rangeStart, rangeEnd);
      hook.seekScheduler.runWhenCurrentIsDone(seekToScrubbed);
    }

    void scrubToRelative(double milliseconds) {
      final baseTime = hook.seeking.value ? hook.currentScrub.value : actualTimeMs;
      final double targetMs = baseTime + milliseconds;
      scrubTo(targetMs);
    }

    return TimelineHelper(
      duration: rangeEnd,
      rangeStartMs: rangeStart,
      rangeEndMs: rangeEnd,
      seeking: hook.seeking.value,
      currentScrub: hook.currentScrub.value,
      actualTimeMs: actualTimeMs,
      timeFraction: timeFraction,
      scrubTo: scrubTo,
      scrubToRelative: scrubToRelative,
      seekToScrubbed: seekToScrubbed,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

TimelineHelper useTimeline(BccmPlayerController playerController) {
  final seeking = useState(false);
  final currentScrub = useState(0.0);
  final seekScheduler = useMemoized(() => OneAsyncAtATime());

  // Dispose
  useEffect(() => () => seekScheduler.reset(), []);

  useListenableSelector(
    playerController,
    () => [
      (playerController.value.playbackPositionMs ?? 0 / 500).round(),
      playerController.value.currentMediaItem?.metadata?.durationMs,
      playerController.seekableRangeStartMs,
      playerController.seekableRangeEndMs,
    ].toString(),
  );

  return use(_TimelineHook(
    playerController: playerController,
    seeking: seeking,
    currentScrub: currentScrub,
    seekScheduler: seekScheduler,
  ));
}
