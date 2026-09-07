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

#### Running tests

The Dart suite lives in `test/` and runs on every PR via `.github/workflows/test.yml`:

```sh
flutter test

# Warnings and errors are fatal; the package still carries some pre-existing
# deprecation infos, hence the flag. This is what CI runs.
flutter analyze --no-fatal-infos
```

There are also Kotlin unit tests (Robolectric) under `android/src/test/`. They need the
Flutter-generated Gradle project, so they run from the example app rather than from
`android/` directly:

```sh
cd example/android && ./gradlew :bccm_player:testDebugUnitTest
```

These are not in CI yet — run them by hand if you touch `ExoPlayerController` or the
player-view lifecycle. iOS has no test target.

When adding tests, note two things that will bite you otherwise:

- `MediaItem` and `Track` are generated pigeon classes with no `==`/`hashCode`, so they
  compare by identity. Assert on `id`/`url`, not on whole objects.
- `PlayerStateNotifier`'s constructor starts a periodic timer. Call `dispose(force: true)`
  or run inside `fakeAsync`, or the test fails on a pending timer.
