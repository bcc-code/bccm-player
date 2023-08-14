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
      playerController: BccmPlayerInterface.instance.primaryController,
      controlsOptions: PlayerControlsOptions(
        playbackSpeeds: const [0.1, 0.2, 0.5, 1.0, 1.5, 2.0, 5.0],
        hidePlaybackSpeed: false,
        hideQualitySelector: false,
      ),
      useSurfaceView: useSurfaceView,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = BccmPlayerInterface.instance.primaryController;
    return SafeArea(
      child: Center(
        child: controller.value.isInitialized == false
            ? const Text('No player')
            : Column(
                children: [
                  Text(controller.value.playerId),
                  Text(controller.value.playbackSpeed.toString()),
                  BccmPlayerView(key: ValueKey('player surface-view:$useSurfaceView'), viewController),
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
                  )
                ],
              ),
      ),
    );
  }
}
