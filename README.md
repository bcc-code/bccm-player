# BccmPlayer - a flutter video player package

**Note: This was recently published so documentation may be lacking, but we want this to work for others, so create an issue on github if you need help.**

This is a video player primarily designed for video-heavy apps that need features like background playback, PiP, casting, analytics, etc.

Used by the open source apps [Bible Kids](https://play.google.com/store/apps/details?id=media.bcc.kids) and [BCC Media](https://apps.apple.com/no/app/brunstadtv/id913268220). ([source code here](https://github.com/bcc-code/bcc-media-app)).

### Documentation

For all the features to work correctly, it's vital that you read the docs.
Documentation: https://bcc-code.github.io/bccm-player

### Difference from video_player/chewie/betterplayer, etc.

A major difference is that BccmPlayer uses hybrid composition platform views to display the video instead of textures.
This means the video is rendered in the native view hierarchy without any intermediate steps, which has several benefits:

- Native video performance
- Subtitles are rendered by the native player (avplayer/exoplayer)
- Can use native controls (`useNativeControls` on VideoPlayerView)

## Platforms

- [x] iOS
- [x] Android
- [ ] Web (almost, but its partial/hacky)

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
- [x] HDR content (see [HDR](#hdr-content-surfaceviews))

# Example

```dart
import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player_example/example_videos.dart';
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
    // You can also use the global "primary" controller.
    // The primary player has superpowers like notification player, background playback, casting, etc:
    // final controller = BccmPlayerInterface.instance.primaryController;
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

```

# Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)
