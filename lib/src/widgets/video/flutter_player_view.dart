import 'package:bccm_player/bccm_player.dart';

import '../cast/cast_player.dart';
import 'package:flutter/widgets.dart';

import '../controls/default_controls.dart';

/// The normal/default implementation of a [BccmPlayerView].
///
/// Read comments on [BccmPlayerView] for more details.
class FlutterBccmPlayerView extends StatefulWidget implements BccmPlayerView {
  final BccmPlayerViewController viewController;
  const FlutterBccmPlayerView(
    this.viewController, {
    super.key,
  });

  @override
  State<FlutterBccmPlayerView> createState() => _FlutterBccmPlayerViewState();
}

class _FlutterBccmPlayerViewState extends State<FlutterBccmPlayerView> {
  late String playerId;

  void onPlayerControllerUpdate() {
    playerId = widget.viewController.playerController.value.playerId;
  }

  @override
  void initState() {
    super.initState();
    widget.viewController.playerController.addListener(onPlayerControllerUpdate);
    onPlayerControllerUpdate();
  }

  @override
  void dispose() {
    widget.viewController.playerController.removeListener(onPlayerControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (playerId == 'chromecast') {
      return widget.viewController.castPlayerBuilder != null ? widget.viewController.castPlayerBuilder!(context) : const CastPlayer();
    }

    return Stack(
      children: [
        Center(
          child: IgnorePointer(
            ignoring: true,
            child: VideoPlatformView(
              playerController: widget.viewController.playerController,
              showControls: false,
              useSurfaceView: widget.viewController.useSurfaceView,
            ),
          ),
        ),
        Positioned.fill(
          child: Builder(builder: (context) {
            final controlsBuilder = widget.viewController.controlsOptions.customBuilder ?? DefaultControls.builder;
            return controlsBuilder(context, widget.viewController);
          }),
        ),
      ],
    );
  }
}
