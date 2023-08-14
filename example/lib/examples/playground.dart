import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player_example/example_videos.dart';
import 'package:flutter/material.dart';

class Playground extends StatefulWidget {
  const Playground({super.key});

  @override
  State<Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground> {
  bool useSurfaceView = false;
  late BccmPlayerViewController viewController;

  @override
  void initState() {
    super.initState();
    viewController = BccmPlayerViewController(
      playerController: BccmPlayerController.primary,
      config: BccmPlayerViewConfig(
        useSurfaceView: useSurfaceView,
        controlsConfig: BccmPlayerControlsConfig(
          playbackSpeeds: const [0.1, 0.2, 0.5, 1.0, 1.5, 2.0, 5.0],
          hidePlaybackSpeed: false,
          hideQualitySelector: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = BccmPlayerController.primary;
    return SafeArea(
      child: Center(
        child: controller.value.isInitialized == false
            ? const Text('No player')
            : Column(
                children: [
                  Text(controller.value.playerId),
                  Text(controller.value.playbackSpeed.toString()),
                  BccmPlayerView.withViewController(
                    viewController,
                    key: ValueKey('player surface-view:$useSurfaceView'),
                  ),
                  ...exampleVideos.map(
                    (MediaItem mediaItem) => ElevatedButton(
                      onPressed: () {
                        BccmPlayerInterface.instance.replaceCurrentMediaItem(
                          controller.value.playerId,
                          mediaItem,
                        );
                      },
                      child: Text('${mediaItem.metadata?.title}'),
                    ),
                  ),
                  ...[0.5, 1.0, 2.0].map(
                    (speed) => ElevatedButton(
                      onPressed: () {
                        BccmPlayerInterface.instance.setPlaybackSpeed(
                          controller.value.playerId,
                          speed,
                        );
                      },
                      child: Text('playbackSpeed $speed'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        useSurfaceView = !useSurfaceView;
                      });
                    },
                    child: Text('useSurfaceView: $useSurfaceView'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      viewController.enterFullscreen();
                    },
                    child: const Text('enter fullscreen'),
                  )
                ],
              ),
      ),
    );
  }
}
