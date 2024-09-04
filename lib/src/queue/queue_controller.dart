import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

abstract class QueueManager {
  void dispose();
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> handlePlaybackEnded(MediaItem? current);
  Future<void> setShuffleEnabled(bool enabled);
  Future<void> setNextUp(List<MediaItem> mediaItems);
  Future<void> addQueueItem(MediaItem mediaItem);
  Future<void> removeQueueItem(String id);
  Future<void> moveQueueItem(int fromIndex, int toIndex);
  Future<void> clearQueue();

  @internal
  void setPlayer(PlayerStateNotifier playerStateNotifier) {}

  ValueNotifier<bool> get shuffleEnabled;
  ValueNotifier<List<MediaItem>> get history;
  ValueNotifier<List<MediaItem>> get queue;
  ValueNotifier<List<MediaItem>> get nextUp;
}
