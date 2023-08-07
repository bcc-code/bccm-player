# BccmPlayer - a flutter video player package

**Note: This was recently published so documentation may be lacking, but we want this to work for others, so create an issue on github if you need help.**

This is a video player primarily designed for video-heavy apps that need features like background playback, PiP, casting, analytics, etc.

Used by the open source apps [Bible Kids](https://play.google.com/store/apps/details?id=media.bcc.kids) and [BCC Media](https://apps.apple.com/no/app/brunstadtv/id913268220). ([source code here](https://github.com/bcc-code/bcc-media-app)).

### Difference from video_player/chewie/betterplayer, etc.

A major difference is that BccmPlayer uses hybrid composition platform views to display the video instead of textures.
This means the video is rendered in the native view hierarchy without any intermediate steps, which has several benefits:

- Native video performance
- Subtitles are rendered by the native player (avplayer/exoplayer)
- Can use native controls (`useNativeControls` on VideoPlayerView)

## Platforms

- [x] iOS
- [x] Android
- [-] Web (partial/hacky)

## Features

- [x] Native video via hybrid composition
- [x] HLS, DASH, MP4 (anything exoplayer and avplayer supports)
- [x] Chromecast
- [x] Background playback
- [x] Picture in picture
- [x] Notification center
- [x] Audio track selection
- [x] Subtitle track selection
- [x] Fullscreen
- [x] NPAW/Youbora analytics
- [x] Metadata
- [x] HDR content (see [HDR](#hdr-content-surfaceviews))

# Installation

1. Add the dependency

   ```bash
   flutter pub add bccm_player
   ```

2. (Android) For native fullscreen and picture-in-picture to work correctly, you need to override these 2 methods on your MainActivity:

   ```kotlin
   class MainActivity : FlutterFragmentActivity() {
       @SuppressLint("MissingSuperCall")
       override fun onPictureInPictureModeChanged(
           isInPictureInPictureMode: Boolean,
           newConfig: Configuration?
       ) {
           super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
           // This is important for PiP to behave correctly (e.g. pause video when exiting PiP).
           val bccmPlayer =
               flutterEngine?.plugins?.get(BccmPlayerPlugin::class.javaObjectType) as BccmPlayerPlugin?
           bccmPlayer?.handleOnPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
       }

       override fun onBackPressed() {
           // This makes the back button work correctly in the native fullscreen player.
           // Returns true if the event was handled.
           if (!BccmPlayerPlugin.handleOnBackPressed(this)) {
               super.onBackPressed()
           }
       }
   }
   ```

3. (Android) Add `supportsPictureInPicture="true"` to your AndroidManifest for MainActivity:

```xml
        <activity
            android:name=".MainActivity"
            android:supportsPictureInPicture="true"
            ...
```

# Usage

## Initialize

This is necessary to ensure some of the more advanced features work smoothly.
Add this to your main.dart before runApp().

```dart
await BccmPlayerInterface.instance.setup(); // don't worry, it completes in milliseconds.
```

## Basic usage

_Note: This is mostly to explain how things work. Even for simple use cases, I recommend skipping straight to the [Advanced Usage section](#advanced-usage)._

```dart
// Create a player
final playerId = await BccmPlayerInterface.instance.newPlayer();

// Play something
await BccmPlayerInterface.instance.replaceCurrentMediaItem(
    playerId,
    MediaItem(
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        mimeType: 'video/mp4',
        metadata: MediaMetadata(title: 'Bick Buck Bunny (MP4)'),
    ),
);

// Show it via a widget
@override
Widget build(BuildContext context, WidgetRef ref) {
    return VideoPlayerView(playerId: playerId);
}
```

Use the widgets:

- VideoPlayerView(): The normal widget for displaying a video with controls.
- VideoPlatformView(): A raw video widget
- BccmCastButton(): A button to connect to cast-enabled devices
- MiniPlayer(): A skeleton widget included for convenience.

## Advanced usage

### Primary player

As this plugin is designed for a VOD-type application, the plugin has the concept of a "primary" player. The plugin guarantees a primary player during initialization.
This makes it easy for flutter to know which player to use by default across your app.
The primary player also has some extra superpowers:

- it controls what's shown in the notification center
- it automatically transfers the current video to chromecasts when you start a session ([technical details here](#chromecast-technical-details)).
- cast sessions will automatically claim the primaryPlayer (so you don't need extra logic for handling the cast sessions)

The primaryPlayerId is available via the StateNotifier at BccmPlayerInterface.instance.stateNotifier.
Example usage with our builtin [riverpod integration](#riverpod):

```dart
final primaryPlayerState = ref.watch(primaryPlayerProvider);
final widget = VideoPlayerView(playerId: primaryPlayerState.id);
debugPrint('Currently playing: ${primaryPlayerState.currentMediaItem?.metadata?.title}');
```

### Configure default languages

```dart
BccmPlayerInterface.instance.setAppConfig(
    AppConfig(
      appLanguage: appLanguage.languageCode, // 2-letter IETF BCP 47 code
      audioLanguage: audioLanguage, // 2-letter IETF BCP 47 code
      subtitleLanguage: subtitleLanguage, // 2-letter IETF BCP 47 code
      analyticsId: analyticsId, // Can be used by analytics services like NPAW
      sessionId: sessionId, // Can be used by analytics services like NPAW
    ),
)
```

### Custom controls

This is designed to be possible but it's not possible yet.
If anyone needs this I can make it possible very quickly so just create an issue and tag @andreasgangso.

### HDR content, SurfaceViews

For this to work on Android you need to enable SurfaceViews.
However, the reason this isn't enabled by default is because flutter has a bug with surface views.
Check out [this issue on the flutter repo](https://github.com/flutter/flutter/issues/89558).

You can opt-in to using surfaceViews via the `useSurfaceView` property on VideoPlayerView or VideoPlatformView:

```dart
VideoPlayerView(
    id: player.playerId,
    useSurfaceView: true,
),
```

### Chromecast

Casting requires some extra steps to setup.

1. You need a [receiver app ID](https://developers.google.com/cast/docs/overview). Recommend starting with the receiver code at https://github.com/bcc-code/bccm-player-chromecast, as it includes support for [default languages](#configure-default-languages). That receiver is also available at this appId for testing: `519C9F80`.
2. (Android) Change your android FlutterActivity to be a FlutterFragmentActivity (required for the native chromecast views):

   ```diff
   // android/app/src/main/kotlin/your/bundle/name/MainActivity.kt
   - class MainActivity : FlutterActivity() {
   + class MainActivity : FlutterFragmentActivity() {
   ```

3. (Android) Add a values.xml with your own receiver id: `<string name="cast_app_id">ABCD1234</string>`
4. (Android) Update `NormalTheme` in your `styles.xml` to use an AppCompat theme and have a `colorPrimary`. This is a requirement from the Cast SDK.

   ```xml
   <style name="NormalTheme" parent="@style/Theme.AppCompat.Light.NoActionBar"> <!-- Change to use "AppCompat" -->
       <item name="android:windowBackground">?android:colorBackground</item> <!-- This was already there -->
       <item name="colorPrimary">#ffffffff</item> <!-- Added -->
   </style>
   ```

5. (Android) Update `NormalTheme` in your `night/styles.xml` too:

   ```xml
       <style name="NormalTheme" parent="@style/Theme.AppCompat.NoActionBar"> <!-- Note there's no "Light" -->
        <item name="android:windowBackground">?android:colorBackground</item>
        <item name="colorPrimary">#ffffffff</item>  <!-- Added -->
    </style>
   ```

6. (iOS) Follow the cast sdk documentation on how to add the "NSBonjourServices" and "NSLocalNetworkUsageDescription" plist values: https://developers.google.com/cast/docs/ios_sender#ios_14
7. (iOS) Add your receiver id to your Info.plist:
   ```xml
      <key>cast_app_id</key>
      <string>ABCD1234</string>
   ```
8. (iOS) Example Info.plist for step 4 and 5:
   ```xml
    <key>cast_app_id</key>
    <string>519C9F80</string>
    <key>NSLocalNetworkUsageDescription</key>
    <string>${PRODUCT_NAME} uses the local network to discover Cast-enabled devices on your WiFi
    network.</string>
    <key>NSBonjourServices</key>
    <array>
        <string>_519C9F80._googlecast._tcp</string>
        <string>_googlecast._tcp</string>
    </array>
   ```

# Plugins

## Riverpod

The riverpod providers are there to simplify usage of the StateNotifiers and event streams. See [./lib/src/plugins/riverpod/providers](./lib/src/plugins/riverpod/providers) to find available providers.

```dart

final player = ref.watch(primaryPlayerProvider); // should never be null when the plugin is initialized
VideoPlayerView(id: player.playerId);

```

## Npaw / Youbora

NPAW can be enabled with "setNpawConfig()":

```dart
BccmPlayerInterface.instance.setNpawConfig(
    NpawConfig(
        accountCode: '',
        appName: '',
    ),
)
```

It uses title etc from your MediaMetadata by default, but you can customize it via `extras`.
Currently limited to the following properties:

```dart
MediaMetadata(
    extras: {
        'npaw.content.id': '123',
        'npaw.content.title': 'Live',
        'npaw.content.tvShow': 'Show',
        'npaw.content.season': 'Season',
        'npaw.content.episodeTitle': 'Livestream',
        'npaw.content.isLive': 'true',
    },
);
```

## For BCC Media apps

Add the BCC Media playback listener (sends episode progress to API and that kind of stuff).
Add it in main.dart.

```dart
BccmPlayerInterface.instance.addPlaybackListener(
    BccmPlaybackListener(ref: ref, apiProvider: apiProvider),
)
```

# Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)
