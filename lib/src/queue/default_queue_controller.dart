import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/queue/queue_controller.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class DefaultQueueManager implements QueueManager {
  DefaultQueueManager() {
    _queue.itemsNotifier.addListener(_recomputeEntries);
    _nextUp.itemsNotifier.addListener(_recomputeEntries);
  }

  PlayerStateNotifier? _playerNotifier;

  final QueueList _queue = QueueList();
  final QueueList _history = QueueList();
  final ShuffleQueueList _nextUp = ShuffleQueueList();
  final ValueNotifier<List<QueueEntry>> _entries = ValueNotifier(const []);
  void Function()? stopPlayerListener;

  /// How far into an item [skipToPrevious] stops going back and restarts
  /// instead. Three seconds is the usual convention.
  Duration restartThreshold = const Duration(seconds: 3);

  /// Upper bound on [queue], so a runaway caller cannot grow it without limit.
  /// Additions past this are dropped rather than throwing.
  int maxQueueLength = 1000;

  @override
  ValueNotifier<bool> get shuffleEnabled => _nextUp.shuffleNotifier;
  @override
  ValueNotifier<List<MediaItem>> get history => _history.itemsNotifier;
  @override
  ValueNotifier<List<MediaItem>> get queue => _queue.itemsNotifier;
  @override
  ValueNotifier<List<MediaItem>> get nextUp => _nextUp.itemsNotifier;
  @override
  ValueNotifier<List<QueueEntry>> get entries => _entries;

  @override
  void dispose() {
    _queue.itemsNotifier.removeListener(_recomputeEntries);
    _nextUp.itemsNotifier.removeListener(_recomputeEntries);
    _queue.dispose();
    _history.dispose();
    _nextUp.dispose();
    _entries.dispose();
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
    _recomputeEntries();
  }

  void _recomputeEntries() {
    final current = _playerNotifier?.getState().currentMediaItem;
    _entries.value = [
      if (current != null) QueueEntry(mediaItem: current, kind: QueueEntryKind.current),
      for (final item in _queue.items) QueueEntry(mediaItem: item, kind: QueueEntryKind.queue),
      for (final item in _nextUp.items) QueueEntry(mediaItem: item, kind: QueueEntryKind.nextUp),
    ];
  }

  /// Seeks the current item back to the start.
  Future<void> _restartCurrent(PlayerState state) {
    return BccmPlayerInterface.instance.seekTo(state.playerId, 0);
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
    final state = player.getState();

    // Past the threshold, "previous" means "start this one again" — pressing it
    // mid-track to jump backwards is almost never what was meant.
    if ((state.playbackPositionMs ?? 0) > restartThreshold.inMilliseconds) {
      return _restartCurrent(state);
    }

    final current = state.currentMediaItem;
    final previous = _history.consumeNext();
    if (previous == null) {
      // Nothing behind us: restart rather than doing nothing at all, so the
      // button is never inert.
      if (current != null) return _restartCurrent(state);
      return;
    }

    if (current != null) {
      // Put the outgoing item back where it will play next. It belongs at the
      // front of `queue` if anything is queued, otherwise at the front of the
      // automatic continuation.
      if (_queue.items.isNotEmpty) {
        _queue.addToStart(current);
      } else {
        _nextUp.addToStart(current);
      }
    }
    await _playMediaItem(previous);
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

  /// Room left before [maxQueueLength] is reached.
  int get _room => maxQueueLength - _queue.items.length;

  @override
  Future<void> addLast(MediaItem mediaItem) async {
    if (_room <= 0) {
      debugPrint('bccm: queue is at maxQueueLength ($maxQueueLength), dropping addLast');
      return;
    }
    _queue.add(_withId(mediaItem));
  }

  @override
  Future<void> addNext(MediaItem mediaItem) async {
    if (_room <= 0) {
      debugPrint('bccm: queue is at maxQueueLength ($maxQueueLength), dropping addNext');
      return;
    }
    _queue.addToStart(_withId(mediaItem));
  }

  @override
  Future<void> insertAll(List<MediaItem> mediaItems) async {
    if (_room <= 0) return;
    if (mediaItems.length > _room) {
      debugPrint('bccm: queue is near maxQueueLength ($maxQueueLength), inserting only $_room of ${mediaItems.length}');
    }
    // One notification for the whole batch rather than one per item.
    _queue.addAll(mediaItems.take(_room).map(_withId).toList());
  }

  @Deprecated('Renamed to addLast, to pair with addNext. Will be removed in a future release.')
  @override
  Future<void> addQueueItem(MediaItem mediaItem) => addLast(mediaItem);

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

  @override
  Future<void> playItem(String id) async {
    final player = _playerNotifier;
    if (player == null) return;
    // Only the chosen item is consumed — everything else stays queued, which is
    // what "tap row 5" should do.
    final target = _queue.consumeSpecific(id) ?? _nextUp.consumeSpecific(id);
    if (target == null) return;
    final current = player.getState().currentMediaItem;
    if (current != null) _history.addToStart(current);
    await _playMediaItem(target);
  }

  @override
  Future<void> playAt(int index) async {
    final list = _entries.value;
    if (index < 0 || index >= list.length) return;
    final entry = list[index];
    if (entry.isCurrent) return;
    final id = entry.mediaItem.id;
    if (id == null) return;
    await playItem(id);
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

  void addAll(List<MediaItem> items) {
    if (items.isEmpty) return;
    itemsNotifier.value = [...itemsNotifier.value, ...items];
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
