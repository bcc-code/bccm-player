# TODO

Known gaps, roughly in order of value. Each is self-contained — none blocks the others.

Queue and audio work is tracked separately in [audio-support-plan.md](audio-support-plan.md); this list is everything outside that.

## Make `tv_controls.dart` DVR-aware

[`lib/src/widgets/controls/tv/tv_controls.dart`](../../lib/src/widgets/controls/tv/tv_controls.dart) reimplements `useTimeline` inline and ignores `seekableRangeStartMs` / `seekableRangeEndMs` entirely, so seeking a live DVR window is wrong on TV.

Unlike the bug fixed in `default_controls`, it is at least self-consistent — its thumb and its drag agree with each other — so this is a missing feature rather than a mismatch. The fix is to make it call `useTimeline` and `positionFromFraction`, which also removes the duplication.

## Web

The player is embedded as a platform view hosted in the root overlay
([`web_player_overlay.dart`](../../lib/src/widgets/video/web_player_overlay.dart)),
which is what stops the element being re-parented — re-parenting costs the media
element its source, so the video reloads. Remaining gaps:

- The video is not clipped by ancestor scroll views, so a player scrolled past
  its viewport paints over whatever is beside it.
- `getPlayerTracks` reports `isSelected: false` for every track: the JS package
  exposes track lists but not which one is current. Only matters if an app reads
  tracks from Dart rather than using the player's own picker.
- Web uses the player's own skin rather than the Flutter controls, deliberately —
  see the comment in `controlled_player_view.dart`.

## Minor

- `lib/src/widgets/utils/bccm_player_plugin_state_builder.dart` is dead code returning `Placeholder()` and isn't exported. Delete it.
- `StateNotifierSelectBuilder` compares selections with `!identical` rather than `!=`. Fine for enums, bools and small ints; a `select` that builds a `String` rebuilds on every notification regardless. Pinned by a test today, not a correctness bug.
- `useWakelockWhilePlaying` holds the wakelock in every state except `paused` — including `stopped` and `error`. Needs a product decision, not just a code change.
- The filename `lib/src/utils/use_wakelock_while_palying.dart` is misspelled.
