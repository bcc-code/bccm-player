# Making bccm_player work for audio as well as video

Status: proposal / analysis. Nothing here is implemented yet.

## Background

bccm_player was built for video-heavy apps (BCC Media, Bible Kids, Live by BCC Connect) and does that well. "Play by BCC Media" replaces the audio app (BMM) with a combined audio and video app, so this package now has to serve a Spotify-like audio experience alongside the existing video experience.

Two things make this more than "add an audio mode":

1. **The queue is the centre of an audio experience**, and the current queue is a Dart-side afterthought over a single-item native player (section 1).
2. **Audio and video are not separate modes.** Content that has video lets the user turn the picture on and off at will, mid-playback. There is no "audio app" to switch into — video is a runtime, per-player toggle over the same stream. bcc-media-play and bcc-connect-live have both already shipped a version of this, entirely at the app layer, working around the package (section 3). This rules out the obvious "give audio its own code path" designs, so section 3 is worth reading before section 1.

**Scope note:** Play replaces BMM rather than integrating with it. The BMM app and its MP3 backend (`bmm-api`) are being retired, and Play uses the BCC Media platform for all content, audio included. So everything here assumes HLS. Progressive MP3 playback, progressive offline download, and MP3 gapless/seeking quirks are explicitly **not** in scope — they were considered and removed from this document. The dependency runs the other way: the BMM catalogue needs to exist in the platform as HLS before Play can replace BMM, but that is a content-migration concern, not a player one.

This document lists what stands in the way, ordered roughly by how much it matters, and ends with a suggested sequencing. Line references are to the state of the repos at the time of writing: this package, plus `bcc-media-play/flutter` and `bcc-connect-live/flutter` for the app-side behaviour and `bcc-media-platform` for the manifest and CDN behaviour.

Section 0 is different in kind from the rest: it is a suspected **live defect** in production today, written to be lifted into its own ticket. It is first because it is cheap to test and because it gates part of the work below, not because it is part of the design.

---

## 0. Suspected live defect: audio language selection in audio-only mode

**This section is a defect report, not a design proposal. It is written to be liftable into its own ticket, and everything else in this document is sequenced behind it.** If it is real it affects the entire audio catalogue — the thing Play exists to serve — today, in production, with no new code shipped.

Play appends `&audio-only=true` for exactly the content whose `primaryMediaType == audio` (`bcc-media-play/flutter/lib/features/player/playback_service.dart:98`, `:115`). So the audio catalogue always goes through the CDN lambda's audio-only branch (`bcc-media-platform/infra/vod-cdn/lambda-js/index.js:107`). That branch:

1. skips **every** `#EXT-X-STREAM-INF` in the master (`skipNextLine = true`), and
2. emits one hardcoded replacement: `BANDWIDTH=128000,CODECS="mp4a.40.2",AUDIO="audio_0"`, whose URI is the rendition marked `DEFAULT=YES`.

The `#EXT-X-MEDIA:TYPE=AUDIO` rendition lines themselves survive the transformation (they fall through to the generic `elem.startsWith("#")` signing branch), so the full language group is still declared in the output manifest. That is what makes the outcome genuinely ambiguous rather than obviously broken.

Two consequences follow if audio-primary manifests are packaged like the video ones (per-language `EXT-X-MEDIA` renditions, which is the same packaging pipeline):

> **Language may be pinned to the default.** The emitted variant declares `AUDIO="audio_0"` _and_ carries a URI pointing at the `DEFAULT=YES` playlist — Norwegian in the sample manifest. Conventionally an audio-only variant does one or the other, and the HLS spec does not pin down how a player should resolve a variant that both references a rendition group and supplies its own audio. AVPlayer and ExoPlayer may well disagree. A German-preferring user may get Norwegian regardless of `preferredAudioLanguages`, and may get it on only one of the two platforms.
>
> **Audio bitrate variants, if any, are collapsed to one.** All `#EXT-X-STREAM-INF` lines are discarded, so any multi-rung audio ladder is replaced by a single hardcoded 128 kbps entry.

This is reasoning from the lambda source, not an observed failure. Nobody has run it against an audio-primary master playlist yet. The test is cheap:

1. Set the app language to German, play an audio-primary episode in Play, check which language you get. Repeat on both iOS and Android — they may differ.
2. Fetch the same stream URL with and without `?audio-only=true` and diff the masters.

There is no test coverage on this transformation to have caught it — `lambda-js-test/index.test.js` covers only `stripSignatureParams`.

**Why this gates the rest.** Step 2 of the sequencing ORs the user's audio-only preference into the URL parameter. That routes *video* content in audio mode through this same branch. If the language pinning is real, shipping step 2 first extends a bug that today only affects the audio catalogue to every user with the toggle on. Resolve this first, or ship step 2 with the language explicitly forced client-side.

Unrelated but noticed while reading the same function: the lambda drops `#EXT-X-I-FRAME-STREAM-INF` with the comment `// Debug. Remove I-Frame playlists`, which kills trick-play and scrub thumbnails. "Debug" suggests it was not meant to ship.

---

## 1. The core problem: the queue lives in Dart, the native players hold one item

