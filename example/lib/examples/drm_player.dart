import 'dart:io';

import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';

class DrmPlayer extends StatefulWidget {
  const DrmPlayer({super.key});

  @override
  State<DrmPlayer> createState() => _DrmPlayerState();
}

class _DrmPlayerState extends State<DrmPlayer> {
  late BccmPlayerController playerController;

  @override
  void initState() {
    playerController = BccmPlayerController(MediaItem(
      url: TempDrmSource.file,
      mimeType: Platform.isAndroid ? 'application/dash+xml' : 'application/vnd.apple.mpegurl',
      drmConfiguration: DrmConfiguration(
        drmType: DrmType.widevine,
        licenseServerUrl: TempDrmSource.licenseUrl,
        licenseRequestHeaders: {'X-AxDRM-Message': TempDrmSource.token},
      ),
    ));
    playerController.addListener(playerListener);
    playerController.events.listen(playerEventListener);
    playerController.initialize().then((_) => playerController.setMixWithOthers(false));
    super.initState();
  }

  void playerListener() {
    final result = playerController.value;
    print('@playerListener: ${result.playbackState}');
  }

  void playerEventListener(dynamic event) {
    print('@playerEventListener: $event');
  }

  @override
  void dispose() {
    playerController.removeListener(playerListener);
    playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BccmPlayerView(
            playerController,
            config: BccmPlayerViewConfig(useSurfaceView: true),
          ),
        ],
      ),
    );
  }
}

class TempDrmSource {
  TempDrmSource._();

  static const String file = 'https://media.axprod.net/TestVectors/v7-MultiDRM-SingleKey/Manifest_1080p.mpd';
  static const String token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2ZXJzaW9uIjoxLCJjb21fa2V5X2lkIjoiYjMzNjRlYjUtNTFmNi00YWUzLThjOTgtMzNjZWQ1ZTMxYzc4IiwibWVzc2FnZSI6eyJ0eXBlIjoiZW50aXRsZW1lbnRfbWVzc2FnZSIsImZpcnN0X3BsYXlfZXhwaXJhdGlvbiI6NjAsInBsYXlyZWFkeSI6eyJyZWFsX3RpbWVfZXhwaXJhdGlvbiI6dHJ1ZX0sImtleXMiOlt7ImlkIjoiOWViNDA1MGQtZTQ0Yi00ODAyLTkzMmUtMjdkNzUwODNlMjY2IiwiZW5jcnlwdGVkX2tleSI6ImxLM09qSExZVzI0Y3Iya3RSNzRmbnc9PSJ9XX19.FAbIiPxX8BHi9RwfzD7Yn-wugU19ghrkBFKsaCPrZmU';
  static const String licenseUrl = 'https://drm-widevine-licensing.axtest.net/AcquireLicense';
}
