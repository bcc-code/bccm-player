# Usage

## Initialize

This is necessary to ensure some of the more advanced features work smoothly.
Add this to your main.dart before runApp().

```dart
await BccmPlayerInterface.instance.setup(); // don't worry, it completes in milliseconds.
```

## Basic usage

_Note: This is mostly to explain how things work. Even for simple use cases, we recommend skipping straight to "Advanced Usage"._

```dart
// Use the primary player (always available and initialized)
final controller = BccmPlayerController.primary;
await controller.replaceCurrentMediaItem(
      MediaItem(
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        mimeType: 'video/mp4',
        metadata: MediaMetadata(title: 'Apple advanced (HLS/HDR)'),
      ),
    );

// or create a new one, optionally with a MediaItem
final controller = BccmPlayerController(
      MediaItem(
        url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8',
        mimeType: 'application/x-mpegURL',
        metadata: MediaMetadata(title: 'Apple advanced (HLS/HDR)'),
      ),
    );
await controller.initialize();

// Show it via a widget
@override
Widget build(BuildContext context) {
    return VideoPlayerView(controller: controller);
}

// If you created a new player (not primary), remember to dispose it
@override
void dispose() {
    if (!controller.isPrimary) {
        controller.dispose();
    }
}
```

Use the widgets:

- VideoPlayerView(): The normal widget for displaying a video with controls.
- VideoPlatformView(): A raw video widget
- CastButton(): A button to connect to cast-enabled devices
- MiniPlayer(): A skeleton widget included for convenience.
