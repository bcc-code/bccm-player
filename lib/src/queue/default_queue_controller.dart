import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/queue/queue_controller.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class DefaultQueueManager implements QueueManager {
  PlayerStateNotifier? _playerNotifier;

  final QueueList _queue = QueueList();
  final QueueList _history = QueueList();
  final ShuffleQueueList _nextUp = ShuffleQueueList();
  void Function()? stopPlayerListener;

  @override
  ValueNotifier<bool> get shuffleEnabled => _nextUp.shuffleNotifier;
  @override
  ValueNotifier<List<MediaItem>> get history => _history.itemsNotifier;
  @override
  ValueNotifier<List<MediaItem>> get queue => _queue.itemsNotifier;
  @override
  ValueNotifier<List<MediaItem>> get nextUp => _nextUp.itemsNotifier;

  @override
  void dispose() {
    _queue.dispose();
    _history.dispose();
    _nextUp.dispose();
  }

  @override
  void setPlayer(PlayerStateNotifier playerStateNotifier) {
    stopPlayerListener?.call();
    _playerNotifier = playerStateNotifier;
    stopPlayerListener = _playerNotifier?.addListener(_onPlayerStateChanged);
  }

  void _onPlayerStateChanged(PlayerState state) {
    final currentId = state.currentMediaItem?.id;
    if (currentId != null) {
      _removeIfUpcoming(currentId);
    }
  }

  void _removeIfUpcoming(String id) {
    if (_queue.items.any((i) => i.id == id)) {
      _queue.remove(id);
    }
    if (_nextUp.items.any((i) => i.id == id)) {
      _nextUp.remove(id);
    }
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
    final player = _playerNotifier;
    if (player == null) return;
    final ended = mediaItem ?? player.getState().currentMediaItem;
    final next = _queue.consumeNext() ?? _nextUp.consumeNext();
    if (next != null) {
      // Same as [skipToNext]: only record history when we actually move on. If
      // there is nothing next, the ended item stays current and does not belong
      // in history.
      if (ended != null) _history.addToStart(ended);
      await _playMediaItem(next);
    }
  }

  @override
  Future<void> setShuffleEnabled(bool enabled) async {
    _nextUp.setShuffleEnabled(enabled);
  }

  @override
  Future<void> setNextUp(List<MediaItem> mediaItems) async {
    // Build a new list rather than writing back into the caller's — MediaItem is
    // a mutable pigeon class, so assigning into `mediaItems[i]` mutated the list
    // the caller still holds.
    _nextUp.setItems(mediaItems.map(_withId).toList());
  }

  /// Returns [item] unchanged if it already has an id, otherwise a copy with a
  /// generated one. Ids are what the queue addresses items by.
  MediaItem _withId(MediaItem item) {
    if (item.id != null) return item;
    final copy = MediaItem.decode(item.encode());
    copy.id = const Uuid().v4();
    return copy;
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    _queue.add(_withId(mediaItem));
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

  /// Moves the item at [fromIndex] to [toIndex].
  ///
  /// Out-of-range indices are tolerated rather than thrown: a reorderable list
  /// racing a queue update hands us stale indices routinely, and dropping the
  /// move is far better than a RangeError out of a gesture handler.
  void move(int fromIndex, int toIndex) {
    final list = [...itemsNotifier.value];
    if (fromIndex < 0 || fromIndex >= list.length) return;
    final item = list.removeAt(fromIndex);
    list.insert(toIndex.clamp(0, list.length), item);
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

/// A [QueueList] that can present its items in a shuffled order while
/// remembering the order they were given in, so toggling shuffle off restores
/// it.
///
/// [_orderedItems] is the unshuffled backing list and must track every
/// mutation of [itemsNotifier] — otherwise consuming an item leaves it in the
/// backing list and toggling shuffle brings it back from the dead. Mutations
/// deliberately do *not* re-run [_maybeShuffle]: reshuffling on every consumed
/// track would reorder the visible queue under the user.
class ShuffleQueueList extends QueueList {
  List<MediaItem> _orderedItems = [];
  final ValueNotifier<bool> shuffleNotifier = ValueNotifier(false);

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

  /// Drops [item] from the backing list. Matches on `id` when there is one and
  /// falls back to identity, so an id-less item can't take every other id-less
  /// item with it.
  void _forget(MediaItem item) {
    _orderedItems = _orderedItems
        .where((i) => item.id != null ? i.id != item.id : !identical(i, item))
        .toList();
  }

  @override
  void add(MediaItem item) {
    _orderedItems = [..._orderedItems, item];
    super.add(item);
  }

  @override
  void addToStart(MediaItem item) {
    _orderedItems = [item, ..._orderedItems];
    super.addToStart(item);
  }

  @override
  void clear() {
    _orderedItems = [];
    super.clear();
  }

  @override
  void remove(String id) {
    _orderedItems = _orderedItems.where((item) => item.id != id).toList();
    super.remove(id);
  }

  @override
  MediaItem? consumeNext() {
    final item = super.consumeNext();
    if (item != null) _forget(item);
    return item;
  }

  @override
  MediaItem? consumeSpecific(String id) {
    final item = super.consumeSpecific(id);
    if (item != null) _forget(item);
    return item;
  }
}