`PlayerController.replaceCurrentMediaItem` ([`players/PlayerController.kt:124`](../../android/src/main/kotlin/media/bcc/bccm_player/players/PlayerController.kt)) calls `player.setMediaItem(...)`, and iOS ([`AVQueuePlayerController.swift:597`](../../ios/Classes/Players/AVQueuePlayerController.swift)) does `removeAllItems()` followed by `replaceCurrentItem(with:)`. So despite the class being named `AVQueuePlayer`, the native timeline is always length 1.

Every track transition is a round trip through Dart:

```
native STATE_ENDED / AVPlayerItemDidPlayToEndTime
  → QueueManagerPigeon.handlePlaybackEnded   (PlayerController.kt:483)
  → DefaultQueueManager                      (default_queue_controller.dart:83)
  → replaceCurrentMediaItem                  (→ prepare → buffer from zero)
```

For video this is invisible — a track change is a deliberate, full-screen load anyway. For audio it breaks four things users notice immediately:

1. **Audible gap on every track change.** No preloading, no gapless. ExoPlayer and AVQueuePlayer both buffer the next item ahead when given a real playlist; that is currently thrown away.
2. **Sluggish skip.** Tapping next costs a platform round trip plus a cold buffer.
3. **Playback lifetime is tied to the Flutter engine.** `onDetachedFromEngine → stopIfAttached` ([`BccmPlayerPlugin.kt:250`](../../android/src/main/kotlin/media/bcc/bccm_player/BccmPlayerPlugin.kt)) releases every controller, releases the media session and calls `stopSelf()` ([`PlaybackService.kt:76`](../../android/src/main/kotlin/media/bcc/bccm_player/PlaybackService.kt)). Swipe the task away and audio dies. Audio apps are expected to keep playing.

   **These are two separate fixes, and only the second needs the native queue.** Keeping the *current* track playing past swipe-away is a self-contained lifecycle change in `stopIfAttached` — the foreground service and media session already exist; the method just tears them down unconditionally. Continuing to the *next* track without a Flutter engine is what requires the queue to live natively, because the transition currently round-trips through Dart. The first is a cheap early win and is sequenced as such (step 2b); the second lands with the native queue move.
4. **The system never sees a queue.** `MediaSession.Builder(this, it.player)` ([`PlaybackService.kt:44`](../../android/src/main/kotlin/media/bcc/bccm_player/PlaybackService.kt)) gets a single-item timeline, so Android Auto, Wear OS and Bluetooth head units cannot show or navigate the queue. `BccmForwardingPlayer.hasNextMediaItem` is hardcoded `true` ([`BccmForwardingPlayer.kt:92`](../../android/src/main/kotlin/media/bcc/bccm_player/players/exoplayer/BccmForwardingPlayer.kt)) and iOS enables `nextTrackCommand`/`previousTrackCommand` unconditionally (`AVQueuePlayerController.swift:445`), so the lock screen shows skip buttons that dead-end at the end of the queue.

### Recommendation

Move the queue into the native players and keep the Dart `QueueManager` as a thin façade over it.

- **Android:** `player.setMediaItems(...)` / `addMediaItems` / `moveMediaItem` on the ExoPlayer timeline, and drop the `playNext`/`playPrevious` overrides in `BccmForwardingPlayer` so media3's own `seekToNext`/`seekToPrevious` and command availability work.
- **iOS:** `insert(_:after:)` / `remove(_:)` on the real `AVQueuePlayer`.
- **Contract:** queue mutations become one-way Dart→native calls; queue _state_ flows back as a new pigeon event (`onQueueChanged`) that the Dart notifier mirrors for UI.

Note: [`ios/Classes/MediaQueueController.swift`](../../ios/Classes/MediaQueueController.swift) already contains a complete Swift `QueueManager` (queue / nextUp / history / shuffle, `@Published` change flow) that is **never instantiated anywhere**. This move was started and abandoned. Either finish it or delete the file — as it stands it is a trap for the next reader.

This is the expensive item, and the long pole — see the sequencing note in section 5 about starting it in parallel rather than last. Everything in sections 2 and 3 is independently shippable; the native move is what buys gapless playback, fast skip, a real system queue, and queue advancement without a Flutter engine.

---

## 2. Queue model and API gaps

Bugs in the current `DefaultQueueManager` ([`lib/src/queue/default_queue_controller.dart`](../../lib/src/queue/default_queue_controller.dart)), worth fixing regardless of where the queue ends up living:

