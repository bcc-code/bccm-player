/*
Modification of
https://github.com/timcreatedit/smooth_video_progress/blob/efe86cdd873869cd1a5714b2849b2bc7c3379ed3/lib/smooth_video_progress.dart
by Tim Lehmann.

MIT License

Copyright (c) 2022 Tim Lehmann

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A widget that provides a method of building widgets using an interpolated
/// position value for [BccmPlayerController].
class SmoothVideoProgress extends HookWidget {
  const SmoothVideoProgress({
    Key? key,
    required this.controller,
    required this.builder,
    this.child,
  }) : super(key: key);

  /// The [VideoPlayerController] to build a progress widget for.
  final BccmPlayerController controller;

  /// The builder function.
  ///
  /// [progress] holds the interpolated current progress of the video. Use
  /// [duration] (the total duration of the video) to calculate a relative value
  /// for a slider for example for convenience.
  /// [child] holds the widget you passed into the constructor of this widget.
  /// Use that to optimize rebuilds.
  final Widget Function(BuildContext context, Duration progress, Duration duration, Widget? child) builder;

  /// An optional child that will be passed to the [builder] function and helps
  /// you optimize rebuilds.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final value = useValueListenable(controller);
    final position = Duration(milliseconds: value.playbackPositionMs ?? 0);
    final duration = Duration(milliseconds: (value.currentMediaItem?.metadata?.durationMs ?? 0).round());

    final animationController = useAnimationController(duration: duration, keys: [duration]);

    final targetRelativePosition = position.inMilliseconds / duration.inMilliseconds;

    final currentPosition = Duration(milliseconds: (animationController.value * duration.inMilliseconds).round());

    final offset = position - currentPosition;

    useValueChanged(
      position,
      (_, __) {
        final correct = value.playbackState == PlaybackState.playing && offset.inMilliseconds > -500 && offset.inMilliseconds < -50;
        final correction = const Duration(milliseconds: 500) - offset;
        final targetPos = correct ? animationController.value : targetRelativePosition;
        final correctedDuration = correct ? duration + correction : duration;

        animationController.duration = correctedDuration;
        value.playbackState == PlaybackState.playing
            ? animationController.forward(from: targetPos)
            : animationController.value = targetRelativePosition;
        return true;
      },
    );

    useValueChanged(
      value.playbackState == PlaybackState.playing,
      (_, __) =>
          value.playbackState == PlaybackState.playing ? animationController.forward(from: targetRelativePosition) : animationController.stop(),
    );

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final millis = animationController.value * duration.inMilliseconds;
        return builder(
          context,
          Duration(milliseconds: millis.round()),
          duration,
          child,
        );
      },
      child: child,
    );
  }
}
