## 1.0.0

- BREAKING CHANGE: VideoPlayerView() is now BccmPlayerView() and now takes a BccmPlayerViewConfig instead. This is for consistency and to avoid confusion.
- Feature: BccmPlayerViewController, which you can use to enter and exit fullscreen programatically.
- Feature: Custom controls builder

## 0.2.4

- Improved code comments
- Fix: [VideoPlatformView] was not exported.

## 0.2.3

- Major breaking changes to how to use the plugin
- Introduced a BccmPlayerController which makes usage more idiomatic and more alike other video player packages.

## 0.2.2

- Chromecast setup improvements, add missing documentation.

## 0.2.1

- New property `useSurfaceView` to support HDR content (#6). It's opt-in because it can trigger a flutter bug, see docs for HDR.

## 0.2.0

- New feature: Quality selection ([#4](https://github.com/bcc-code/bccm-player/pull/4)) ("Max quality" on iOS because its practically impossible to force a rendition with avplayer)
- BREAKING CHANGE: `showPlaybackSpeed` renamed to `hidePlaybackSpeed`

## 0.1.0

- BREAKING CHANGE: `useNativeControls` on enterFullscreen and VideoPlayerView now defaults to false instead of true.
- Migrate from wakelock to wakelock_plus

## 0.0.2

- Simplified integration steps needed for native fullscreen and picture-in-picture to work correctly on android.

## 0.0.1

- Initial release
