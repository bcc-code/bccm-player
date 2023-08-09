# HDR content / SurfaceView

HDR should work fine on iOS.

On Android, you need to enable SurfaceViews. However, the reason this isn't enabled by default is because flutter has a bug with surface views.
Check out [this issue on the flutter repo](https://github.com/flutter/flutter/issues/89558).

You can opt-in to using surfaceViews via the `useSurfaceView` property on VideoPlayerView or VideoPlatformView:

```dart
VideoPlayerView(
    controller: controller,
    useSurfaceView: true,
),
```
