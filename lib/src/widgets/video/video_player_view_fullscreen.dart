import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/state/player_controller.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flutter/material.dart';

class VideoPlayerViewFullscreen extends HookWidget {
  const VideoPlayerViewFullscreen({
    super.key,
    required this.controller,
    this.playNextButton,
    this.castPlayerBuilder,
  });

  final BccmPlayerController controller;
  final WidgetBuilder? playNextButton;
  final WidgetBuilder? castPlayerBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            color: Colors.black,
          ),
          SizedBox.expand(
            child: Align(
              alignment: Alignment.center,
              child: VideoPlayerView(
                controller: controller,
                useNativeControls: false,
                isFullscreenPlayer: true,
                playNextButton: playNextButton,
                castPlayerBuilder: castPlayerBuilder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