- **Shuffle resurrects played tracks.** `ShuffleQueueList._orderedItems` (line 194) is only written by `setItems`. `consumeNext` is inherited from `QueueList` and touches only `itemsNotifier`, so toggling shuffle off replays the whole original list from the top. Shuffle also does not pin the current item to the front, which is standard behaviour in audio apps.
- **`handlePlaybackEnded` does not record history** (lines 83–89). It takes `mediaItem` and ignores it. `skipToNext` _does_ push to history (line 61), so after a track ends naturally you cannot skip back to it. Inconsistent.
- **No repeat-all.** `RepeatMode` is `{off, one}` ([`pigeons/playback_platform_pigeon.dart:148`](../../pigeons/playback_platform_pigeon.dart)). Repeat-queue is table stakes for audio, and is impossible today because repeat is handled natively while the queue is in Dart.
- **`skipToPrevious` has the wrong semantics for audio.** It always jumps to the previous item, and no-ops when history is empty. Expected: restart the current track if position > ~3s, otherwise go back.
- **No way to play a specific queue item.** `consumeSpecific` exists on `QueueList` (line 184) but is not on the `QueueManager` interface, so tapping row 5 of a queue UI requires clear + re-set.
- **No current item in the queue model.** The current track only exists in `PlayerState`, so a "current + upcoming, current highlighted" list has to be assembled by every consumer.
- **`moveQueueItem` throws on stale indices** (`removeAt`/`insert`, line 168) — easy to hit from a `ReorderableListView` racing a queue update. Needs bounds checks, and it cannot move items between `queue` and `nextUp`.
- **`setNextUp` mutates the caller's list in place** (lines 98–103).
- **Casting silently loses the queue.** `swapPlayerNotifier` ([`player_controller.dart:375`](../../lib/src/state/player_controller.dart)) points the controller at a different `PlayerStateNotifier`, which owns a _different_ `DefaultQueueManager`. Android's cast `transferState` ([`CastPlayerController.kt:170`](../../android/src/main/kotlin/media/bcc/bccm_player/players/chromecast/CastPlayerController.kt)) copies the previous player's timeline — which is one item.
- **No persistence.** Audio users expect the queue and position to survive an app restart.

Additions worth making to the interface: `playAt(index)` / `playItem(id)`, `addNext(item)` vs `addLast(item)`, `insertAll`, a max-length guard, and a combined `List<QueueEntry>` view with the current index.

The whole thing is pure Dart and trivially unit-testable. `test/` currently only has `controller_test.dart`, so this is a good place to add real coverage _before_ refactoring.

**Scope the tests to the interface, not the internals.** `QueueList` and `ShuffleQueueList` are implementation detail that moves native in section 1; tests written against them get deleted at that point. Tests written against the `QueueManager` contract survive the move and are what make it safe.

**Note the breaking change.** `QueueManager` is an exported abstract class in a published package, so adding methods to it breaks any consumer with its own implementation. Either add them with defaults on a mixin / base class, or take the major version bump deliberately.

### Resume, and failure while playing

Two things that are barely a concern for video and are headline features for audio. Neither is really a queue concern, but they are adjacent enough to get lost between sections.

- **Resume position across app kill.** Not the same as "persist the queue". A user who was 40 minutes into a two-hour talk expects to reopen the app and be 40 minutes in, and expects the lock screen to offer it before they have navigated anywhere. `playbackStartPositionMs` already exists on `MediaItem`, so the plumbing is there; what is missing is anyone writing the position down periodically and restoring it on cold start. Decide whether that lives in the package or in the apps — it is arguably app-level, but every consuming app will otherwise reimplement it.
- **Error and retry policy.** There is none today: a failed load or a mid-playback network drop surfaces as an error state and stops. For a 20-second video clip that is survivable. For a 90-minute audiobook on a train it is the single most common complaint an audio app gets. ExoPlayer has `setErrorHandlingPolicy` / `Player.prepare()`-after-error; AVPlayer needs an explicit observer on `AVPlayerItem.status` and a reload at the last known position. Wants a bounded exponential backoff and a "waiting for connection" state distinct from "buffering", so the UI can say which.

---

## 3. Video is a runtime toggle, not a content mode

**This is the design constraint that shapes most of the rest of this document.** Play does not have an "audio app" and a "video app" mode. Content that _has_ video lets the user turn the picture on and off at will, mid-playback.

### Scope: two content shapes

| Shape                                               | Delivery                                                 | Toggle applies?                   |
| --------------------------------------------------- | -------------------------------------------------------- | --------------------------------- |
| Video content                                       | HLS, 6-rung video ladder, `?audio-only=true` available   | **Yes** — this is the toggle case |
| Audio-primary content (`primaryMediaType == audio`) | HLS, audio-primary — `Stream.type` is still `hls`/`dash` | No — no video to hide             |

`primaryMediaType` and `StreamType` are orthogonal in the platform schema (`backend/graph/api/schema/episodes.graphqls:105`, `:117`), so "audio-primary" does not mean "not HLS". Both shapes are HLS through the same CDN and the same lambda — which matters for the bug hypothesis below, because the audio catalogue goes through the more surprising code path.

### How this works today

bcc-media-play and bcc-connect-live have both already shipped a version of this, and they agree on the model. There are two distinct concepts, and the apps keep them properly separate — the package just doesn't know about either of them.

**1. The content is inherently audio** (no video exists). Decided when the media item is built, from the GraphQL stream:

```dart
// bcc-media-play  lib/features/player/playback_service.dart:98
final isAudioOnly = episode.streams.any((s) => s.primaryMediaType == Enum$PrimaryMediaType.audio);
// ...:115
url: '${stream.url}&audio-only=$isAudioOnly',
// ...:128
'context.audioOnly': isAudioOnly.toString(),
```

So there is **already a backend mechanism**: an `&audio-only=true` query parameter that makes the platform serve an audio manifest. Real bytes saved, done properly. It is also what hides the toggle — `_isAudioOnlyEpisode` gates the `AudioOnlyToggle` out of the UI entirely (`lib/screens/player.dart:212`), which is correct: there is nothing to toggle.

**2. The user hid the video.** A `SharedPreferences`-backed bool, identical in both apps (`lib/features/player/audio_only_provider.dart`, `lib/features/livestream/audio_only_provider.dart`). When it is on, the app **unmounts `VideoPlatformView` from the widget tree** and renders artwork instead (`inline_player_mobile.dart:85`, `inline_live_player_mobile.dart:71`), and hides the fullscreen button.

