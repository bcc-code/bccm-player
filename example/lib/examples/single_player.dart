import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';

class SinglePlayer extends StatefulWidget {
  const SinglePlayer({super.key});

  @override
  State<SinglePlayer> createState() => _SinglePlayerState();
}

class _SinglePlayerState extends State<SinglePlayer> {
  late BccmPlayerController controller;

  @override
  void initState() {
    controller = BccmPlayerController(
      MediaItem(
        url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8',
        mimeType: 'application/x-mpegURL',
        metadata: MediaMetadata(title: 'Apple advanced (HLS/HDR)'),
      ),
    );
    controller.initialize().then((_) => controller.setMixWithOthers(true)); // if you want to play together with other videos
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          children: [
            VideoPlayerView(controller: controller),
            ElevatedButton(
              onPressed: () {
                controller.setPrimary();
              },
              child: const Text('Make primary'),
            ),
            ElevatedButton(
              onPressed: () {
                final currentMs = controller.value.playbackPositionMs;
                if (currentMs != null) {
                  controller.seekTo(Duration(milliseconds: currentMs + 20000));
                }
              },
              child: const Text('Skip 20 seconds'),
            ),
          ],
        ),
      ],
    );
  }
}
