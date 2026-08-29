import 'dart:async';

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player_example/example_videos.dart';
import 'package:flutter/material.dart';
import 'package:preload_page_view/preload_page_view.dart';

class PreloadPlayerPage extends StatefulWidget {
  const PreloadPlayerPage({super.key});

  @override
  State<PreloadPlayerPage> createState() => _PreloadPlayerPageState();
}

class _PreloadPlayerPageState extends State<PreloadPlayerPage> {
  int initialIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preload Players"),
      ),
      body: PreloadPageView.builder(
        itemCount: exampleVideos.length,
        preloadPagesCount: exampleVideos.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (BuildContext context, int index) {
          final MediaItem mediaItem = exampleVideos[index];
          return _PortraitPlayer(
            mediaItem: mediaItem,
            isPrimary: initialIndex == index,
            currentIndex: initialIndex,
          );
        },
        controller: PreloadPageController(),
        onPageChanged: (int position) {
          setState(() => initialIndex = position);
          print('page changed. current: $position');
        },
      ),
    );
  }
}

class _PortraitPlayer extends StatefulWidget {
  final MediaItem mediaItem;
  final bool isPrimary;
  final int currentIndex;
  const _PortraitPlayer({
    required this.mediaItem,
    required this.isPrimary,
    required this.currentIndex,
  });

  @override
  State<_PortraitPlayer> createState() => __PortraitPlayerState();
}

class __PortraitPlayerState extends State<_PortraitPlayer> {
  late BccmPlayerController playerController;
  late BccmPlayerViewController viewController;

  FutureOr<void> setupPlayer() async {
    playerController = BccmPlayerController(widget.mediaItem);
    viewController = BccmPlayerViewController(
      playerController: playerController,
      config: BccmPlayerViewConfig(useSurfaceView: false, videoFit: BoxFit.contain),
    );

    playerController.initialize().then((_) {
      playerController.setMixWithOthers(true);
      playerController.play();
    });
  }

  @override
  void initState() {
    setupPlayer();
    super.initState();
  }

  @override
  void dispose() {
    playerController.stop(reset: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPrimary) return Text('Is not primary = ${widget.isPrimary} - ${widget.currentIndex}');
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: BccmPlayerView(playerController, config: viewController.config),
        ),
        Text('${widget.currentIndex}'),
      ],
    );
  }
}
