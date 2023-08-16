### Custom controls

#### Controls customization

For colors, etc, see "Styling".
If you just want to do simple changes, you have some configuration options for the controls with BccmPlayerViewConfig:

Example:

```dart
BccmPlayerView(
    controller,
    config: BccmPlayerViewConfig(
        controlsConfig: BccmPlayerControlsConfig(
            playbackSpeeds: const [0.1, 0.2, 0.5, 1.0, 1.5, 2.0, 5.0],
            hidePlaybackSpeed: false,
            hideQualitySelector: false,
        ),
      ),
),
```

#### Advanced customization

You can set a custom `controlsBuilder`.
Find "Custom controls" in the example project for an up-to-date example if this is outdated.

#### Example

```dart
import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';

class CustomControls extends StatelessWidget {
  const CustomControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BccmPlayerView(
      BccmPlayerController.primary,
      config: BccmPlayerViewConfig(
        controlsConfig: PlayerControlsConfig(
          customBuilder: (context) => const MyControls(),
        ),
      ),
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
```
