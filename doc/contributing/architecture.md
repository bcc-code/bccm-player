## Players and controllers

The plugin manages a list of "PlayerControllers", which currently has the following implementations:

- (iOS) AVQueuePlayerController, which uses AVQueuePlayer.
- (Android) ExoPlayerController, which uses Media3 ExoPlayer.
- CastPlayerController, for chromecasts. Expected to be only one of this.

## Player views

The following views are accessible from flutter:

## State management

State management is built-in, see [PluginStateNotifier](./lib/src/state/plugin_state_notifier.dart). This has a `players` map with [PlayerStateNotifiers](./lib/src/state/player_state_notifier.dart). The PluginStateNotifier is kept in sync with the native side counterparts: `PlaybackService` (Android) and `PlaybackApiImpl` (iOS).

Data is transferred back and forth via pigeons: PlaybackPlatformPigeon, ChromecastPigeon, PlaybackListenerPigeon etc.
See [./pigeons/README.md](./pigeons/README.md).

## Plugin initialization

The plugin does the following during init:

**Native**

- (Android only) Creates a _bounded_ service, PlaybackService, which enables background playback and a notification.
- Creates 1x PlayerController to be used as primary by default.
- Creates a CastPlayerController. Expected to be only one. Becomes primary if a session exists.

**Dart**

- Calls .attach() which hooks in the listeners etc for the plugin. This is necessary because all dart isolates enables all plugins, at least on Android, and this makes it easy to identify which is the 'real' dart isolate.
- Gets state for the primary player

## Chromecast technical details

On session start/resume:

- If the current primary player is playing, transfers the state automatically to the chromecast so that it continues playing on the chromecast instead.
- It then does `.setPrimary('chromecast');`

On session stop:

- Currently the state is only transferred back to the primary player manually on the episode page.
- CastPlayerController does `.unclaimPrimary()` which sets the previous primary player to be primary again. A random native PlayerController will be chosen if there was no previous primary, for example if the app was launched while a session was active.

## Data transfer between flutter, native and chromecast

This table outlines where metadata is stored during its journey up and down the stack.

| Flutter                          | iOS                                                       | Android                                                      | Chromecast                                       |
| -------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------ |
| MediaItem.Metadata.Extras["KEY"] | PlayerItem.externalMetadata["media.bcc.extras.**KEY**")   | MediaItem.MediaMetadata.Extras["media.bcc.extras.**KEY**"]   | mediaInfo.metadata["media.bcc.extras.**KEY**"]   |
| MediaItem.isLive                 | PlayerItem.externalMetadata["media.bcc.player.is_live"]   | MediaItem.MediaMetadata.Extras["media.bcc.player.is_live"]   | mediaInfo.metadata["media.bcc.player.is_live"]   |
| MediaItem.mimeType               | PlayerItem.externalMetadata["media.bcc.player.mime_type"] | MediaItem.MediaMetadata.Extras["media.bcc.player.mime_type"] | mediaInfo.metadata["media.bcc.player.mime_type"] |

# Idea dump

- Move chromecast logic to a standalone package? We could set it as primary via listeners on the flutter-side. Would it simplify? Probably not. It would maintain its own custom "MediaItem" types, so we would have to do some extra mapping. The native side would have to have to import it as a plugin which could be annoying. If we want to enable usage of the castplayer without hijacking primaryplayer etc, then it would make more sense to just add a configuration flag to disable that feature.
