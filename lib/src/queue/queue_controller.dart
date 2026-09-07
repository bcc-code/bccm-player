import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// Which list an entry in [QueueManager.entries] came from.
enum QueueEntryKind {
  /// The item the player is on right now.
  current,

  /// Explicitly queued by the user; played before [nextUp].
  queue,

  /// The automatic continuation — the rest of the album, show, playlist.
  nextUp,
}

/// One row of the combined [QueueManager.entries] view.
class QueueEntry {
  const QueueEntry({required this.mediaItem, required this.kind});

  final MediaItem mediaItem;
  final QueueEntryKind kind;

  bool get isCurrent => kind == QueueEntryKind.current;
}

/// The queue behind a single player.
///
/// Ordering is: the current item, then everything in [queue] (explicitly queued
/// by the user), then everything in [nextUp] (the automatic continuation).
/// [entries] presents all three as one list, which is what a queue UI wants.
///
/// Not exported from the package barrel — reachable through
/// [BccmPlayerController.queue]. Implementations other than
/// [DefaultQueueManager] are not a supported extension point, which is why
/// methods can be added here without a major version bump.
abstract class QueueManager {
  void dispose();

  Future<void> skipToNext();

  /// Goes back, or restarts the current item.
  ///
  /// Restarts when playback is further than a short threshold into the current
  /// item, matching what every other media player does; only goes back to the
  /// previous item when pressed near the start.
  Future<void> skipToPrevious();

  Future<void> handlePlaybackEnded(MediaItem? current);

  Future<void> setShuffleEnabled(bool enabled);

  /// Replaces [nextUp] wholesale.
  Future<void> setNextUp(List<MediaItem> mediaItems);

  /// Appends to the end of [queue].
  Future<void> addLast(MediaItem mediaItem);

  /// Inserts at the front of [queue], so it plays immediately after the
  /// current item.
  Future<void> addNext(MediaItem mediaItem);

  /// Appends several items to the end of [queue] in one go.
  Future<void> insertAll(List<MediaItem> mediaItems);

  @Deprecated('Renamed to addLast, to pair with addNext. Will be removed in a future release.')
  Future<void> addQueueItem(MediaItem mediaItem);

  Future<void> removeQueueItem(String id);

  Future<void> moveQueueItem(int fromIndex, int toIndex);

  Future<void> clearQueue();

  /// Jumps straight to an upcoming item, leaving the rest of the queue in place.
  ///
  /// Does nothing if [id] is not upcoming.
  Future<void> playItem(String id);

  /// Plays the entry at [index] of [entries]. Out-of-range indices and the
  /// current entry are ignored.
  Future<void> playAt(int index);

  @internal
  void setPlayer(PlayerStateNotifier playerStateNotifier) {}

  ValueNotifier<bool> get shuffleEnabled;

  /// Most recently played first.
  ValueNotifier<List<MediaItem>> get history;

  ValueNotifier<List<MediaItem>> get queue;

  ValueNotifier<List<MediaItem>> get nextUp;

  /// The current item followed by everything upcoming, as one list.
  ///
  /// Saves every consumer assembling "current + upcoming, current highlighted"
  /// for itself.
  ValueNotifier<List<QueueEntry>> get entries;
}
