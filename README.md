# BccmPlayer - a flutter video player package

This is a video player primarily designed for video-heavy apps that need features like background playback, PiP, casting, analytics, etc.

Used by the open source apps [Bible Kids](https://play.google.com/store/apps/details?id=media.bcc.kids) and [BCC Media](https://apps.apple.com/no/app/brunstadtv/id913268220). ([source code here](https://github.com/bcc-code/bcc-media-app)).

[![pub package](https://img.shields.io/pub/v/bccm_player.svg)](https://pub.dev/packages/bccm_player)

![Controls screenshot](https://github.com/bcc-code/bccm-player/blob/main/doc/demo/controls.jpg?raw=true)
![Casting screenshot](https://github.com/bcc-code/bccm-player/blob/main/doc/demo/casting.jpg?raw=true)

![Demo on android](https://github.com/bcc-code/bccm-player/blob/main/doc/demo/demo.mp4?raw=true)

### Documentation

For all the features to work correctly, it's vital that you read the docs.

Documentation: https://bcc-code.github.io/bccm-player/

**Create an issue on github if you need help.**

### Difference from video_player/chewie/betterplayer, etc.

A major difference is that BccmPlayer uses hybrid composition platform views to display the video instead of textures.
This means the video is rendered in the native view hierarchy without any intermediate steps, which has several benefits:

- Native video performance
- Subtitles are rendered by the native player (avplayer/exoplayer)
- Can use native controls (`showControls` on [VideoPlatformView])

## Platforms

- [x] iOS
- [x] Android
- [ ] ~~Web~~. Some groundwork is there, but it's not complete and it's not supported.

## Features

- [x] Native video via hybrid composition
- [x] HLS, DASH, MP4 (anything exoplayer and avplayer supports)
- [x] Chromecast
- [x] Background playback
- [x] Picture in picture
- [x] Notification center
- [x] Audio track selection
- [x] Subtitle track selection
- [x] Fullscreen
- [x] NPAW/Youbora analytics
- [x] Metadata
- [x] HDR content (read [HDR](https://bcc-code.github.io/bccm-player/advanced-usage/hdr-content/) in the docs)

# Example

```dart
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
    // You can also use the global "primary" controller: BccmPlayerController.primary;
    // The primary player has superpowers like notification player, background playback, casting, etc.
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
            BccmPlayerView(
              playerController,
              //config: BccmPlayerViewConfig()
            ),
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


```

# Contributing

Thank you for the interest in contributing!
We want to improve the codebase so that it's usable for others too, so we are very open for PRs and issues.
The docs has a page about architecture details to help you understand the codebase.

Before starting on a bigger change it might be a good idea to create an issue about your ideas so that we can help you out and become aligned.
