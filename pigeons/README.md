# Pigeons

Pigeon is used to generate type-safe code for communicating between flutter and iOS/Android.
Pigeon doesn't use build_runner, so the commands below need to be re-run whenever you change the dart pigeon files.

```sh

# When you change playback_platform_pigeon.dart, run:
dart run pigeon --input pigeons/playback_platform_pigeon.dart

# When you change chromecast_pigeon.dart, run:
dart run pigeon --input pigeons/chromecast_pigeon.dart

# When you change downloader_pigeon.dart, run:
dart run pigeon --input pigeons/downloader_pigeon.dart

```
