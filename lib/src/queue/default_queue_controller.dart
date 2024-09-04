import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/queue/queue_controller.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class DefaultQueueManager implements QueueManager {
  DefaultQueueManager();

  PlayerStateNotifier? _playerNotifier;

  final QueueList _queue = QueueList();
  final QueueList _history = QueueList();
  final ShuffleQueueList _nextUp = ShuffleQueueList();

  @override
  ValueNotifier<bool> get shuffleEnabled => _nextUp.shuffleNotifier;
  @override
  ValueNotifier<List<MediaItem>> get history => _history.itemsNotifier;
  @override
  ValueNotifier<List<MediaItem>> get queue => _queue.itemsNotifier;
  @override
  ValueNotifier<List<MediaItem>> get nextUp => _nextUp.itemsNotifier;

  void dispose() {
    _queue.dispose();
    _history.dispose();
    _nextUp.dispose();
  }

  @override
  void setPlayer(PlayerStateNotifier playerStateNotifier) {
    _playerNotifier = playerStateNotifier;
  }

  @override
  Future<void> skipToNext() async {
    final player = _playerNotifier;
    if (player == null) return;
    final current = player.getState().currentMediaItem;
    final next = _queue.consumeNext() ?? _nextUp.consumeNext();
    if (next != null) {
      if (current != null) _history.addToStart(current);
      await _playMediaItem(next);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final player = _playerNotifier;
    if (player == null) return;
    final current = player.getState().currentMediaItem;
    final previous = _history.consumeNext();
    if (previous != null && current != null) {
      if (queue.value.isNotEmpty) {
        _queue.addToStart(current);
      } else {
        _nextUp.addToStart(current);
      }
      await _playMediaItem(previous);
    }
  }

  @override
  Future<void> handlePlaybackEnded(MediaItem? mediaItem) async {
    if (_playerNotifier == null) return;
    final next = _queue.consumeNext() ?? _nextUp.consumeNext();
    if (next != null) {
      await _playMediaItem(next);
    }
  }

  @override
  Future<void> setShuffleEnabled(bool enabled) async {
    _nextUp.setShuffleEnabled(enabled);
  }

  @override
  Future<void> setNextUp(List<MediaItem> mediaItems) async {
    for (var item in mediaItems) {
      item.id ??= const Uuid().v4();
    }
    _nextUp.setItems(mediaItems);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    mediaItem.id ??= const Uuid().v4();
    _queue.add(mediaItem);
  }

  @override
  Future<void> removeQueueItem(String id) async {
    _queue.remove(id);
  }

  @override
  Future<void> moveQueueItem(int fromIndex, int toIndex) async {
    _queue.move(fromIndex, toIndex);
  }

  @override
  Future<void> clearQueue() async {
    _queue.clear();
  }

  Future<void> _playMediaItem(MediaItem mediaItem) async {
    final player = _playerNotifier;
    if (player == null) return;
    await BccmPlayerInterface.instance.replaceCurrentMediaItem(
      player.getState().playerId,
      mediaItem,
      playbackPositionFromPrimary: false,
      autoplay: true,
    );
  }
}

class QueueList {
  final ValueNotifier<List<MediaItem>> itemsNotifier = ValueNotifier([]);

  List<MediaItem> get items => itemsNotifier.value;

  void dispose() {
    itemsNotifier.dispose();
  }

  void add(MediaItem item) {
    itemsNotifier.value = [...itemsNotifier.value, item];
  }

  void addToStart(MediaItem item) {
    itemsNotifier.value = [item, ...itemsNotifier.value];
  }

  void clear() {
    itemsNotifier.value = [];
  }

  void remove(String id) {
    itemsNotifier.value = itemsNotifier.value.where((item) => item.id != id).toList();
  }

  void move(int fromIndex, int toIndex) {
    final list = [...itemsNotifier.value];
    final item = list.removeAt(fromIndex);
    list.insert(toIndex, item);
    itemsNotifier.value = list;
  }

  MediaItem? consumeNext() {
    if (itemsNotifier.value.isNotEmpty) {
      final item = itemsNotifier.value.first;
      itemsNotifier.value = itemsNotifier.value.sublist(1);
      return item;
    }
    return null;
  }

  MediaItem? consumeSpecific(String id) {
    final item = itemsNotifier.value.firstWhereOrNull((item) => item.id == id);
    if (item != null) {
      itemsNotifier.value = itemsNotifier.value.where((item) => item.id != id).toList();
    }
    return item;
  }
}

class ShuffleQueueList extends QueueList {
  List<MediaItem> _orderedItems = [];
  ValueNotifier<bool> shuffleNotifier = ValueNotifier(false);

  ShuffleQueueList() {
    shuffleNotifier.addListener(_maybeShuffle);
  }

  @override
  void dispose() {
    shuffleNotifier.removeListener(_maybeShuffle);
    shuffleNotifier.dispose();
    super.dispose();
  }

  void setShuffleEnabled(bool shuffle) {
    shuffleNotifier.value = shuffle;
  }

  void _maybeShuffle() {
    if (shuffleNotifier.value) {
      itemsNotifier.value = [..._orderedItems]..shuffle();
    } else {
      itemsNotifier.value = [..._orderedItems];
    }
  }

  void setItems(List<MediaItem> items) {
    _orderedItems = [...items];
    _maybeShuffle();
  }
}
