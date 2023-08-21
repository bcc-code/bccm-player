import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player_example/example_videos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        deviceOrientationsNormal: (_) => const [DeviceOrientation.portraitUp],
        deviceOrientationsFullscreen: (viewController) {
          final videoSize = viewController.playerController.value.videoSize;
          if (videoSize == null || videoSize.aspectRatio == 1) {
            return [DeviceOrientation.landscapeLeft];
          }
          return null;
        },
        controlsConfig: BccmPlayerControlsConfig(),
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
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 24, bottom: 16),
                      child: Text(
                        'Playground',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: BccmPlayerView.withViewController(
                        viewController,
                        key: ValueKey('player surface-view:$useSurfaceView'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<PlayerState>(
                      valueListenable: controller,
                      builder: (context, value, _) => MiniPlayer(
                        title: controller.value.currentMediaItem?.metadata?.title ?? 'Not playing',
                        secondaryTitle: null,
                        artworkUri: controller.value.currentMediaItem?.metadata?.artworkUri,
                        isPlaying: controller.value.playbackState == PlaybackState.playing,
                        onPlayTap: () => controller.play(),
                        onPauseTap: () => controller.pause(),
                        onCloseTap: () => controller.stop(reset: true),
                      ),
                    ),
                    const SizedBox(height: 32),
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
      ),
    );
  }
}
