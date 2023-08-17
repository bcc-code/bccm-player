// ignore_for_file: invalid_use_of_protected_member

import 'dart:math';

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/utils/debouncer.dart';
import 'package:bccm_player/src/widgets/controls/controls_wrapper.dart';
import 'package:bccm_player/src/widgets/mini_player/loading_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/svg_icons.dart';
import '../../utils/time.dart';
import 'control_fade_out.dart';
import 'default/settings.dart';
import 'default/time_skip_button.dart';

double _safeDouble(double input) => input.isNaN || !input.isFinite ? 0 : input.toDouble();
int _safeInt(int input) => input.isNaN || !input.isFinite ? 0 : input;

class DefaultControls extends HookWidget {
  const DefaultControls({
    super.key,
  });

  static ControlsBuilder builder = (BuildContext context) {
    return const DefaultControls();
  };

  @override
  Widget build(BuildContext context) {
    final controlsTheme = BccmPlayerTheme.safeOf(context).controls!;
    final viewController = BccmPlayerViewController.of(context);
    final player = useListenable(viewController.playerController);
    final actualTimeMs = _safeInt(player.value.playbackPositionMs ?? 0);
    final duration = max(0.0, _safeDouble(player.value.currentMediaItem?.metadata?.durationMs ?? player.value.playbackPositionMs?.toDouble() ?? 1.0));
    final forwardRewindDurationSec = Duration(milliseconds: duration.toInt()).inMinutes > 60 ? 30 : 15;
    final seeking = useState(false);
    final currentScrub = useState(0.0);
    final seekScheduler = useMemoized(() => OneAsyncAtATime());

    // Dispose
    useEffect(() => () => seekScheduler.reset(), []);

    Future<void> seekToScrubbed() async {
      if (!context.mounted) return;
      final actualTargetMs = currentScrub.value;
      await viewController.playerController.seekTo(Duration(milliseconds: (actualTargetMs).round()));
      if (context.mounted && !seekScheduler.hasPending) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (!context.mounted) return;
          currentScrub.value = 0;
          seeking.value = false;
        });
      }
    }

    void scrubTo(double targetMs) {
      if ((currentScrub.value - targetMs).abs() < 500) {
        return;
      }
      seeking.value = true;
      currentScrub.value = clampDouble(targetMs, 0, duration);
      seekScheduler.runWhenCurrentIsDone(seekToScrubbed);
    }

    void scrubToRelative(double milliseconds) {
      final baseTime = seeking.value ? currentScrub.value : actualTimeMs;
      final double targetMs = baseTime + milliseconds;
      scrubTo(targetMs);
    }

    final title = player.value.currentMediaItem?.metadata?.title;

    return SizedBox.expand(
      child: ControlsWrapper(
        autoHide: player.value.playbackState == PlaybackState.playing,
        builder: (context) => SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: ControlFadeOut(
                  child: Container(
                    alignment: Alignment.topLeft,
                    width: double.infinity,
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (viewController.isFullscreen) ...[
                          IconButton(
                            icon: const Icon(Icons.close),
                            iconSize: 32,
                            color: controlsTheme.iconColor,
                            padding: const EdgeInsets.all(12).copyWith(left: 6),
                            onPressed: () {
                              Navigator.maybePop(context);
                            },
                          ),
                          if (title != null)
                            Text(
                              title,
                              style: controlsTheme.fullscreenTitleStyle,
                            ),
                        ],
                        const Spacer(),
                        SettingsButton(
                          viewController: viewController,
                          padding: const EdgeInsets.only(top: 12, bottom: 24, left: 24, right: 10),
                          controlsTheme: controlsTheme,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ControlFadeOut(
                child: Container(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: TimeSkipButton(
                          forwardRewindDurationSec: forwardRewindDurationSec,
                          onPressed: () => scrubToRelative(-forwardRewindDurationSec * 1000),
                          icon: const Icon(Icons.replay),
                        ),
                      ),
                      if (player.value.playbackState != PlaybackState.playing)
                        IconButton(
                          constraints: const BoxConstraints.tightFor(width: 68, height: 68),
                          icon: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: SvgPicture.string(
                              SvgIcons.play,
                              width: double.infinity,
                              height: double.infinity,
                              colorFilter: ColorFilter.mode(controlsTheme.iconColor ?? Colors.white, BlendMode.srcIn),
                            ),
                          ),
                          color: controlsTheme.iconColor,
                          onPressed: () {
                            viewController.playerController.play();
                          },
                        )
                      else
                        IconButton(
                          constraints: const BoxConstraints.tightFor(width: 68, height: 68),
                          icon: player.value.isBuffering == true
                              ? LoadingIndicator(
                                  width: 42,
                                  height: 42,
                                  color: controlsTheme.iconColor,
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: SvgPicture.string(
                                    SvgIcons.pause,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                          iconSize: 42,
                          color: controlsTheme.iconColor,
                          onPressed: () {
                            player.pause();
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: TimeSkipButton(
                          forwardRewindDurationSec: forwardRewindDurationSec,
                          onPressed: () => scrubToRelative(forwardRewindDurationSec * 1000),
                          icon: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(pi),
                            child: const Icon(Icons.replay),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (viewController.config.controlsConfig.playNextButton != null && viewController.isFullscreen)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 8, right: 12),
                                child: viewController.config.controlsConfig.playNextButton!(context)),
                        ],
                      ),
                    ),
                    ControlFadeOut(
                      blockBackgroundClicks: true,
                      child: SizedBox(
                        height: 42,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (player.value.currentMediaItem?.isLive != true)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8, left: 13),
                                child: Text(
                                  '${getFormattedDuration(seeking.value ? currentScrub.value : actualTimeMs)} / ${getFormattedDuration(duration)}',
                                  style: controlsTheme.durationTextStyle,
                                ),
                              ),
                            const Spacer(),
                            ...?viewController.config.controlsConfig.additionalActionsBuilder?.call(context),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (!viewController.isFullscreen) {
                                  viewController.enterFullscreen();
                                } else {
                                  viewController.exitFullscreen();
                                }
                              },
                              child: Container(
                                height: double.infinity,
                                alignment: Alignment.bottomRight,
                                padding: EdgeInsets.only(
                                    right: 10,
                                    top: 8,
                                    bottom: 5,
                                    left: viewController.config.controlsConfig.additionalActionsBuilder != null ? 12 : 20),
                                child: Icon(
                                  viewController.isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                  color: controlsTheme.iconColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (player.value.currentMediaItem?.isLive == true)
                      const Padding(padding: EdgeInsets.only(top: 12))
                    else
                      ControlFadeOut(
                        blockBackgroundClicks: true,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: SliderTheme(
                                  data: controlsTheme.progressBarTheme!,
                                  child: SizedBox(
                                    height: 16,
                                    child: Slider(
                                      value: clampDouble(
                                        (seeking.value ? currentScrub.value : actualTimeMs.toDouble()) / duration,
                                        0,
                                        1,
                                      ),
                                      onChanged: (double value) {
                                        scrubTo(value * duration);
                                      },
                                      onChangeEnd: (double value) {
                                        //seekDebouncer.forceEarly();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
