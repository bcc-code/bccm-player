# Plugins

## Riverpod

The riverpod providers are there to simplify usage of the StateNotifiers and event streams. See [./lib/src/plugins/riverpod/providers](./lib/src/plugins/riverpod/providers) to find available providers.

```dart
final String? currentMediaItemEpisodeId = ref.watch(
    primaryPlayerProvider.select(
        (player) => player?.currentMediaItem?.metadata?.extras?['id']?.asOrNull<String>(),
    ),
);

final String? currentMediaItemEpisodeId = ref.watch(
    playerProviderFor(playerId).select(
        (player) => player?.currentMediaItem?.metadata?.extras?['id']?.asOrNull<String>(),
    ),
);
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
        'npaw.isOffline': 'true',
        'npaw.content.type': 'video',
        'npaw.content.customDimension1': 'customDimension1',
        'npaw.content.customDimension2': 'customDimension2',
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
