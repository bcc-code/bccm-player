import 'package:bccm_player/bccm_player.dart';

import 'package:flutter/widgets.dart';

/// Native controls implementation of a BccmPlayerView
///
/// Read comments on [BccmPlayerView.native] for more details.
class NativeBccmPlayerView extends StatelessWidget implements BccmPlayerView {
  final BccmPlayerNativeViewController viewController;

  const NativeBccmPlayerView(
    this.viewController, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return VideoPlatformView(playerController: viewController.playerController, showControls: true);
  }
}
