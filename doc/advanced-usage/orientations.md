### Orientations

The default when entering fullscreen is to force landscape for landscape videos, portrait for portrait videos and allow all if undetermined.
When exiting, the default is to allow all orientations.

To control orientations, use the `deviceOrientationsNormal`/`deviceOrientationsFullscreen` on BccmPlayerViewConfig.
These callbacks receives the relevant `viewController` as arguments, and should return either a specific list of orientations, or `null` get the default behavior.

This gives a lot of flexibility for you to determine how to handle the specific scenario.

#### Example: Force portrait when exiting fullscreen

If you want to use the default adaptive behavior in fullscreen, but need to force portrait mode in your app, use `deviceOrientationsNormal`:

```dart
BccmPlayerViewConfig(
    deviceOrientationsNormal: (_) => [DeviceOrientations.portraitUp],
)
```

#### Example: Assume landscape for uninitialized/square videos

If you want to force landscape if the video is square or uninitialized, use `deviceOrientationsFullscreen`:

```dart
BccmPlayerViewConfig(
    deviceOrientationsFullscreen: (viewController) {
        final videoSize = viewController.playerController.value.videoSize;
        if (videoSize == null || videoSize.aspectRatio == 1) {
            return [DeviceOrientation.landscapeLeft];
        }
        return null; // return null to get default behavior
    },
)
```
