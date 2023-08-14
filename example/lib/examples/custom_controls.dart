import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';

class CustomControls extends StatefulWidget {
  const CustomControls({super.key});

  @override
  State<CustomControls> createState() => _CustomControlsState();
}

class _CustomControlsState extends State<CustomControls> {
  late BccmPlayerViewController playerViewController;

  @override
  void initState() {
    playerViewController = BccmPlayerViewController(
        playerController: BccmPlayerController.primary,
        controlsOptions: PlayerControlsOptions(
          customBuilder: (context, viewController) => MyControls(viewController),
        ));
    BccmPlayerController.primary.replaceCurrentMediaItem(
      MediaItem(
        url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8',
        mimeType: 'application/x-mpegURL',
        metadata: MediaMetadata(title: 'Apple advanced (HLS/HDR)'),
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    playerViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          children: [
            BccmPlayerView(playerViewController),
          ],
        ),
      ],
    );
  }
}

class MyControls extends StatelessWidget {
  const MyControls(this.viewController, {Key? key}) : super(key: key);

  final BccmPlayerViewController viewController;

  @override
  Widget build(BuildContext context) {
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