### The important consequence: the 6-second heuristics are load-bearing

The user toggle **does not change the stream at all.** It removes the video widget, and then the package's view-attachment heuristic notices and reduces bitrate:

- iOS `updateAutomaticAudioOnlyTimer` (`AVQueuePlayerController.swift:41`) → `setAudioOnlyMode(true)` 6s after the view detaches → `preferredPeakBitRate = 1` ([`PeakBitrateController.swift:34`](../../ios/Classes/Utils/PeakBitrateController.swift)).
- Android `currentPlayerView` setter ([`ExoPlayerController.kt:80`](../../android/src/main/kotlin/media/bcc/bccm_player/players/exoplayer/ExoPlayerController.kt)) → `setForceLowestVideoBitrate(true)` 6s after the view detaches.

**These heuristics look like vestigial hacks but are not: they are the current implementation of the audio-only toggle's bandwidth saving.** Removing them without a wired-up replacement would regress data usage in two shipping apps. They still need to go, but as a swap, in the same change.

(One caveat on the iOS timer: it no-ops for `BufferMode.fastStartShortForm`, so shortform content never gets the reduction at all.)

They are, however, genuinely the wrong mechanism, in four ways:

1. **The signal is indirect.** "No player view is attached" is not "the user wants audio". It also fires on navigation, backgrounding, and any screen that happens not to mount a player — and it _fails_ to fire when the user has video off but some other screen does mount a view.
2. **Six seconds of full-bitrate video** after every toggle-off, on a metered connection.
3. **They save far less than "audio only" implies — on both platforms.** See the next section: the video manifest has no audio-only rendition, so the best either heuristic can do is select the lowest _video_ variant. Video bytes keep flowing for as long as playback continues.
4. **`allowsVideoFrameAnalysis`, PiP and fullscreen** are all decided elsewhere, so the "am I really playing video right now" answer is spread across the app, the view tree, and two native timers with no single source of truth.

### Today: the video ladder has no audio-only rendition

The regular video manifest contains no audio-only variant. The only way to get audio-only is `?audio-only=true`, which the CDN lambda rewrites in flight.

That has two consequences worth stating plainly, because the code reads better than it behaves:

- **Client-side variant selection cannot reach audio.** Both `setTrackTypeDisabled(TRACK_TYPE_VIDEO)` on Android and `preferredPeakBitRate` on iOS choose from what is in the ladder. With no audio rendition there, the ceiling is the lowest video variant.
- **So the current toggle saves far less than it looks like, on both platforms.** iOS's `preferredPeakBitRate = 1` reads like "audio only" but just selects the bottom rung. Looking at the ladder in `master_input.m3u8`, the saving is 5.59 Mbps → 378 kbps, not 5.59 Mbps → ~128 kbps audio. Real, but roughly 3× short of what the name implies. Anyone estimating data usage from the code alone will get this wrong.

Audio-only is therefore a **URL-level** switch today, and flipping it means `replaceCurrentMediaItem` → re-`prepare` → rebuffer. Which is why it is only used for content that is inherently audio, and never for the toggle.

### Adding an audio-only rendition is much cheaper than it sounds

Worth checking before accepting the constraint above, because the platform is already 95% of the way there.

**Audio is already fully demuxed.** From `bcc-media-platform/backend/cmd/stream-proxy/testdata/master_input.m3u8`:

```
#EXT-X-STREAM-INF:BANDWIDTH=378651,RESOLUTION=320x180,CODECS="avc1.64000D,mp4a.40.2",AUDIO="audio_0"
... 6 video rungs, 378 kbps → 5.59 Mbps ...
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio_0",LANGUAGE="nor",DEFAULT=YES,URI="...index_8_0.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio_0",LANGUAGE="deu",...
... ~20 languages, each its own media playlist ...
```

Every audio rendition already exists as its own playlist object. An audio-only variant is a couple of lines in the master pointing at playlists that are already there — no re-encoding, no new storage, no packaging work.

**And the lambda already builds one.** `bcc-media-platform/infra/vod-cdn/lambda-js/index.js:111`:

```js
body.push(
  '#EXT-X-STREAM-INF:BANDWIDTH=128000,CODECS="mp4a.40.2",AUDIO="audio_0"',
);
// ...finds the DEFAULT=YES audio URI...
body.push(signed(dir, defaultAudioUri || "", encodedPolicy));
```

