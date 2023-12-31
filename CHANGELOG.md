## 1.1.2

- Feature: setVolume(double)
- Docs: Added a contributing guide on how setVolume() was implemented.

## 1.1.1

- Docs: Updated readme with screenshots, etc.

## 1.1.0

- Feature: custom orientation callbacks in BccmPlayerViewConfig: `deviceOrientationsNormal`/`deviceOrientationsFullscreen`. See "orientations" in docs for details.

## 1.0.6

- Feature: Configure `allowSystemGestures` in BccmPlayerViewConfig. This is `false` by default to prevent conflicts with the seekbar.

## 1.0.5

- Feature: Dynamically adjust aspect ratio instead of assuming 16/9.
- Feature: Current width/height available on `controller.value.videoSize`. Null if not available.

## 1.0.4

- Fix(ios): cast didnt become primary unless avplayer was playing something

## 1.0.3

- Fix: Scrubbing and seeking in the default controls was very unreliable and jumpy.

## 1.0.2

- Feature: show seconds inside skip/rewind buttons and expose the button as a widget in 'package:bccm_player/controls.dart'.

## 1.0.1

- Feature: additionalActionsBuilder, which allows you to add additional actions next to the fullscreen button.
- Docs: improved docs for airplay, custom controls, and theming
- Refactor: Rename `PlayerTheme` to `BccmPlayerTheme` for consistency. Also fixed it so that `primaryColor` is used more.

## 1.0.0

- BREAKING CHANGE: VideoPlayerView() is now BccmPlayerView() and now takes a BccmPlayerViewConfig instead. This is for consistency and to avoid confusion.
- Feature: BccmPlayerViewController, which you can use to enter and exit fullscreen programatically.
- Feature: Custom controls builder

## 0.2.4

- Improved code comments
- Fix: [VideoPlatformView] was not exported.

## 0.2.3

- Major breaking changes to how to use the plugin
- Introduced a BccmPlayerController which makes usage more idiomati and more alike other video player packages.

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
