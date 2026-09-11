# Web

Web support works, but it is not the same player as iOS and Android, and the
differences are worth knowing before you build against it.

## Setup

The host page must load [`bccm-video-player`](https://www.npmjs.com/package/bccm-video-player)
and expose it as `window.bccmVideoPlayer` — see step 4 of [Installation](index.md).
Without it, players are created but never play.

## The player draws its own controls

On iOS and Android the plugin draws Flutter controls over the video. On web the
underlying player draws its own, and **`BccmPlayerViewConfig.controlsConfig` —
including `customBuilder` — does not apply**.

This is deliberate. The video is a real DOM element, and it can only live in one
place at a time: drawing Flutter controls above it means hoisting them out of the
normal widget tree, which costs `Material` ancestry, layout and z-ordering. The
player's own skin is web-optimised and localised, so the trade is worth it.

Practically: `BccmPlayerView` and `BccmPlayerView.native` render the same thing
on web.

## Fullscreen

Fullscreen is the browser's, requested on the player element, rather than the
Flutter route used elsewhere. `BccmPlayerViewController.enterFullscreen()` still
works and still resolves when fullscreen ends, so calling code does not need to
change — but the fullscreen UI is the player's.

Pushing a Flutter route for it would rebuild the platform view and detach the
video from its source.

## Not available

- **Downloads.** No web equivalent, so `DownloaderInterface` reads empty and
  `startDownload` throws `UnsupportedError`.
- **Chromecast.** The cast APIs are no-ops.
- **Picture in picture**, video textures, and `setMixWithOthers`.

## Known limitation: clipping

The video is painted from Flutter's root `Overlay` rather than inline, which is
what keeps it from being re-parented — re-parenting costs the media element its
source and the video reloads. The cost is that it is **not clipped by ancestor
scroll views**: a player scrolled past its viewport paints over whatever is
beside it.

If that matters more than reload-free scrolling for your layout, open an issue —
the trade is a small, contained change.

### What this rules out

Layouts that crop the video by clipping it. The common shape is an `OverflowBox`
sized past the frame inside a `ClipRect`, used to cover-crop a landscape stream
into a vertical one — a short-form/"shorts" feed being the usual case. On web the
clip does not apply, so the video paints at its overflowed size across the page.

The same layouts usually draw their own UI over the video, which the overlay also
paints above, and run several preloaded players at once, all of which would be
visible rather than hidden off-screen.

Feed-style playback is therefore not supported on web. A single player in a page
is what this is built for.

## Track selection

`getPlayerTracks` returns the available audio and subtitle tracks, and
`setSelectedTrack` switches them, but tracks are reported with
`isSelected: false` because the underlying API exposes the lists without saying
which is current. Use the player's own picker unless you are tracking selection
yourself.