The rendition exists. The lambda **replaces** the video variants with it (`skipNextLine = true` swallows each video variant's URI) rather than **appending** it alongside them. So "add an audio-only rendition to the ladder" is not a packaging project — it is changing that branch from replace to append, gated on a new query parameter.

For context: this is the standard HLS pattern, not an exotic one. An audio-only rendition was a hard App Store requirement for cellular streaming for years and is still in Apple's HLS Authoring Spec; Apple's own reference streams carry one. Not having one is the unusual configuration, and here it is almost certainly just an encoder profile that was never asked to emit it.

**Gate it on a query parameter rather than adding it everywhere.** Suggested shape: `?audio-only=true` unchanged, default unchanged, and a new `?audio-fallback=true` that appends the audio variant to the full ladder. Play opts in; BCC Media, Bible Kids and connect-live keep exactly today's behaviour. That matters because of the next point.

**The ABR risk, and why it is asymmetric.** With the audio variant in the ladder, a player under congestion may select it and the picture disappears. For a video-first product that often reads worse than a stall.

- **Android:** controllable. `setMinVideoSize` / `setMinVideoBitrate` on `TrackSelectionParameters` floors it while the user wants video.
- **iOS:** not controllable. `preferredPeakBitRate` is a maximum only; there is no minimum-bitrate API. You cannot stop AVPlayer dropping to audio-only under pressure.

Query-param gating keeps BCC Media, Bible Kids and connect-live at exactly today's behaviour — but note what it does **not** do. It confines the risk to Play, which is precisely the app that has both video content and the toggle. A Play iOS user watching video on a congested connection can have the picture silently vanish. Gating is not a mitigation for that; it only protects the other apps.

So on iOS the seamless-toggle benefit and the picture-disappears risk are the same mechanism, and the trade has to be made deliberately. Options, roughly in order of preference:

1. **Ship variant selection on Android, keep the reload path on iOS.** Android gets both benefits safely; iOS keeps today's (worse but predictable) behaviour. Least risk, and the `setVideoEnabled` API shape already accommodates it — this is exactly the "report which path it took" case.
2. **Ship both and detect the drop.** Observe `AVPlayerItem.presentationSize` going to zero (or the `accessLog` event's `indicatedBitrate` landing on the audio rung) while `videoEnabled` is true, and reload without `?audio-fallback=true`. Recoverable, but a visible glitch and non-trivial to get right.
3. **Accept and monitor.** Ship it, add an NPAW dimension for "video variant lost while video enabled", and revisit if it shows up in the field.

This should be an explicit decision before the ladder change lands, not something discovered after.

### Cross-reference: the audio-only branch is suspect (section 0)

Because the audio catalogue always carries `?audio-only=true`, it always goes through the CDN lambda's audio-only branch — which is suspected of pinning audio language to the packaged default. Written up separately in [section 0](#0-suspected-live-defect-audio-language-selection-in-audio-only-mode), because it is a live defect report rather than a design decision and should be tracked as its own ticket.

It matters here for one reason: the build-time fix below routes **video content in audio mode** through that same branch, so it inherits the bug if the bug is real. Section 0 gates the recommendation below.

### A second thing the 6-second heuristic does to audio content

For audio-primary content there is never a video view attached, so `updateAutomaticAudioOnlyTimer` (`AVQueuePlayerController.swift:41`) always fires and sets `preferredPeakBitRate = 1` — permanently, for every audio session on iOS.

If audio-primary manifests carry more than one audio rung, that silently pins every audio session to the lowest. For a music and worship catalogue that is a quality regression nobody would think to look for. It interacts with section 0: whether it matters at all depends on whether the lambda already collapsed the ladder to a single variant, so the same test answers both. Either way the fix is the one this section argues for throughout — drive it from explicit state (`hasVideo`) instead of view attachment.

### The recommendation

**Ship the build-time fix first; pursue the ladder change in parallel.** They are independent and the first is nearly free — but see the gate in section 0 before shipping it.

**1. Apply the persisted preference at media-item build time.** `isAudioOnly` in `playback_service.dart:98` is derived _only_ from content type; the user's preference never reaches the URL:

```dart
// today
final isAudioOnly = episode.streams.any((s) => s.primaryMediaType == Enum$PrimaryMediaType.audio);
// wanted
final contentIsAudioOnly = episode.streams.any((s) => s.primaryMediaType == Enum$PrimaryMediaType.audio);
final useAudioOnlyStream = contentIsAudioOnly || ref.read(audioOnlyProvider);
```

Because the preference is already persisted, most sessions start in the mode the user wants — and applying it at build time makes those sessions genuinely audio-only, at full effect, from the first segment, with no seam and no native or platform change. This is where most of the real bandwidth saving lives, regardless of what happens with the ladder.

**Two ordering constraints, both hard:**

- `context.audioOnly` currently means both "the stream has no video" and "hide the toggle". OR the preference into it and the toggle hides itself, stranding the user. Split the fields first (see _State and API shape_).
- This change sends video content through the lambda's audio-only branch, which today only ever sees the audio catalogue. If section 0's language pinning is real, this spreads it to every user with the toggle on. Test section 0 first, and either fix it or force the audio language client-side as part of this change.

**2. Then the ladder change makes mid-playback flips seamless.** With the audio variant present, a flip is variant selection on the live player — no reload, no gap, position untouched. Android via `setTrackTypeDisabled(TRACK_TYPE_VIDEO, …)`, iOS via the `preferredPeakBitRate` path `PeakBitrateController` already implements. This is what makes `setVideoEnabled(bool)` an honest API rather than a wrapper around a reload.

**Design the package API to work either way.** `setVideoEnabled(bool)` as the entry point; internally, variant selection when the stream carries an audio rendition, and a position-preserving `replaceCurrentMediaItem` fallback (using `MediaItem.playbackStartPositionMs`, which already exists) when it does not. Consumers should not have to know which. Where the fallback path is taken, show a loading state over the artwork so it reads as a mode change rather than a stall; for live, position preservation is moot since you rejoin at the edge anyway.

**One open question for the platform team** (also listed in step 0 of the sequencing): does `?audio-only=true` work on **live** manifests, or only VOD? connect-live does not use the parameter at all today, and it is the app most likely to want it.

### The case the URL parameter can never fix

The view-attachment heuristic is doing two different jobs, and only one is replaced by the build-time fix:

1. **Implementing the user's audio-only toggle.** Replaced by the URL parameter (and later by variant selection).
2. **Video content playing with nothing rendering it** — backgrounded, screen off, notification-only playback. The user has not toggled anything, and reloading the stream because someone locked their phone is absurd. Variant selection is the only available lever, so without an audio rendition in the ladder the ceiling is "lowest video variant".

Job 2 is legitimate and should be **kept**, re-expressed as an explicit "no renderer attached" policy rather than a 6-second timer. It is also the second independent argument for the ladder change: in an audio-heavy app, video content playing in the background will be common, and there is no way to make it cheap otherwise.

One Android detail to verify when job 2 gets reworked: the comment on `setForceLowestVideoBitrate` ([`ExoPlayerController.kt:282`](../../android/src/main/kotlin/media/bcc/bccm_player/players/exoplayer/ExoPlayerController.kt)) records that disabling the video _renderer_ did not stop segment downloads ([ExoPlayer#9282](https://github.com/google/ExoPlayer/issues/9282)). `setMaxVideoSize(0, 0)` and `setMaxVideoBitrate` are worth measuring against the current `setForceLowestBitrate`.

### What the apps are working around

Three more things in the app code read as "the package is missing a field":

- **`context.audioOnly` is a stringly-typed extra**, read as `extras['context.audioOnly'] == 'true'` at four separate call sites in play (`screens/player.dart:182`, `screens/tabs.dart:145`, `inline_player_mobile.dart:29`, `floating_mini_player.dart:62`). This is the app hand-rolling the `hasVideo` / `isAudioOnly` field that `MediaItem` should carry.
- **`artist` is overloaded by content kind** — `artist: isAudioOnly ? contributors : episode.season?.$show.title` (`playback_service.dart:120`). Evidence for the audio metadata fields below, not just a style nit.
- **`pauseIfAudioOnlyAndMuted`** in connect-live (`autoplaying_player_provider.dart:63`) pauses playback when audio-only is on and volume is 0, polled on a 5-second timer plus a listener on the toggle. A reasonable policy that the app has to implement by polling because the package offers no hook for it.

### State and API shape

Because audio-only is a URL-level switch, this is mostly about naming three things that are currently one overloaded string. `context.audioOnly` today means "the stream has no video" _and_ "hide the toggle" _and_ implicitly "the user is in audio mode" — and those come apart the moment the user preference feeds into the URL.

- **`MediaItem.hasVideo`** — does this _content_ have video at all? Set when the item is built; the apps already know it from `primaryMediaType`. This is what gates the toggle's visibility, and nothing else should. Resolve against `getTracks().videoTracks` once the manifest loads as a cross-check.
- **`MediaItem.isAudioOnlyStream`** — is the URL currently pointing at the rewritten audio manifest? Distinct from the above: true either because the content has no video, or because the user chose audio. This is what the player and the view stack should read to decide "is there a picture to show".
- **`videoEnabled` on `PlayerState`** as the resolved effective state, fed from the native snapshot so it survives PiP, cast handover, and engine reattach. This does _not_ replace the apps' `audioOnlyProvider` — that stays as the persisted user preference, and it stays in the apps.
- **`setVideoEnabled(bool)`** on the controller / pigeon interface, with the two-path implementation described above: variant selection where the stream carries an audio rendition, position-preserving reload where it does not. Player-level, not item-level. It should also report which path it took, so the UI knows whether to show a loading state — a silent 1.5s stall and a silent instant switch behind the same call is how you get bug reports that cannot be reproduced.
- **Keep preference storage in the apps.** Both already persist it in `SharedPreferences` under `PrefKeys.audioOnly`, and both want their own defaults. The package should take a default via `AppConfig` and otherwise stay out of it.

### Everything gated on video should follow the toggle

- **Fullscreen, PiP, orientation** are meaningless with video off. `enterFullscreen`, `pipOnLeave`, and the `deviceOrientationsFullscreen` callbacks all need to respect `videoEnabled && hasVideo`.
- **Platform view lifecycle.** Both apps mount and unmount `VideoPlatformView` on every toggle, which is currently also how the bitrate heuristic gets triggered. Once the URL carries the mode, unmounting is fine and arguably correct — an audio-only stream has no picture to render, so keeping a hybrid-composition view alive would be pure cost. Keep the unmount; just stop relying on it as the bandwidth signal. (`setPlayerViewVisibility` exists in the pigeon interface for the hide-without-unmount case, but note it is a **no-op on iOS** ([`PlaybackApiImpl.swift:71`](../../ios/Classes/PlaybackApiImpl.swift)) and only emits an event-bus message on Android — don't reach for it expecting it to work.)
- **Cast.** Casting to a TV with video off is almost never what the user wants — and because the mode lives in the URL, the receiver would be handed an audio manifest and show a black screen. Cast handover has to rebuild the media item with `audio-only=false`, then restore the local preference when the session ends. This is now a correctness issue rather than a preference nicety.
- **Downloads.** `DownloadConfig` separates `audioTrackIds` from `videoTrackIds`, but with in-flight rewriting an audio-only download could simply download the `?audio-only=true` URL — likely simpler and smaller. Either way, an audio-only download makes the toggle unsatisfiable offline, so it needs to be disabled (visibly, not silently failing) for items whose local copy has no video.
- **NPAW.** A mid-playback flip is a `replaceCurrentMediaItem`, so NPAW will end the view and start a new one whether or not that is intended — one piece of listening becomes two views, with a rebuffer event between them. Decide whether that is the reporting you want, and if not, carry a dimension marking the flip so the two halves can be stitched. Either way it should be a decision, not something discovered in the dashboards.

### Buffering: the primary player is stuck on one profile

Audio is roughly 1/20th the bitrate of video, so a 2–5 minute audio buffer is nearly free and would kill the rebuffering complaints that dominate transit listening. The two current `BufferMode` profiles top out around 40–50s (`ExoPlayerController.kt:374`).

There is an apparent tension here — deep audio buffers being wasted when the user turns video on. With audio-only being a URL switch, that mostly dissolves: a mid-playback flip reloads and discards the buffer anyway, so there is nothing to protect.

The real obstacle is narrower and worse. `LoadControl` is fixed at player construction (`ExoPlayerController.kt:67`), and **the primary player is hardcoded to `BufferMode.STANDARD`** — `PlaybackService.kt:43` and `:180` on Android, with iOS defaulting the same way in `PlaybackApiImpl.swift:102`. The primary player is the one that handles background playback, the queue, and cast handover, i.e. every audio session that matters. It can never be given a deeper buffer today, no matter what the media item is.

So the options are:

- **Let the primary player's buffer profile be set after construction**, which for ExoPlayer means a custom `LoadControl` wrapping `DefaultLoadControl` and reading a mutable target. Not a nice-to-have — it is the only way to reach the primary player at all.
- **Recreate the primary player** when the profile needs to change. Cheaper to write, but the primary player is deliberately long-lived (it owns the media session and the notification), so this trades a real architectural property for a buffer setting. Not recommended.

Either way, "just add an audio `BufferMode`" is not sufficient, which is worth knowing before it gets estimated as a one-line enum addition.

### Still worth doing regardless of the toggle

- **`MediaMetadata` needs audio fields:** `album`, `albumArtist`, `trackNumber`, `genre`, `description`, `mediaType`. Android Auto specifically needs media3's `setMediaType(MEDIA_TYPE_MUSIC)`, `setAlbumTitle` and `setIsPlayable` to render correctly.
- **Content-kind-driven transport controls.** Podcasts and audiobooks want ±15/30s seek; music wants prev/next. This tracks the _kind of content_, not the video toggle — a video podcast still wants ±30s. Today `BccmForwardingPlayer.getAvailableCommands` advertises both unconditionally, and the iOS command center registers both plus `seekForwardCommand` with a hardcoded 10s (`AVQueuePlayerController.swift:461` — registered without a matching `seekBackwardCommand`).
- **Separate playback-speed memory per content kind.** Speed is currently global and sticky across items. A podcast listener at 1.5x does not want their next music video at 1.5x.
- **iOS 17 `audiovisualBackgroundPlaybackPolicy`.** For items that have video, set this explicitly to `.continuesIfPossible` on the `AVPlayerItem`. The default can pause video-bearing items when backgrounded — precisely the wrong behaviour for a video podcast the user is listening to with the screen off.

---

## 4. Audio features that are missing entirely

- **Sleep timer**, with fade-out and an "end of episode" mode.
- **Skip silence** — `ExoPlayer.setSkipSilenceEnabled`. Very popular for podcasts. No iOS equivalent, so Android-only is acceptable.
- **Chapters / markers** for podcasts and audiobooks, including surfacing them to the lock screen and Android Auto.
- **iOS interruption and route-change handling.** The only `AVAudioSession` work in the package is `setCategory(.playback)` + `setActive(true)` ([`PlaybackApiImpl.swift:247`](../../ios/Classes/PlaybackApiImpl.swift)). There is no `interruptionNotification` observer, so after a phone call playback stays paused instead of resuming, and no `routeChangeNotification` handling. Tolerable for video; a daily annoyance for audio.
- **Richer now-playing info on iOS.** `updateNowPlayingBaseInfo` (`AVQueuePlayerController.swift:740`) sets only artist / title / artwork. Missing `MPMediaItemPropertyAlbumTitle`, `MPNowPlayingInfoPropertyIsLiveStream`, and `MPNowPlayingInfoPropertyPlaybackQueueIndex`/`Count` — the last two are what render "3 of 12" on the lock screen and in CarPlay. It also writes via `npic.nowPlayingInfo?[...]`, which silently no-ops if the dictionary is nil.
- **Artwork loading is naive.** `addArtworkAsync` (`AVQueuePlayerController.swift:864`) does a blocking `Data(contentsOf: url)` per item, uncached and unresized. Video changes artwork rarely; an audio queue changes it every few minutes. Add a small LRU cache and downscale before handing it to `MPMediaItemArtwork`.
- **CarPlay / Android Auto browsing.** Neither exists today (no `MediaLibraryService`, no CarPlay scene). Bigger than the rest, but the thing audio users ask about most after gapless. **The scope decision belongs in step 0 of the sequencing, not here:** Android Auto wants a `MediaLibraryService` rather than a plain `MediaSessionService`, so deciding late means rebuilding the native queue on a different base class.

---

## 5. Suggested sequencing

Two things shape this ordering beyond "cheap things first".

**The native queue move (step 6) is the long pole, and it has a decision in front of it.** The real dependency chain is: Android Auto / CarPlay scope decision → native queue → cast-with-queue. Gapless playback, fast skip, a real system queue and next-track-survives-swipe-away are baseline expectations for an app replacing BMM, not polish. So the Auto/CarPlay call gets made in step 0 with the other decisions, and the native-queue work starts in parallel with the app- and platform-side work rather than queueing behind all of it. Steps 1–4 touch the apps, the CDN lambda and the Dart layer; step 6 touches the native players. They do not contend.

**Step 0 gates step 2.** Not just "do it first" — step 2 routes video content in audio mode through the same suspect lambda branch, so it inherits the defect if the defect is real.

### Decide first (days, not weeks)

0. **Three decisions, up front.**
   - **Test the audio-only language bug** (section 0). Set the app language to German, play an audio-primary episode in Play on both platforms, see which language you get; then fetch one audio-primary stream URL with and without `?audio-only=true` and diff the masters. An hour of work, needs no decisions from anyone, and **blocks step 2**.
   - **Ask the platform team:** does `?audio-only=true` work on **live** manifests, or only VOD? connect-live does not use the parameter today and is the app most likely to want it. Not blocking, but the answer changes what step 4 has to cover.
   - **Decide whether Android Auto / CarPlay are in scope.** This must be settled now, not at the end: Auto wants a `MediaLibraryService` rather than a plain `MediaSessionService`, which changes the base class the native queue is built on. Deciding late means rework of the most expensive item on the list.

### App and platform side (parallel with the native track)

1. **Split the overloaded `context.audioOnly`.** Separate `hasVideo` (gates the toggle) from `isAudioOnlyStream` (gates the picture). Must land before step 2 or the toggle hides itself. `hasVideo` is also what lets the iOS 6-second timer stop firing on audio content.
2. **Apply the persisted preference at build time.** OR the preference into the URL parameter in `playback_service.dart`. Small, app-side, no native work — and where most of the real bandwidth saving lives, since sessions that start in audio mode become genuinely audio-only from the first segment. **Gated on step 0**; if the language bug is real, either fix it first or force the audio language client-side as part of this change.

   2b. **Stop `stopIfAttached` killing playback on engine detach.** Independent of everything else here, and a cheap win: keeps the current track playing past swipe-away without waiting for the native queue (see section 1, point 3). Continuing to the *next* track still needs step 6.

3. **Queue semantics + tests, in Dart.** Fix shuffle, history-on-natural-end, `skipToPrevious`, `moveQueueItem` bounds; add `playAt`/`addNext`/repeat-all to the interface and a combined queue view with current index. Test the **interface**, not `QueueList`/`ShuffleQueueList` — the internals move native in step 6, the contract does not. Locks that contract before the move.
4. **The `?audio-fallback=true` ladder change** in the CDN lambda — append the audio-only variant instead of replacing the video ones, gated on the new parameter so only Play opts in. Small and self-contained (`infra/vod-cdn/lambda-js/index.js`). Add test coverage for the transformation while in there; there is none today. **Make the iOS ABR call before this lands** (section 3) — appending the audio rendition is what exposes Play's iOS users to losing the picture under congestion.
5. **`setVideoEnabled(bool)` + `videoEnabled` in `PlayerState`.** Variant selection where the ladder has an audio rendition, position-preserving reload where it does not, and a way for callers to know which happened. If the iOS decision was "Android-first", this is where the asymmetry lives — same API, different path per platform. Then re-scope the two 6-second heuristics down to job 2 only (no renderer attached) rather than deleting them; they remain the only lever for backgrounded video content. Gate fullscreen/PiP/orientation and cast handover on the new state.

### Native track (starts alongside step 1, not after step 5)

6. **Move the queue native** (Android timeline first, then `AVQueuePlayer`), with the Dart `QueueManager` becoming a façade over an `onQueueChanged` event. Buys gapless, fast skip, correct next/prev availability, a real system queue, and queue advancement that survives swipe-away. Built on whichever service base class step 0 decided. Delete or wire up `MediaQueueController.swift` — as it stands it is a trap for the next reader.
7. **Mutable buffer profile for the primary player** (custom `LoadControl`), so audio sessions can actually get a deep buffer. Independent of everything above; can slot in wherever there is capacity.
8. **Error and retry policy** — bounded backoff, reconnect at last position, a "waiting for connection" state distinct from "buffering" (section 2). Higher user impact than its position here suggests; pull it forward if audio ships before the rest.

### After

9. **Audio metadata fields + content-kind plumbing.** Pigeon change, mostly additive. Unlocks per-kind transport controls, per-kind speed memory, and Android Auto rendering.
10. **iOS audio-session correctness** (interruptions, route changes) + full now-playing info + `audiovisualBackgroundPlaybackPolicy`. Small, high annoyance-reduction.
11. **Resume position across cold start** (section 2), if it is not already handled app-side by then.
12. **Audio features:** sleep timer, skip silence, chapters.
13. **Cast-with-queue**, once the queue is native and transferable. Includes the video-on-cast policy from section 3.
14. **Android Auto / CarPlay implementation**, if step 0 said yes. The scope decision was made at step 0; this is the build-out.
