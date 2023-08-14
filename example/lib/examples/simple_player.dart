import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';

class SimplePlayer extends StatefulWidget {
  const SimplePlayer({super.key});

  @override
  State<SimplePlayer> createState() => _SimplePlayerState();
}

class _SimplePlayerState extends State<SimplePlayer> {
  late BccmPlayerController playerController;

  @override
  void initState() {
    playerController = BccmPlayerController(
      MediaItem(
        url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8',
        mimeType: 'application/x-mpegURL',
        metadata: MediaMetadata(title: 'Apple advanced (HLS/HDR)'),
      ),
    );
    playerController.initialize().then((_) => playerController.setMixWithOthers(true)); // if you want to play together with other videos
    super.initState();
  }

  @override
  void dispose() {
    playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          children: [
            BccmPlayerView(playerController),
            ElevatedButton(
              onPressed: () {
                playerController.setPrimary();
              },
              child: const Text('Make primary'),
            ),
            ElevatedButton(
              onPressed: () {
                final currentMs = playerController.value.playbackPositionMs;
                if (currentMs != null) {
                  playerController.seekTo(Duration(milliseconds: currentMs + 20000));
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
