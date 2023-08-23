### Contributing - Getting started

Thank you for wanting to contribute. Here's a few details on how to get started.

1. Clone the repo locally.
2. In a terminal, run `dart run build_runner --watch` and keep it open while developing.

# Pigeons

Pigeon is used to generate type-safe code for communicating between flutter and the native host (iOS/Android).
Pigeon doesn't use build_runner, so the commands below need to be re-run whenever you change the dart pigeon files.

```sh
# When you change playback_platform_pigeon.dart, run:
dart run pigeon --input pigeons/playback_platform_pigeon.dart

# When you change chromecast_pigeon.dart, run:
dart run pigeon --input pigeons/chromecast_pigeon.dart
```
