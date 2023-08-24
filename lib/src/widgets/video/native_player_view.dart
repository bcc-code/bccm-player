import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';

class NativeBccmPlayerView extends StatelessWidget implements BccmPlayerView {
  const NativeBccmPlayerView(
    this.playerController, {
    super.key,
  });

  final BccmPlayerController playerController;

  @override
  Widget build(BuildContext context) {
    return VideoPlatformView(
      playerController: playerController,
      showControls: true,
    );
  }
}
