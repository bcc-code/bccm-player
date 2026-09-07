import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/queue/default_queue_controller.dart';
import 'package:bccm_player/src/queue/queue_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fake_platform.dart';
import '../utils/fixtures.dart';

/// Tests are scoped to the [QueueManager] *contract*, not to the
/// `QueueList` / `ShuffleQueueList` internals. Per
/// `doc/contributing/audio-support-plan.md` §1, those internals move into the
/// native players; the contract survives the move and is what makes it safe.
void main() {
  late FakeBccmPlayerInterface fake;
  late PlayerStateNotifier player;
  late QueueManager queue;

  setUp(() {
    fake = FakeBccmPlayerInterface.install();
    player = PlayerStateNotifier(keepAlive: false, player: const PlayerState(playerId: 'p1'));
    queue = player.queueManager;
  });

  tearDown(() {
    player.dispose();
    fake.restore();
  });

  /// The media item the fake platform was last asked to play.
  MediaItem? lastPlayed() =>
      fake.replaceCurrentMediaItemCalls.isEmpty ? null : fake.replaceCurrentMediaItemCalls.last.mediaItem;

  group('skipToNext', () {
    test('drains queue before nextUp', () async {
      await queue.addLast(mediaItem(id: 'q1'));
      await queue.setNextUp([mediaItem(id: 'n1')]);

      await queue.skipToNext();
      expect(lastPlayed()?.id, 'q1');
      expect(idsOf(queue.queue.value), isEmpty);
      expect(idsOf(queue.nextUp.value), ['n1']);

      await queue.skipToNext();
      expect(lastPlayed()?.id, 'n1');
      expect(idsOf(queue.nextUp.value), isEmpty);
    });

    test('pushes the outgoing item onto history', () async {
      player.setMediaItem(mediaItem(id: 'current'));
      await queue.addLast(mediaItem(id: 'q1'));

      await queue.skipToNext();

      expect(idsOf(queue.history.value), ['current']);
    });

    test('no-ops when both queue and nextUp are empty', () async {
      player.setMediaItem(mediaItem(id: 'current'));

      await queue.skipToNext();

      expect(fake.replaceCurrentMediaItemCalls, isEmpty);
      expect(idsOf(queue.history.value), isEmpty);
    });

    test('plays with autoplay and without inheriting the primary position', () async {
      await queue.addLast(mediaItem(id: 'q1'));

      await queue.skipToNext();

      final call = fake.replaceCurrentMediaItemCalls.single;
      expect(call.playerId, 'p1');
      expect(call.autoplay, isTrue);
      expect(call.playbackPositionFromPrimary, isFalse);
    });
  });

  group('skipToPrevious', () {
    test('pops history and returns the current item to the front of the queue', () async {
      player.setMediaItem(mediaItem(id: 'a'));
      await queue.addLast(mediaItem(id: 'q1'));
      await queue.skipToNext(); // a -> history, q1 plays
      player.setMediaItem(mediaItem(id: 'q1'));
      await queue.addLast(mediaItem(id: 'q2'));

      await queue.skipToPrevious();

      expect(lastPlayed()?.id, 'a');
      expect(idsOf(queue.history.value), isEmpty);
      expect(idsOf(queue.queue.value), ['q1', 'q2']);
    });

    test('returns the current item to nextUp when the queue is empty', () async {
      player.setMediaItem(mediaItem(id: 'a'));
      await queue.setNextUp([mediaItem(id: 'n1')]);
      await queue.skipToNext(); // a -> history, n1 consumed
      player.setMediaItem(mediaItem(id: 'n1'));

      await queue.skipToPrevious();

      expect(lastPlayed()?.id, 'a');
      expect(idsOf(queue.nextUp.value), ['n1']);
      expect(idsOf(queue.queue.value), isEmpty);
    });

    test('restarts rather than doing nothing when history is empty', () async {
      // The button should never be inert: with nothing behind us, "previous"
      // means "start this one again".
      player.setMediaItem(mediaItem(id: 'current'));

      await queue.skipToPrevious();

      expect(fake.replaceCurrentMediaItemCalls, isEmpty);
      expect(fake.seekToCalls.single.positionMs, 0);
    });

    test('does nothing at all when there is no current item and no history', () async {
      await queue.skipToPrevious();

      expect(fake.replaceCurrentMediaItemCalls, isEmpty);
      expect(fake.seekToCalls, isEmpty);
    });

    test('restarts the current item when past the threshold', () async {
      // Regression: it used to always jump back, so pressing previous halfway
      // through a track lost your place in it.
      player.setMediaItem(mediaItem(id: 'a'));
      await queue.addLast(mediaItem(id: 'q1'));
      await queue.skipToNext(); // a -> history
      player.setMediaItem(mediaItem(id: 'q1'));
      player.setPlaybackPosition(30000);
      fake.replaceCurrentMediaItemCalls.clear();

      await queue.skipToPrevious();

      expect(fake.seekToCalls.single.positionMs, 0);
      expect(fake.replaceCurrentMediaItemCalls, isEmpty, reason: 'stays on the current item');
      expect(idsOf(queue.history.value), ['a'], reason: 'history is untouched');
    });

    test('goes back when pressed near the start', () async {
      player.setMediaItem(mediaItem(id: 'a'));
      await queue.addLast(mediaItem(id: 'q1'));
      await queue.skipToNext();
      player.setMediaItem(mediaItem(id: 'q1'));
      player.setPlaybackPosition(1500);
      fake.replaceCurrentMediaItemCalls.clear();

      await queue.skipToPrevious();

      expect(lastPlayed()?.id, 'a');
      expect(fake.seekToCalls, isEmpty);
    });

    test('the restart threshold is adjustable', () async {
      (queue as DefaultQueueManager).restartThreshold = Duration.zero;
      player.setMediaItem(mediaItem(id: 'a'));
      await queue.addLast(mediaItem(id: 'q1'));
      await queue.skipToNext();
      player.setMediaItem(mediaItem(id: 'q1'));
      player.setPlaybackPosition(1);
      fake.replaceCurrentMediaItemCalls.clear();

      await queue.skipToPrevious();

      expect(fake.seekToCalls.single.positionMs, 0, reason: 'a zero threshold always restarts');
    });
  });

  group('handlePlaybackEnded', () {
    test('advances to the next item', () async {
      await queue.addLast(mediaItem(id: 'q1'));

      await queue.handlePlaybackEnded(mediaItem(id: 'ended'));

      expect(lastPlayed()?.id, 'q1');
    });

    test('records the ended item in history, like skipToNext does', () async {
      // Regression: handlePlaybackEnded used to ignore its argument entirely, so
      // after a track finished naturally you could not skip back to it, even
      // though skipping forward manually did record history.
      final ended = mediaItem(id: 'ended');
      player.setMediaItem(ended);
      await queue.addLast(mediaItem(id: 'q1'));

      await queue.handlePlaybackEnded(ended);

      expect(idsOf(queue.history.value), ['ended']);
    });

    test('falls back to the current media item when passed null', () async {
      player.setMediaItem(mediaItem(id: 'current'));
      await queue.addLast(mediaItem(id: 'q1'));

      await queue.handlePlaybackEnded(null);

      expect(idsOf(queue.history.value), ['current']);
    });

    test('does not record history when there is nothing to advance to', () async {
      final ended = mediaItem(id: 'ended');
      player.setMediaItem(ended);

      await queue.handlePlaybackEnded(ended);

      expect(idsOf(queue.history.value), isEmpty);
      expect(fake.replaceCurrentMediaItemCalls, isEmpty);
    });
  });

  group('id backfill', () {
    test('addLast assigns an id when the caller supplies none', () async {
      await queue.addLast(mediaItem(url: 'https://example.test/x.m3u8'));

      expect(queue.queue.value.single.id, isNotNull);
      expect(queue.queue.value.single.url, 'https://example.test/x.m3u8');
    });

    test('addLast preserves a caller-supplied id', () async {
      await queue.addLast(mediaItem(id: 'mine'));

      expect(queue.queue.value.single.id, 'mine');
    });

    test('setNextUp assigns ids and gives distinct ones per item', () async {
      await queue.setNextUp([mediaItem(), mediaItem()]);

      final ids = idsOf(queue.nextUp.value);
      expect(ids, everyElement(isNotNull));
      expect(ids.toSet(), hasLength(2));
    });

    test('setNextUp does not mutate the list it was given', () async {
      // Regression: setNextUp wrote the backfilled items straight back into
      // `mediaItems[i]`, mutating the caller's list under them.
      final caller = [mediaItem(), mediaItem()];

      await queue.setNextUp(caller);

      expect(idsOf(caller), everyElement(isNull));
      expect(idsOf(queue.nextUp.value), everyElement(isNotNull));
    });
  });

  group('queue mutation', () {
    test('removeQueueItem removes by id', () async {
      await queue.addLast(mediaItem(id: 'a'));
      await queue.addLast(mediaItem(id: 'b'));

      await queue.removeQueueItem('a');

      expect(idsOf(queue.queue.value), ['b']);
    });

    test('clearQueue empties the queue but leaves nextUp alone', () async {
      await queue.addLast(mediaItem(id: 'a'));
      await queue.setNextUp([mediaItem(id: 'n1')]);

      await queue.clearQueue();

      expect(idsOf(queue.queue.value), isEmpty);
      expect(idsOf(queue.nextUp.value), ['n1']);
    });

    test('moveQueueItem reorders', () async {
      await queue.addLast(mediaItem(id: 'a'));
      await queue.addLast(mediaItem(id: 'b'));
      await queue.addLast(mediaItem(id: 'c'));

      await queue.moveQueueItem(0, 2);

      expect(idsOf(queue.queue.value), ['b', 'c', 'a']);
    });

    test('moveQueueItem tolerates stale indices instead of throwing', () async {
      // Regression: bare removeAt/insert threw RangeError. A ReorderableListView
      // racing a queue update hits this trivially.
      await queue.addLast(mediaItem(id: 'a'));

      await expectLater(queue.moveQueueItem(5, 0), completes);
      await expectLater(queue.moveQueueItem(0, 9), completes);
      await expectLater(queue.moveQueueItem(-1, 0), completes);

      expect(idsOf(queue.queue.value), ['a']);
    });
  });

  group('shuffle', () {
    test('toggling off restores the original order', () async {
      await queue.setNextUp(mediaItems(5));
      final original = idsOf(queue.nextUp.value);

      await queue.setShuffleEnabled(true);
      await queue.setShuffleEnabled(false);

      expect(idsOf(queue.nextUp.value), original);
      expect(queue.shuffleEnabled.value, isFalse);
    });

    test('shuffling keeps the same set of items', () async {
      await queue.setNextUp(mediaItems(5));

      await queue.setShuffleEnabled(true);

      expect(idsOf(queue.nextUp.value).toSet(), idsOf(mediaItems(5)).toSet());
      expect(queue.shuffleEnabled.value, isTrue);
    });

    test('toggling shuffle does not resurrect already-played items', () async {
      // Regression: `_orderedItems` was only ever written by setItems, so
      // consuming an item left it in the backing list and toggling shuffle
      // replayed the whole original list from the top.
      await queue.setNextUp(mediaItems(3)); // id-1, id-2, id-3
      await queue.skipToNext(); // consumes id-1

      await queue.setShuffleEnabled(true);
      await queue.setShuffleEnabled(false);

      expect(idsOf(queue.nextUp.value), ['id-2', 'id-3']);
    });

    test('an item returned to nextUp survives unshuffling', () async {
      // skipToPrevious is the only caller that pushes onto nextUp, so it is the
      // only path that exercises the backing list's add side.
      player.setMediaItem(mediaItem(id: 'a'));
      await queue.setNextUp(mediaItems(2)); // id-1, id-2
      await queue.setShuffleEnabled(true);
      await queue.skipToNext(); // a -> history, one of id-1/id-2 consumed
      player.setMediaItem(lastPlayed());

      await queue.skipToPrevious(); // plays 'a', returns the consumed item

      await queue.setShuffleEnabled(false);
      expect(idsOf(queue.nextUp.value), hasLength(2));
      expect(idsOf(queue.nextUp.value).toSet(), {'id-1', 'id-2'});
    });

    test('removeQueueItem does not reach into nextUp, shuffled or not', () async {
      // The contract has no way to remove a specific nextUp item — removeQueueItem
      // only addresses `queue`. Worth pinning so a future `removeNextUpItem`
      // does not quietly change this one's scope.
      await queue.setNextUp(mediaItems(3));
      await queue.setShuffleEnabled(true);

      await queue.removeQueueItem('id-2');
      expect(idsOf(queue.nextUp.value), hasLength(3));

      await queue.setShuffleEnabled(false);
      expect(idsOf(queue.nextUp.value), ['id-1', 'id-2', 'id-3']);
    });
  });

  group('player state listener', () {
    test('removes an item from queue and nextUp once it becomes current', () async {
      await queue.addLast(mediaItem(id: 'a'));
      await queue.setNextUp([mediaItem(id: 'a'), mediaItem(id: 'b')]);

      player.setMediaItem(mediaItem(id: 'a'));

      expect(idsOf(queue.queue.value), isEmpty);
      expect(idsOf(queue.nextUp.value), ['b']);
    });

    test('leaves the lists alone for an item that is not queued', () async {
      await queue.addLast(mediaItem(id: 'a'));

      player.setMediaItem(mediaItem(id: 'unrelated'));

      expect(idsOf(queue.queue.value), ['a']);
    });
  });

  group('adding items', () {
    test('addLast appends to the end of the queue', () async {
      await queue.addLast(mediaItem(id: 'a'));
      await queue.addLast(mediaItem(id: 'b'));

      expect(idsOf(queue.queue.value), ['a', 'b']);
    });

    test('addNext jumps the item to the front, to play right after the current one', () async {
      await queue.addLast(mediaItem(id: 'a'));
      await queue.addLast(mediaItem(id: 'b'));

      await queue.addNext(mediaItem(id: 'urgent'));

      expect(idsOf(queue.queue.value), ['urgent', 'a', 'b']);
    });

    test('addNext backfills an id like the others do', () async {
      await queue.addNext(mediaItem());

      expect(queue.queue.value.single.id, isNotNull);
    });

    test('insertAll appends in order', () async {
      await queue.addLast(mediaItem(id: 'a'));

      await queue.insertAll(mediaItems(3));

      expect(idsOf(queue.queue.value), ['a', 'id-1', 'id-2', 'id-3']);
    });

    test('insertAll notifies once for the whole batch', () async {
      var notifications = 0;
      queue.queue.addListener(() => notifications++);

      await queue.insertAll(mediaItems(5));

      expect(notifications, 1, reason: 'a per-item notification would rebuild the UI five times');
    });

    test('insertAll of nothing does not notify', () async {
      var notifications = 0;
      queue.queue.addListener(() => notifications++);

      await queue.insertAll([]);

      expect(notifications, 0);
    });

    test('the deprecated addQueueItem still behaves like addLast', () async {
      // ignore: deprecated_member_use_from_same_package
      await queue.addQueueItem(mediaItem(id: 'a'));

      expect(idsOf(queue.queue.value), ['a']);
    });
  });

  group('max queue length', () {
    test('drops additions past the cap instead of growing without bound', () async {
      (queue as DefaultQueueManager).maxQueueLength = 2;

      await queue.addLast(mediaItem(id: 'a'));
      await queue.addLast(mediaItem(id: 'b'));
      await queue.addLast(mediaItem(id: 'c'));
      await queue.addNext(mediaItem(id: 'd'));

      expect(idsOf(queue.queue.value), ['a', 'b']);
    });

    test('insertAll fills the remaining room and drops the rest', () async {
      (queue as DefaultQueueManager).maxQueueLength = 3;
      await queue.addLast(mediaItem(id: 'a'));

      await queue.insertAll(mediaItems(5));

      expect(idsOf(queue.queue.value), ['a', 'id-1', 'id-2']);
    });
  });

  group('playItem', () {
    test('plays an upcoming item and leaves the rest queued', () async {
      // Tapping row 3 should not discard rows 1 and 2.
      player.setMediaItem(mediaItem(id: 'current'));
      await queue.insertAll(mediaItems(3));

      await queue.playItem('id-3');

      expect(lastPlayed()?.id, 'id-3');
      expect(idsOf(queue.queue.value), ['id-1', 'id-2']);
    });

    test('moves the outgoing item to history', () async {
      player.setMediaItem(mediaItem(id: 'current'));
      await queue.insertAll(mediaItems(2));

      await queue.playItem('id-2');

      expect(idsOf(queue.history.value), ['current']);
    });

    test('reaches into nextUp as well as queue', () async {
      await queue.setNextUp(mediaItems(3, prefix: 'n'));

      await queue.playItem('n-2');

      expect(lastPlayed()?.id, 'n-2');
      expect(idsOf(queue.nextUp.value), ['n-1', 'n-3']);
    });

    test('ignores an id that is not upcoming', () async {
      await queue.addLast(mediaItem(id: 'a'));

      await queue.playItem('nope');

      expect(fake.replaceCurrentMediaItemCalls, isEmpty);
      expect(idsOf(queue.queue.value), ['a']);
    });
  });

  group('playAt', () {
    test('plays the entry at that position in the combined view', () async {
      player.setMediaItem(mediaItem(id: 'current'));
      await queue.insertAll(mediaItems(2));
      await queue.setNextUp(mediaItems(2, prefix: 'n'));

      // entries == [current, id-1, id-2, n-1, n-2]
      await queue.playAt(3);

      expect(lastPlayed()?.id, 'n-1');
    });

    test('ignores the current entry', () async {
      player.setMediaItem(mediaItem(id: 'current'));
      await queue.addLast(mediaItem(id: 'a'));

      await queue.playAt(0);

      expect(fake.replaceCurrentMediaItemCalls, isEmpty);
    });

    test('ignores out-of-range indices', () async {
      await queue.addLast(mediaItem(id: 'a'));

      await queue.playAt(-1);
      await queue.playAt(99);

      expect(fake.replaceCurrentMediaItemCalls, isEmpty);
    });
  });

  group('entries', () {
    List<String?> entryIds() => queue.entries.value.map((e) => e.mediaItem.id).toList();
    List<QueueEntryKind> entryKinds() => queue.entries.value.map((e) => e.kind).toList();

    test('is current, then queue, then nextUp', () async {
      player.setMediaItem(mediaItem(id: 'current'));
      await queue.insertAll(mediaItems(2));
      await queue.setNextUp(mediaItems(2, prefix: 'n'));

      expect(entryIds(), ['current', 'id-1', 'id-2', 'n-1', 'n-2']);
      expect(entryKinds(), [
        QueueEntryKind.current,
        QueueEntryKind.queue,
        QueueEntryKind.queue,
        QueueEntryKind.nextUp,
        QueueEntryKind.nextUp,
      ]);
    });

    test('marks exactly one entry as current', () async {
      player.setMediaItem(mediaItem(id: 'current'));
      await queue.insertAll(mediaItems(2));

      expect(queue.entries.value.where((e) => e.isCurrent).map((e) => e.mediaItem.id), ['current']);
    });

    test('holds only upcoming items when nothing is playing', () async {
      await queue.insertAll(mediaItems(2));

      expect(entryIds(), ['id-1', 'id-2']);
      expect(entryKinds(), everyElement(QueueEntryKind.queue));
    });

    test('tracks a change of current item', () async {
      await queue.setNextUp(mediaItems(2, prefix: 'n'));
      expect(entryIds(), ['n-1', 'n-2']);

      player.setMediaItem(mediaItem(id: 'now-playing'));

      expect(entryIds(), ['now-playing', 'n-1', 'n-2']);
    });

    test('tracks queue mutations', () async {
      await queue.addLast(mediaItem(id: 'a'));
      expect(entryIds(), ['a']);

      await queue.addNext(mediaItem(id: 'b'));
      expect(entryIds(), ['b', 'a']);

      await queue.removeQueueItem('a');
      expect(entryIds(), ['b']);

      await queue.clearQueue();
      expect(entryIds(), isEmpty);
    });

    test('drops an item from the upcoming lists once it becomes current', () async {
      await queue.setNextUp(mediaItems(2, prefix: 'n'));

      player.setMediaItem(mediaItem(id: 'n-1'));

      expect(entryIds(), ['n-1', 'n-2'], reason: 'it appears once, as the current entry');
      expect(entryKinds().first, QueueEntryKind.current);
    });
  });
}
