# TODO

Known gaps, roughly in order of value. Each is self-contained — none blocks the others.

Queue and audio work is tracked separately in [audio-support-plan.md](audio-support-plan.md); this list is everything outside that.

## Migrate the web player off `dart:html`

[`lib/src/web/video_js_player.dart`](../../lib/src/web/video_js_player.dart) is ~120 lines of DOM code on the deprecated `dart:html`. Moving to `package:web` + `dart:js_interop` needs a new dependency, `ui_web.platformViewRegistry` in place of `dart:ui`'s, and a replacement for `NodeTreeSanitizer.trusted`.

Only a real web build can verify it — no Dart test reaches this file. It carries the single inline `// ignore: deprecated_member_use` in the package, so this is the last thing between us and an unqualified strict `flutter analyze`.

## Make `tv_controls.dart` DVR-aware

[`lib/src/widgets/controls/tv/tv_controls.dart`](../../lib/src/widgets/controls/tv/tv_controls.dart) reimplements `useTimeline` inline and ignores `seekableRangeStartMs` / `seekableRangeEndMs` entirely, so seeking a live DVR window is wrong on TV.

Unlike the bug fixed in `default_controls`, it is at least self-consistent — its thumb and its drag agree with each other — so this is a missing feature rather than a mismatch. The fix is to make it call `useTimeline` and `positionFromFraction`, which also removes the duplication.

## Stop the riverpod providers leaking notifiers

[`lib/src/plugins/riverpod/providers/player_provider.dart`](../../lib/src/plugins/riverpod/providers/player_provider.dart) — both `playerProviderFor` and `primaryPlayerProvider` fall back to `PlayerStateNotifier(keepAlive: false)` when the player is absent. That constructor starts a periodic 1 s timer, and a fresh notifier is built on every rebuild, so each one leaks.

## Native tests

The six Robolectric tests in `android/src/test/` still aren't in CI. They need a JDK and the Android SDK, and run through the Flutter-generated Gradle project rather than from `android/` directly:

```sh
cd example/android && ./gradlew :bccm_player:testDebugUnitTest
```

iOS has no test target at all — `ios/bccm_player.podspec` has no `test_spec`.

## Minor

- `lib/src/widgets/utils/bccm_player_plugin_state_builder.dart` is dead code returning `Placeholder()` and isn't exported. Delete it.
- `PlayerPluginStateNotifier._removePlayer` calls `debugPrint` unconditionally — noisy in test output and in release logs.
- `StateNotifierSelectBuilder` compares selections with `!identical` rather than `!=`. Fine for enums, bools and small ints; a `select` that builds a `String` rebuilds on every notification regardless. Pinned by a test today, not a correctness bug.
- `useWakelockWhilePlaying` holds the wakelock in every state except `paused` — including `stopped` and `error`. Needs a product decision, not just a code change.
- The filename `lib/src/utils/use_wakelock_while_palying.dart` is misspelled.
