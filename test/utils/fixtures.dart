import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';

/// Builders for the generated pigeon models.
///
/// **`MediaItem` and `Track` have no `==`/`hashCode`.** They are plain mutable
/// pigeon classes, so they compare by identity. `expect(item, equals(other))`
/// therefore fails for two structurally identical items — assert on `id` / `url`
/// instead, or compare `.map((i) => i.id)` over a list.
///
/// `PlayerState` *is* freezed and has value equality, but it holds a `MediaItem`,
/// so `copyWith(currentMediaItem: equalButDistinctItem)` still counts as a change
/// and still notifies listeners.

MediaItem mediaItem({
  String? id,
  String? url,
  String? title,
  double? durationMs,
  bool? isLive,
  bool? isOffline,
  Map<String?, String?>? extras,
}) {
  return MediaItem(
    id: id,
    url: url ?? 'https://example.test/${id ?? 'item'}.m3u8',
    mimeType: 'application/x-mpegURL',
    isLive: isLive,
    isOffline: isOffline,
    metadata: MediaMetadata(
      title: title ?? id,
      durationMs: durationMs,
      extras: extras,
    ),
  );
}

/// A list of items with sequential ids: `id-1`, `id-2`, ...
List<MediaItem> mediaItems(int count, {String prefix = 'id'}) {
  return List.generate(count, (i) => mediaItem(id: '$prefix-${i + 1}'));
}

PlayerStateSnapshot snapshot({
  String playerId = 'fake-player-1',
  PlaybackState playbackState = PlaybackState.playing,
  bool isBuffering = false,
  bool isFullscreen = false,
  double playbackSpeed = 1.0,
  MediaItem? currentMediaItem,
  double? playbackPositionMs,
  VideoSize? videoSize,
  int? textureId,
  double? volume,
  PlayerError? error,
  double? seekableRangeStartMs,
  double? seekableRangeEndMs,
}) {
  return PlayerStateSnapshot(
    playerId: playerId,
    playbackState: playbackState,
    isBuffering: isBuffering,
    isFullscreen: isFullscreen,
    playbackSpeed: playbackSpeed,
    currentMediaItem: currentMediaItem,
    playbackPositionMs: playbackPositionMs,
    videoSize: videoSize,
    textureId: textureId,
    volume: volume,
    error: error,
    seekableRangeStartMs: seekableRangeStartMs,
    seekableRangeEndMs: seekableRangeEndMs,
  );
}

Track track({
  required String id,
  String? label,
  String? language,
  double? frameRate,
  int? bitrate,
  int? width,
  int? height,
  bool? downloaded,
  bool isSelected = false,
}) {
  return Track(
    id: id,
    label: label,
    language: language,
    frameRate: frameRate,
    bitrate: bitrate,
    width: width,
    height: height,
    downloaded: downloaded,
    isSelected: isSelected,
  );
}

/// Ids of a queue-ish list, for order assertions.
List<String?> idsOf(List<MediaItem> items) => items.map((i) => i.id).toList();
