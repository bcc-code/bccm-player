import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/plugins/riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BccmPlayerInterface.instance.setup();
  final providerContainer = ProviderContainer();
  runApp(
    UncontrolledProviderScope(
      container: providerContainer,
      child: const MyApp(),
    ),
  );
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(primaryPlayerProvider);
    if (player == null) {
      return const Center(child: Text('Player id not set'));
    }
    final useSurfaceView = useState(true);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: CastButton(color: Colors.white),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              children: [
                Text(player.playerId),
                Text(player.playbackSpeed.toString()),
                VideoPlayerView(
                  key: ValueKey('player surface-view:${useSurfaceView.value}'),
                  id: player.playerId,
                  useNativeControls: false,
                  playbackSpeeds: const [0.1, 0.2, 0.5, 1.0, 1.5, 2.0, 5.0],
                  hidePlaybackSpeed: false,
                  hideQualitySelector: false,
                  useSurfaceView: useSurfaceView.value,
                ),
                ...[
                  MediaItem(
                    url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                    mimeType: 'video/mp4',
                    metadata: MediaMetadata(title: 'Big Buck Bunny (MP4)'),
                  ),
                  MediaItem(
                    url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8',
                    mimeType: 'application/x-mpegURL',
                    metadata: MediaMetadata(title: 'Apple BipBop fMP4 (HLS)'),
                  ),
                  MediaItem(
                    url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8',
                    mimeType: 'application/x-mpegURL',
                    metadata: MediaMetadata(title: 'Apple advanced (HLS/HDR)'),
                  ),
                ].map(
                  (MediaItem mediaItem) => ElevatedButton(
                    onPressed: () {
                      BccmPlayerInterface.instance.replaceCurrentMediaItem(
                        player.playerId,
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
                        player.playerId,
                        speed,
                      );
                    },
                    child: Text('playbackSpeed $speed'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    useSurfaceView.value = !useSurfaceView.value;
                  },
                  child: Text('useSurfaceView: ${useSurfaceView.value}'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
