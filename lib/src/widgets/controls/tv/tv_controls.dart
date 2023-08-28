// ignore_for_file: invalid_use_of_protected_member

import 'dart:math';

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/utils/debouncer.dart';
import 'package:bccm_player/src/widgets/controls/controls_wrapper.dart';
import 'package:bccm_player/src/widgets/mini_player/loading_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../utils/svg_icons.dart';
import '../../../utils/time.dart';
import '../../../utils/num.dart';
import '../control_fade_out.dart';
import '../default/settings.dart';

class TvControls extends HookWidget {
  const TvControls({
    super.key,
  });

  static ControlsBuilder builder = (BuildContext context) {
    return const TvControls();
  };

  @override
  Widget build(BuildContext context) {
    final controlsTheme = BccmPlayerTheme.safeOf(context).controls!;
    final viewController = BccmPlayerViewController.of(context);
    final player = useListenable(viewController.playerController);
    final actualTimeMs = safeInt(player.value.playbackPositionMs ?? 0);
    final duration = max(0.0, safeDouble(player.value.currentMediaItem?.metadata?.durationMs ?? player.value.playbackPositionMs?.toDouble() ?? 1.0));
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

    final title = player.value.currentMediaItem?.metadata?.title;

    Widget buttonsRowBuilder(BuildContext context) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            SettingsButton(
              viewController: viewController,
              padding: const EdgeInsets.only(left: 24, right: 10),
              controlsTheme: controlsTheme,
              iconSize: 46,
            ),
          ],
        );

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
              autoHide: !player.value.isBuffering && player.value.playbackState == PlaybackState.playing,
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
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    icon: const Icon(Icons.close),
                                    iconSize: 32,
                                    color: controlsTheme.iconColor,
                                    padding: const EdgeInsets.all(6),
                                    onPressed: () {
                                      Navigator.maybePop(context);
                                    },
                                  ),
                                ),
                                if (title != null)
                                  Text(
                                    title,
                                    style: controlsTheme.fullscreenTitleStyle,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (player.value.currentMediaItem?.isLive == true)
                      ControlFadeOut(child: Center(child: buttonsRowBuilder(context)))
                    else
                      Container(
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.only(left: 12, right: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ControlFadeOut(
                              blockBackgroundClicks: true,
                              child: SizedBox(
                                height: 42,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (player.value.currentMediaItem?.isLive != true)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 13),
                                        child: Text(
                                          '${getFormattedDuration(seeking.value ? currentScrub.value : actualTimeMs)} / ${getFormattedDuration(duration)}',
                                          style: controlsTheme.durationTextStyle,
                                        ),
                                      ),
                                    Expanded(
                                      child: SliderTheme(
                                        data: controlsTheme.progressBarTheme!,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            ),
                            ControlFadeOut(
                              blockBackgroundClicks: true,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [buttonsRowBuilder(context)],
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
