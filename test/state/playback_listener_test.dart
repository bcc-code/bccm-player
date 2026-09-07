import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/native/root_pigeon_playback_listener.dart';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:bccm_player/src/state/state_playback_listener.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fixtures.dart';

/// [StatePlaybackListener] is where the native players' events land in Dart.
/// The native side is not unit-tested, so this is the closest testable boundary
/// to it and every playback state the UI reads passes through here.
void main() {
  group('StatePlaybackListener', () {
    late PlayerPluginStateNotifier plugin;
    late StatePlaybackListener listener;

    setUp(() {
      plugin = PlayerPluginStateNotifier(keepAlive: false);
      listener = StatePlaybackListener(plugin);
    });

    tearDown(() {
      for (final notifier in plugin.state.players.values) {
        notifier.dispose(force: true);
      }
      plugin.dispose(force: true);
    });

    PlayerState stateOf(String playerId) => plugin.getPlayerNotifier(playerId)!.state;

    test('onPlaybackStateChanged sets playbackState and isBuffering', () {
      listener.onPlaybackStateChanged(PlaybackStateChangedEvent(
        playerId: 'p1',
        playbackState: PlaybackState.playing,
        isBuffering: true,
      ));

      expect(stateOf('p1').playbackState, PlaybackState.playing);
      expect(stateOf('p1').isBuffering, isTrue);
    });

    test('onMediaItemTransition sets the current media item', () {
      listener.onMediaItemTransition(MediaItemTransitionEvent(
        playerId: 'p1',
        mediaItem: mediaItem(id: 'ep-1'),
      ));

      expect(stateOf('p1').currentMediaItem?.id, 'ep-1');
    });

    test('onPictureInPictureModeChanged sets isInPipMode', () {
      listener.onPictureInPictureModeChanged(
        PictureInPictureModeChangedEvent(playerId: 'p1', isInPipMode: true),
      );

      expect(stateOf('p1').isInPipMode, isTrue);
    });

    test('onPositionDiscontinuity sets a rounded position', () {
      listener.onPositionDiscontinuity(
        PositionDiscontinuityEvent(playerId: 'p1', playbackPositionMs: 1500.6),
      );

      expect(stateOf('p1').playbackPositionMs, 1501);
    });

    test('onPositionDiscontinuity coerces a non-finite position to null', () {
      // AVPlayer reports NaN/infinite times routinely before a manifest loads.
      listener.onPositionDiscontinuity(
        PositionDiscontinuityEvent(playerId: 'p1', playbackPositionMs: double.nan),
      );
      expect(stateOf('p1').playbackPositionMs, isNull);

      listener.onPositionDiscontinuity(
        PositionDiscontinuityEvent(playerId: 'p1', playbackPositionMs: double.infinity),
      );
      expect(stateOf('p1').playbackPositionMs, isNull);
    });

    test('onPlayerStateUpdate applies the whole snapshot', () {
      listener.onPlayerStateUpdate(PlayerStateUpdateEvent(
        playerId: 'p1',
        snapshot: snapshot(
          playerId: 'p1',
          playbackState: PlaybackState.paused,
          isBuffering: true,
          isFullscreen: true,
          playbackSpeed: 1.5,
          currentMediaItem: mediaItem(id: 'ep-1'),
          playbackPositionMs: 4200.0,
          videoSize: VideoSize(width: 1920, height: 1080),
          textureId: 7,
          volume: 0.5,
          error: PlayerError(code: 'x', message: 'boom'),
        ),
      ));

      final state = stateOf('p1');
      expect(state.playbackState, PlaybackState.paused);
      expect(state.isBuffering, isTrue);
      expect(state.isNativeFullscreen, isTrue);
      expect(state.playbackSpeed, 1.5);
      expect(state.currentMediaItem?.id, 'ep-1');
      expect(state.playbackPositionMs, 4200);
      expect(state.videoSize?.aspectRatio, 1920 / 1080);
      expect(state.textureId, 7);
      expect(state.volume, 0.5);
      expect(state.error?.message, 'boom');
      expect(state.isInitialized, isTrue);
    });

    test('onPlayerStateUpdate carries the seekable range onto the notifier', () {
      // These two live on the notifier rather than on PlayerState — see the
      // comment at the top of player_state_notifier.dart for why.
      listener.onPlayerStateUpdate(PlayerStateUpdateEvent(
        playerId: 'p1',
        snapshot: snapshot(playerId: 'p1', seekableRangeStartMs: 100.4, seekableRangeEndMs: 5000.5),
      ));

      final notifier = plugin.getPlayerNotifier('p1')!;
      expect(notifier.seekableRangeStartMs, 100);
      expect(notifier.seekableRangeEndMs, 5001);
    });

    test('onPlayerStateUpdate nulls a non-finite seekable range', () {
      listener.onPlayerStateUpdate(PlayerStateUpdateEvent(
        playerId: 'p1',
        snapshot: snapshot(
          playerId: 'p1',
          seekableRangeStartMs: double.nan,
          seekableRangeEndMs: double.infinity,
        ),
      ));

      final notifier = plugin.getPlayerNotifier('p1')!;
      expect(notifier.seekableRangeStartMs, isNull);
      expect(notifier.seekableRangeEndMs, isNull);
    });

    test('onPlayerStateUpdate preserves isInPipMode, which is not in the snapshot', () {
      listener.onPictureInPictureModeChanged(
        PictureInPictureModeChangedEvent(playerId: 'p1', isInPipMode: true),
      );

      listener.onPlayerStateUpdate(PlayerStateUpdateEvent(
        playerId: 'p1',
        snapshot: snapshot(playerId: 'p1'),
      ));

      expect(stateOf('p1').isInPipMode, isTrue);
    });

    test('onPrimaryPlayerChanged sets the primary id and creates the notifier', () {
      listener.onPrimaryPlayerChanged(PrimaryPlayerChangedEvent(playerId: 'p9'));

      expect(plugin.getPrimaryPlayerId(), 'p9');
      expect(plugin.getPlayerNotifier('p9'), isNotNull);
    });

    test('events for an unknown player create that player', () {
      expect(plugin.getPlayerNotifier('new'), isNull);

      listener.onPlaybackStateChanged(PlaybackStateChangedEvent(
        playerId: 'new',
        playbackState: PlaybackState.playing,
        isBuffering: false,
      ));

      expect(plugin.getPlayerNotifier('new'), isNotNull);
    });

    test('players are kept separate', () {
      listener.onMediaItemTransition(
        MediaItemTransitionEvent(playerId: 'p1', mediaItem: mediaItem(id: 'a')),
      );
      listener.onMediaItemTransition(
        MediaItemTransitionEvent(playerId: 'p2', mediaItem: mediaItem(id: 'b')),
      );

      expect(stateOf('p1').currentMediaItem?.id, 'a');
      expect(stateOf('p2').currentMediaItem?.id, 'b');
    });
  });

  group('RootPigeonPlaybackListener', () {
    late RootPigeonPlaybackListener root;

    setUp(() => root = RootPigeonPlaybackListener());

    test('forwards every callback to added listeners', () {
      final spy = _SpyListener();
      root.addListener(spy);

      root.onPlaybackStateChanged(PlaybackStateChangedEvent(
          playerId: 'p1', playbackState: PlaybackState.playing, isBuffering: false));
      root.onPlaybackEnded(PlaybackEndedEvent(playerId: 'p1'));
      root.onMediaItemTransition(MediaItemTransitionEvent(playerId: 'p1'));
      root.onPictureInPictureModeChanged(
          PictureInPictureModeChangedEvent(playerId: 'p1', isInPipMode: false));
      root.onPositionDiscontinuity(PositionDiscontinuityEvent(playerId: 'p1'));
      root.onPlayerStateUpdate(
          PlayerStateUpdateEvent(playerId: 'p1', snapshot: snapshot(playerId: 'p1')));
      root.onPrimaryPlayerChanged(PrimaryPlayerChangedEvent(playerId: 'p1'));

      expect(spy.received, hasLength(7));
    });

    test('stops forwarding to a removed listener', () {
      final spy = _SpyListener();
      root.addListener(spy);
      root.removeListener(spy);

      root.onPlaybackEnded(PlaybackEndedEvent(playerId: 'p1'));

      expect(spy.received, isEmpty);
    });

    test('publishes every event onto the stream, including primary-player changes', () async {
      // Regression: onPrimaryPlayerChanged was the only one of the seven
      // callbacks that never reached the stream controller, so playerEventStream
      // — and therefore BccmPlayerController.events and
      // playerEventStreamProvider — never saw a primary-player change.
      final received = <Object?>[];
      final sub = root.stream.listen(received.add);
      addTearDown(sub.cancel);

      root.onPlaybackStateChanged(PlaybackStateChangedEvent(
          playerId: 'p1', playbackState: PlaybackState.playing, isBuffering: false));
      root.onPlaybackEnded(PlaybackEndedEvent(playerId: 'p1'));
      root.onMediaItemTransition(MediaItemTransitionEvent(playerId: 'p1'));
      root.onPictureInPictureModeChanged(
          PictureInPictureModeChangedEvent(playerId: 'p1', isInPipMode: false));
      root.onPositionDiscontinuity(PositionDiscontinuityEvent(playerId: 'p1'));
      root.onPlayerStateUpdate(
          PlayerStateUpdateEvent(playerId: 'p1', snapshot: snapshot(playerId: 'p1')));
      root.onPrimaryPlayerChanged(PrimaryPlayerChangedEvent(playerId: 'p1'));

      await Future.delayed(Duration.zero);

      expect(received, hasLength(7));
      expect(received.whereType<PrimaryPlayerChangedEvent>(), hasLength(1));
    });
  });
}

class _SpyListener implements PlaybackListenerPigeon {
  final List<Object?> received = [];

  @override
  void onPlaybackStateChanged(PlaybackStateChangedEvent event) => received.add(event);
  @override
  void onPlaybackEnded(PlaybackEndedEvent event) => received.add(event);
  @override
  void onMediaItemTransition(MediaItemTransitionEvent event) => received.add(event);
  @override
  void onPictureInPictureModeChanged(PictureInPictureModeChangedEvent event) => received.add(event);
  @override
  void onPositionDiscontinuity(PositionDiscontinuityEvent event) => received.add(event);
  @override
  void onPlayerStateUpdate(PlayerStateUpdateEvent event) => received.add(event);
  @override
  void onPrimaryPlayerChanged(PrimaryPlayerChangedEvent event) => received.add(event);
}
