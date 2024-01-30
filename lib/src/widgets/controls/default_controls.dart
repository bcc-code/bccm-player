// ignore_for_file: invalid_use_of_protected_member

import 'dart:math';

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/controls.dart';
import 'package:bccm_player/src/widgets/controls/default/fullscreen_button.dart';
import 'package:bccm_player/src/widgets/mini_player/loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/svg_icons.dart';
import '../../utils/time.dart';

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
    final timeline = useTimeline(viewController.playerController);

    final forwardRewindDurationSec = Duration(milliseconds: timeline.duration.toInt()).inMinutes > 60 ? 30 : 15;
    final title = player.value.currentMediaItem?.metadata?.title;

    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(navigationMode: NavigationMode.directional),
        child: Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
          },
          child: SizedBox.expand(
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
                              if (viewController.config.controlsConfig.topRightNextToSettingsSlot != null)
                                viewController.config.controlsConfig.topRightNextToSettingsSlot!(context),
                              SettingsButton(
                                viewController: viewController,
                                padding: const EdgeInsets.only(top: 12, bottom: 24, left: 24, right: 10),
                                controlsTheme: controlsTheme,
                                removePadding: true,
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
                                onPressed: () => timeline.scrubToRelative(-forwardRewindDurationSec * 1000),
                                icon: const Icon(Icons.replay),
                              ),
                            ),
                            if (player.value.playbackState != PlaybackState.playing)
                              IconButton(
                                autofocus: true,
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
                                onPressed: () => timeline.scrubToRelative(forwardRewindDurationSec * 1000),
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
                                        '${getFormattedDuration(timeline.seeking ? timeline.currentScrub : timeline.actualTimeMs)} / ${getFormattedDuration(timeline.duration)}',
                                        style: controlsTheme.durationTextStyle,
                                      ),
                                    ),
                                  const Spacer(),
                                  ...?viewController.config.controlsConfig.additionalActionsBuilder?.call(context),
                                  FullscreenButton(
                                    viewController: viewController,
                                    padding: EdgeInsets.only(
                                      right: 10,
                                      top: 8,
                                      bottom: 5,
                                      left: viewController.config.controlsConfig.additionalActionsBuilder != null ? 12 : 20,
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
                                            value: timeline.timeFraction,
                                            onChanged: (double value) {
                                              timeline.scrubTo(value * timeline.duration);
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
          ),
        ),
      ),
    );
  }
}
