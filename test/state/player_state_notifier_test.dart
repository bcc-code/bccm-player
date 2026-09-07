import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fixtures.dart';

void main() {
  group('PlayerState.fromPlayerStateSnapshot', () {
    test('maps isFullscreen onto isNativeFullscreen', () {
      // The field names differ on purpose but are trivially inverted in a
      // refactor, and the symptom (fullscreen state stuck) is far from the cause.
      final state = PlayerState.fromPlayerStateSnapshot(snapshot(isFullscreen: true));

      expect(state.isNativeFullscreen, isTrue);
    });

    test('always marks the player initialized', () {
      expect(PlayerState.fromPlayerStateSnapshot(snapshot()).isInitialized, isTrue);
    });

    test('rounds the playback position and nulls non-finite values', () {
      expect(
        PlayerState.fromPlayerStateSnapshot(snapshot(playbackPositionMs: 999.5)).playbackPositionMs,
        1000,
      );
      expect(
        PlayerState.fromPlayerStateSnapshot(snapshot(playbackPositionMs: double.nan)).playbackPositionMs,
        isNull,
      );
      expect(
        PlayerState.fromPlayerStateSnapshot(snapshot(playbackPositionMs: double.negativeInfinity))
            .playbackPositionMs,
        isNull,
      );
    });

    test('a fresh PlayerState has sane defaults', () {
      const state = PlayerState(playerId: 'p1');

      expect(state.playbackSpeed, 1.0);
      expect(state.playbackState, PlaybackState.stopped);
      expect(state.isBuffering, isFalse);
      expect(state.isInPipMode, isFalse);
      expect(state.isNativeFullscreen, isFalse);
      expect(state.isInitialized, isFalse);
    });
  });

  group('PlayerStateNotifier position ticker', () {
    /// Runs [body] with a notifier in the given state, inside a fake clock.
    void withNotifier(PlayerState initial, void Function(PlayerStateNotifier, FakeAsync) body) {
      fakeAsync((async) {
        final notifier = PlayerStateNotifier(keepAlive: false, player: initial);
        addTearDown(notifier.dispose);
        body(notifier, async);
        notifier.dispose();
      });
    }

    test('advances one second per tick while playing', () {
      withNotifier(
        const PlayerState(
          playerId: 'p1',
          playbackState: PlaybackState.playing,
          playbackPositionMs: 0,
        ),
        (notifier, async) {
          async.elapse(const Duration(seconds: 3));
          expect(notifier.state.playbackPositionMs, 3000);
        },
      );
    });

    test('scales the tick by playback speed', () {
      withNotifier(
        const PlayerState(
          playerId: 'p1',
          playbackState: PlaybackState.playing,
          playbackPositionMs: 0,
          playbackSpeed: 1.5,
        ),
        (notifier, async) {
          async.elapse(const Duration(seconds: 2));
          expect(notifier.state.playbackPositionMs, 3000);
        },
      );
    });

    test('does not advance while buffering', () {
      withNotifier(
        const PlayerState(
          playerId: 'p1',
          playbackState: PlaybackState.playing,
          playbackPositionMs: 5000,
          isBuffering: true,
        ),
        (notifier, async) {
          async.elapse(const Duration(seconds: 3));
          expect(notifier.state.playbackPositionMs, 5000);
        },
      );
    });

    test('does not advance while paused', () {
      withNotifier(
        const PlayerState(
          playerId: 'p1',
          playbackState: PlaybackState.paused,
          playbackPositionMs: 5000,
        ),
        (notifier, async) {
          async.elapse(const Duration(seconds: 3));
          expect(notifier.state.playbackPositionMs, 5000);
        },
      );
    });

    test('does not invent a position when there is none', () {
      withNotifier(
        const PlayerState(playerId: 'p1', playbackState: PlaybackState.playing),
        (notifier, async) {
          async.elapse(const Duration(seconds: 3));
          expect(notifier.state.playbackPositionMs, isNull);
        },
      );
    });

    test('resync restarts the interval so the next tick is a full second away', () {
      withNotifier(
        const PlayerState(
          playerId: 'p1',
          playbackState: PlaybackState.playing,
          playbackPositionMs: 0,
        ),
        (notifier, async) {
          async.elapse(const Duration(milliseconds: 900));
          expect(notifier.state.playbackPositionMs, 0, reason: 'not a full second yet');

          notifier.resyncPlaybackPositionTimer();

          // Would have ticked at 1000ms without the resync; now the next tick is
          // at 1900ms. This is what keeps the interpolated position from
          // double-counting right after a real position arrives from native.
          async.elapse(const Duration(milliseconds: 600));
          expect(notifier.state.playbackPositionMs, 0);

          async.elapse(const Duration(milliseconds: 400));
          expect(notifier.state.playbackPositionMs, 1000);
        },
      );
    });

    test('stops ticking once disposed', () {
      fakeAsync((async) {
        final notifier = PlayerStateNotifier(
          keepAlive: false,
          player: const PlayerState(
            playerId: 'p1',
            playbackState: PlaybackState.playing,
            playbackPositionMs: 0,
          ),
        );
        // Observed through a listener rather than `state`, which throws once
        // disposed.
        final positions = <int?>[];
        notifier.addListener((s) => positions.add(s.playbackPositionMs));

        async.elapse(const Duration(seconds: 1));
        expect(positions.last, 1000);

        notifier.dispose();
        final ticksAtDispose = positions.length;
        async.elapse(const Duration(seconds: 5));

        expect(positions, hasLength(ticksAtDispose), reason: 'timer kept firing after dispose');
      });
    });
  });

  group('PlayerStateNotifier.dispose', () {
    test('a keepAlive notifier ignores a plain dispose', () {
      final notifier = PlayerStateNotifier(keepAlive: true);
      addTearDown(() => notifier.dispose(force: true));

      notifier.dispose();

      expect(notifier.mounted, isTrue);
    });

    test('a keepAlive notifier honours a forced dispose', () {
      final notifier = PlayerStateNotifier(keepAlive: true);

      notifier.dispose(force: true);

      expect(notifier.mounted, isFalse);
    });

    test('a non-keepAlive notifier disposes normally', () {
      final notifier = PlayerStateNotifier(keepAlive: false);

      notifier.dispose();

      expect(notifier.mounted, isFalse);
    });

    test('is idempotent even when onDispose re-enters it', () {
      // Regression: for a notifier owned by PlayerPluginStateNotifier, onDispose
      // runs `_removePlayer`, which calls dispose(force: true) straight back. The
      // second pass used to dispose `queueManager` twice and assert.
      final plugin = PlayerPluginStateNotifier(keepAlive: false);
      addTearDown(() => plugin.dispose(force: true));
      final notifier = plugin.getOrAddPlayerNotifier('p1');

      expect(() => notifier.dispose(force: true), returnsNormally);
      expect(() => notifier.dispose(force: true), returnsNormally);
    });
  });

  group('PlayerPluginStateNotifier', () {
    late PlayerPluginStateNotifier plugin;

    setUp(() => plugin = PlayerPluginStateNotifier(keepAlive: false));

    tearDown(() {
      for (final notifier in [...plugin.state.players.values]) {
        notifier.dispose(force: true);
      }
      plugin.dispose(force: true);
    });

    test('getPlayerNotifier returns null for an unknown player', () {
      expect(plugin.getPlayerNotifier('nope'), isNull);
    });

    test('getOrAddPlayerNotifier creates, stores and then reuses', () {
      final first = plugin.getOrAddPlayerNotifier('p1');

      expect(plugin.state.players.keys, ['p1']);
      expect(plugin.getOrAddPlayerNotifier('p1'), same(first));
    });

    test('getOrAddPlayerNotifier replaces an unmounted notifier', () {
      final first = plugin.getOrAddPlayerNotifier('p1');
      first.dispose(force: true);

      final second = plugin.getOrAddPlayerNotifier('p1');

      expect(second, isNot(same(first)));
      expect(second.mounted, isTrue);
    });

    test('disposing a notifier removes it from the map', () {
      final notifier = plugin.getOrAddPlayerNotifier('p1');

      notifier.dispose(force: true);

      expect(plugin.state.players, isEmpty);
    });

    test('setPrimaryPlayer records the id and creates the notifier', () {
      plugin.setPrimaryPlayer('p1');

      expect(plugin.getPrimaryPlayerId(), 'p1');
      expect(plugin.getPlayerNotifier('p1'), isNotNull);
    });

    test('setPrimaryPlayer(null) clears the primary without touching players', () {
      plugin.setPrimaryPlayer('p1');

      plugin.setPrimaryPlayer(null);

      expect(plugin.getPrimaryPlayerId(), isNull);
      expect(plugin.getPlayerNotifier('p1'), isNotNull);
    });

    test('a new player notifier starts out initialized', () {
      // _createPlayerNotifier seeds isInitialized: true, because by the time
      // native tells us about a player it exists over there.
      expect(plugin.getOrAddPlayerNotifier('p1').state.isInitialized, isTrue);
    });
  });
}
