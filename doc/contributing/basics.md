## Contributing

Thank you for the interest in contributing!
We want to improve the codebase so that it's usable for others too, so we are very open for PRs and issues.
The docs has a page about architecture details to help you understand the codebase.

Before starting on a bigger change it might be a good idea to create an issue about your ideas so that we can help you out and become aligned.

### Getting started

Thank you for wanting to contribute. Here's a few details on how to get started.

1. Clone the repo locally.
2. In a terminal, run `dart run build_runner --watch` and keep it open while developing.

#### Pigeons (Important)

Pigeon is used to generate type-safe code for communicating between flutter and the native host (iOS/Android).
Pigeon doesn't use build_runner, so the commands below need to be re-run whenever you change the dart pigeon files.

```sh
# When you change playback_platform_pigeon.dart, run:
dart run pigeon --input pigeons/playback_platform_pigeon.dart

# When you change chromecast_pigeon.dart, run:
dart run pigeon --input pigeons/chromecast_pigeon.dart
```

You will likely need to add things to the pigeons if you are building new features that require writing native code in swift/kotlin.
