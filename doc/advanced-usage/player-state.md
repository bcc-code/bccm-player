### Player state

You can get player state from your controller's "value".
Also, it's a ValueNotifier so you can listen to BccmPlayerController, exactly like other plugins (video_player, etc.).

Example:

```dart
final controller = BccmPlayerController.primary;
controller.value.videoSize.aspectRatio;
```
