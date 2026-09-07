import 'package:bccm_player/bccm_player.dart';
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
      await queue.addQueueItem(mediaItem(id: 'q1'));
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
      await queue.addQueueItem(mediaItem(id: 'q1'));

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
      await queue.addQueueItem(mediaItem(id: 'q1'));

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
      await queue.addQueueItem(mediaItem(id: 'q1'));
      await queue.skipToNext(); // a -> history, q1 plays
      player.setMediaItem(mediaItem(id: 'q1'));
      await queue.addQueueItem(mediaItem(id: 'q2'));

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

    test('no-ops with empty history', () async {
      player.setMediaItem(mediaItem(id: 'current'));

      await queue.skipToPrevious();

      expect(fake.replaceCurrentMediaItemCalls, isEmpty);
    });
  });

  group('handlePlaybackEnded', () {
    test('advances to the next item', () async {
      await queue.addQueueItem(mediaItem(id: 'q1'));

      await queue.handlePlaybackEnded(mediaItem(id: 'ended'));

      expect(lastPlayed()?.id, 'q1');
    });

    test('records the ended item in history, like skipToNext does', () async {
      // Regression: handlePlaybackEnded used to ignore its argument entirely, so
      // after a track finished naturally you could not skip back to it, even
      // though skipping forward manually did record history.
      final ended = mediaItem(id: 'ended');
      player.setMediaItem(ended);
      await queue.addQueueItem(mediaItem(id: 'q1'));

      await queue.handlePlaybackEnded(ended);

      expect(idsOf(queue.history.value), ['ended']);
    });

    test('falls back to the current media item when passed null', () async {
      player.setMediaItem(mediaItem(id: 'current'));
      await queue.addQueueItem(mediaItem(id: 'q1'));

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
    test('addQueueItem assigns an id when the caller supplies none', () async {
      await queue.addQueueItem(mediaItem(url: 'https://example.test/x.m3u8'));

      expect(queue.queue.value.single.id, isNotNull);
      expect(queue.queue.value.single.url, 'https://example.test/x.m3u8');
    });

    test('addQueueItem preserves a caller-supplied id', () async {
      await queue.addQueueItem(mediaItem(id: 'mine'));

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
      await queue.addQueueItem(mediaItem(id: 'a'));
      await queue.addQueueItem(mediaItem(id: 'b'));

      await queue.removeQueueItem('a');

      expect(idsOf(queue.queue.value), ['b']);
    });

    test('clearQueue empties the queue but leaves nextUp alone', () async {
      await queue.addQueueItem(mediaItem(id: 'a'));
      await queue.setNextUp([mediaItem(id: 'n1')]);

      await queue.clearQueue();

      expect(idsOf(queue.queue.value), isEmpty);
      expect(idsOf(queue.nextUp.value), ['n1']);
    });

    test('moveQueueItem reorders', () async {
      await queue.addQueueItem(mediaItem(id: 'a'));
      await queue.addQueueItem(mediaItem(id: 'b'));
      await queue.addQueueItem(mediaItem(id: 'c'));

      await queue.moveQueueItem(0, 2);

      expect(idsOf(queue.queue.value), ['b', 'c', 'a']);
    });

    test('moveQueueItem tolerates stale indices instead of throwing', () async {
      // Regression: bare removeAt/insert threw RangeError. A ReorderableListView
      // racing a queue update hits this trivially.
      await queue.addQueueItem(mediaItem(id: 'a'));

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
      await queue.addQueueItem(mediaItem(id: 'a'));
      await queue.setNextUp([mediaItem(id: 'a'), mediaItem(id: 'b')]);

      player.setMediaItem(mediaItem(id: 'a'));

      expect(idsOf(queue.queue.value), isEmpty);
      expect(idsOf(queue.nextUp.value), ['b']);
    });

    test('leaves the lists alone for an item that is not queued', () async {
      await queue.addQueueItem(mediaItem(id: 'a'));

      player.setMediaItem(mediaItem(id: 'unrelated'));

      expect(idsOf(queue.queue.value), ['a']);
    });
  });
}
