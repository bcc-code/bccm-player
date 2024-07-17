import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/utils/svg_icons.dart';
import 'package:bccm_player/src/widgets/mini_player/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

class PlayPauseButton extends HookWidget {
  const PlayPauseButton({super.key, required this.player, this.onPressed});

  final BccmPlayerController player;
  final void Function(bool newState)? onPressed;

  @override
  Widget build(BuildContext context) {
    final controlsTheme = BccmPlayerTheme.safeOf(context).controls!;
    final state = useListenableSelector(player, () => player.value.playbackState);
    if (state != PlaybackState.playing) {
      return IconButton(
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
          player.play();
          onPressed?.call(true);
        },
      );
    } else {
      return IconButton(
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
          onPressed?.call(false);
        },
      );
    }
  }
}
