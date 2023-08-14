import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';

class CustomControls extends StatelessWidget {
  const CustomControls({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        BccmPlayerView(
          BccmPlayerController.primary,
          config: BccmPlayerViewConfig(
            controlsConfig: BccmPlayerControlsConfig(
              customBuilder: (context) => const MyControls(),
            ),
          ),
        ),
        ElevatedButton(
            onPressed: () {
              BccmPlayerController.primary.replaceCurrentMediaItem(
                MediaItem(
                  url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8',
                  mimeType: 'application/x-mpegURL',
                  metadata: MediaMetadata(title: 'Apple advanced (HLS/HDR)'),
                ),
              );
            },
            child: const Text('Play something'))
      ],
    );
  }
}

class MyControls extends StatelessWidget {
  const MyControls({super.key});

  @override
  Widget build(BuildContext context) {
    final viewController = BccmPlayerViewController.of(context);
    return Theme(
      data: Theme.of(context).copyWith(
        iconTheme: Theme.of(context).iconTheme.copyWith(color: Colors.white),
      ),
      child: ValueListenableBuilder<PlayerState>(
        valueListenable: viewController.playerController,
        builder: (context, state, widget) => Container(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 50,
            color: Colors.black,
            alignment: Alignment.bottomCenter,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (state.playbackState == PlaybackState.playing)
                  IconButton(
                    onPressed: () {
                      viewController.playerController.pause();
                    },
                    icon: const Icon(Icons.pause),
                  ),
                if (state.playbackState == PlaybackState.paused)
                  IconButton(
                    onPressed: () {
                      viewController.playerController.play();
                    },
                    icon: const Icon(Icons.play_arrow),
                  ),
                IconButton(
                  onPressed: () {
                    viewController.playerController.seekTo(Duration(milliseconds: state.playbackPositionMs! - 20000));
                  },
                  icon: const Icon(Icons.skip_previous),
                ),
                IconButton(
                  onPressed: () {
                    viewController.playerController.seekTo(Duration(milliseconds: state.playbackPositionMs! + 20000));
                  },
                  icon: const Icon(Icons.skip_next),
                ),
                if (!viewController.isFullscreen)
                  IconButton(
                    onPressed: () {
                      viewController.enterFullscreen();
                    },
                    icon: const Icon(Icons.fullscreen),
                  ),
                if (viewController.isFullscreen)
                  IconButton(
                    onPressed: () {
                      viewController.exitFullscreen();
                    },
                    icon: const Icon(Icons.fullscreen_exit),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
