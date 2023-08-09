// ignore_for_file: invalid_use_of_protected_member

import 'package:bccm_player/bccm_player.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../cast/cast_player.dart';
import 'package:flutter/material.dart';

import '../controls/default_controls.dart';
import 'video_platform_view.dart';

/// Creates a video player with controls.
///
/// * [controller] is the controller for the player. See [BccmPlayerController].
/// * [useNativeControls] will use native UI for the player. NOTE: All other options will be ignored if this is true.
/// * [resetSystemOverlays] is a callback that will be called when the player exits fullscreen. Defaults to using [SystemUiMode.edgeToEdge].
/// * [playNextButton] is a widget that will be shown in the bottom right corner of the player.
/// * [isFullscreenPlayer] should only be used when this is used in a fullscreen context.
/// * [playbackSpeeds] is a list of playback speeds that will be shown in the settings menu.
/// * [hidePlaybackSpeed] will hide the playback speed selector in the settings menu.
/// * [hideQualitySelector] will hide the quality selector in the settings menu.
/// * [castPlayerBuilder] is a builder that will be used to build the cast player.
/// * [useSurfaceView] will use a SurfaceView instead of a TextureView on Android. Fixes HDR but flutter has a bug with SurfaceViews. See [the docs](https://bcc-code.github.io/bccm-player/advanced-usage/hdr-content/)
///
/// See also:
///
/// * [BccmPlayerController], which is the controller used for the player.
/// * [VideoPlatformView], which is the widget that actually renders the video.
/// * [DefaultControls], which is the default controls used for the player.
/// * [CastPlayer], which is the widget that renders the cast player.
///
class VideoPlayerView extends HookWidget {
  final BccmPlayerController controller;
  final bool useNativeControls;
  final bool isFullscreenPlayer;
  final VoidCallback? resetSystemOverlays;
  final WidgetBuilder? playNextButton;
  final List<double>? playbackSpeeds;
  final bool? hidePlaybackSpeed;
  final bool? hideQualitySelector;
  final WidgetBuilder? castPlayerBuilder;
  final bool? useSurfaceView;

  const VideoPlayerView({
    super.key,
    required this.controller,
    this.useNativeControls = false,
    this.isFullscreenPlayer = false,
    this.resetSystemOverlays,
    this.playNextButton,
    this.playbackSpeeds,
    this.hidePlaybackSpeed,
    this.hideQualitySelector,
    this.castPlayerBuilder,
    this.useSurfaceView,
  });

  @override
  Widget build(BuildContext context) {
    final isMounted = useIsMounted();
    final disableLocally = useState(
      controller.value.isFlutterFullscreen == true && !isFullscreenPlayer,
    );
    final playerId = useState(controller.value.playerId);
    useEffect(() {
      listener() {
        disableLocally.value = controller.value.isFlutterFullscreen == true && !isFullscreenPlayer;
        playerId.value = controller.value.playerId;
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [playerId, isFullscreenPlayer]);

    if (playerId.value == 'chromecast') {
      return castPlayerBuilder != null ? castPlayerBuilder!(context) : const CastPlayer();
    }
    if (useNativeControls) {
      return VideoPlatformView(
        controller: controller,
        showControls: true,
        useSurfaceView: useSurfaceView,
      );
    }
    if (disableLocally.value) {
      return const SizedBox.shrink();
    }

    Future goFullscreen() async {
      disableLocally.value = true;
      controller.enterFullscreen(
        useNativeControls: useNativeControls,
        context: context,
        resetSystemOverlays: resetSystemOverlays,
        playNextButton: playNextButton,
      );
      if (isMounted()) {
        disableLocally.value = false;
      }
    }

    Future exitFullscreen() async {
      BccmPlayerInterface.instance.exitFullscreen(playerId.value);
    }

    return _VideoWithControls(
      parent: this,
      goFullscreen: goFullscreen,
      exitFullscreen: exitFullscreen,
    );
  }
}

class _VideoWithControls extends HookWidget {
  const _VideoWithControls({
    required this.parent,
    required this.goFullscreen,
    required this.exitFullscreen,
  });

  final VideoPlayerView parent;
  final Future Function() goFullscreen;
  final Future Function() exitFullscreen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: IgnorePointer(
            ignoring: true,
            child: VideoPlatformView(
              controller: parent.controller,
              showControls: false,
              useSurfaceView: parent.useSurfaceView,
            ),
          ),
        ),
        Positioned.fill(
          child: Builder(builder: (context) {
            return DefaultControls(
              controller: parent.controller,
              exitFullscreen: exitFullscreen,
              goFullscreen: goFullscreen,
              playNextButton: parent.playNextButton,
              playbackSpeeds: parent.playbackSpeeds,
              hidePlaybackSpeed: parent.hidePlaybackSpeed,
              hideQualitySelector: parent.hideQualitySelector,
            );
          }),
        ),
      ],
    );
  }
}
