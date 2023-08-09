### Primary player

As this plugin is designed for a VOD-type application, the plugin has the concept of a "primary" player. The plugin guarantees a primary player during initialization.
This makes it easy for flutter to know which player to use by default across your app.
The primary player also has some extra superpowers:

- always available: cant be disposed and is initialized on startup
- it controls what's shown in the notification center
- it automatically transfers the current video to chromecasts when you start a session ([technical details here](#chromecast-technical-details)).
- cast sessions will automatically claim the primaryPlayer (so you don't need extra logic for handling the cast sessions)

```dart
// The primary player is automatically initialized on startup
// It's accessible via BccmPlatformInterface.instance:
final controller = BccmPlatformInterface.instance.primaryController;

// Change video with replaceCurrentMediaItem
await controller.replaceCurrentMediaItem(
      MediaItem(
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        mimeType: 'video/mp4',
        metadata: MediaMetadata(title: 'Apple advanced (HLS/HDR)'),
      ),
    );

// Display as usual
final widget = VideoPlayerView(controller: controller);

// You don't need to (and actually can't) dispose the primary player.
if (!controller.isPrimary) controller.dispose();
```
