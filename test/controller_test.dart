import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/bccm_player_native.dart';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:flutter/widgets.dart' hide RepeatMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'utils/fake_platform.dart';
import 'utils/fixtures.dart';
import 'utils/mocks.mocks.dart';

void main() {
  group('initialize', () {
    test('creates a native player and loads the initial media item', () async {
      // Kept on the mockito mocks: the point here is verifying the interaction,
      // which is what mockito is good at.
      final mockPlayerInterface = MockBccmPlayerInterface();
      BccmPlayerInterface.instance = mockPlayerInterface;

      const fakePlayerId = '12345678-1234-1234-1234-123456789012';
      const fakeUrl = 'url.mp4';

      final stateNotifier = MockPlayerPluginStateNotifier();
      final playerStateNotifier =
          PlayerStateNotifier(keepAlive: false, player: const PlayerState(playerId: fakePlayerId));

      when(mockPlayerInterface.stateNotifier).thenAnswer((_) => stateNotifier);
      when(stateNotifier.getOrAddPlayerNotifier(any)).thenReturn(playerStateNotifier);
      when(mockPlayerInterface.newPlayer()).thenAnswer((_) async => fakePlayerId);

      final BccmPlayerController controller = BccmPlayerController.networkUrl(Uri.parse(fakeUrl));
      await controller.initialize();

      verify(mockPlayerInterface.newPlayer()).called(1);
      final replaceCurrentMediaItemCall =
          verify(mockPlayerInterface.replaceCurrentMediaItem(fakePlayerId, captureAny));
      expect((replaceCurrentMediaItemCall.captured[0] as MediaItem).url, fakeUrl);

      playerStateNotifier.dispose();
    });

    group('with a fake platform', () {
      late FakeBccmPlayerInterface fake;

      setUp(() => fake = FakeBccmPlayerInterface.install());
      tearDown(() => fake.restore());

      test('adopts the player id from the platform', () async {
        final controller = BccmPlayerController(mediaItem(id: 'a'));
        await controller.initialize();

        expect(controller.value.playerId, 'fake-player-1');
        expect(controller.value.isInitialized, isTrue);
        expect(controller.stateNotifier, isNotNull);
      });

      test('is memoized, so concurrent calls create one native player', () async {
        final controller = BccmPlayerController(mediaItem(id: 'a'));

        await Future.wait([controller.initialize(), controller.initialize()]);

        expect(fake.newPlayerCalls, hasLength(1));
      });

      test('a second initialize after the first completes is a no-op', () async {
        final controller = BccmPlayerController(mediaItem(id: 'a'));
        await controller.initialize();

        await controller.initialize();

        expect(fake.newPlayerCalls, hasLength(1));
      });

      test('does nothing on an already-disposed controller', () async {
        final controller = BccmPlayerController(mediaItem(id: 'a'));
        await controller.dispose();

        await controller.initialize();

        expect(fake.newPlayerCalls, isEmpty);
      });

      test('does not attach when the controller is disposed mid-flight', () async {
        // The window between `newPlayer` returning and the notifier being wired
        // up is real: a widget can be torn down inside it.
        final controller = BccmPlayerController(mediaItem(id: 'a'));
        final pending = controller.initialize();
        await controller.dispose();
        await pending;

        expect(controller.stateNotifier, isNull);
        expect(controller.value.isInitialized, isFalse);
      });

      test('networkUrl builds a media item from the url and mime type', () async {
        final controller = BccmPlayerController.networkUrl(
          Uri.parse('https://example.test/a.m3u8'),
          mimeType: 'application/x-mpegURL',
        );
        await controller.initialize();

        final item = fake.replaceCurrentMediaItemCalls.single.mediaItem;
        expect(item.url, 'https://example.test/a.m3u8');
        expect(item.mimeType, 'application/x-mpegURL');
      });

      test('an empty controller loads no media item', () async {
        final controller = BccmPlayerController.empty();
        await controller.initialize();

        expect(fake.newPlayerCalls, hasLength(1));
        expect(fake.replaceCurrentMediaItemCalls, isEmpty);
      });
    });
  });

  group('an initialized controller', () {
    late FakeBccmPlayerInterface fake;
    late BccmPlayerController controller;

    setUp(() async {
      fake = FakeBccmPlayerInterface.install();
      controller = BccmPlayerController(mediaItem(id: 'a'));
      await controller.initialize();
    });

    tearDown(() => fake.restore());

    test('forwards seekTo as milliseconds', () async {
      await controller.seekTo(const Duration(seconds: 90));

      expect(fake.seekToCalls.single.playerId, 'fake-player-1');
      expect(fake.seekToCalls.single.positionMs, 90000.0);
    });

    test('forwards seekToLive', () async {
      await controller.seekToLive();

      expect(fake.seekToLiveCalls, ['fake-player-1']);
    });

    test('forwards the simple transport controls', () async {
      await controller.play();
      await controller.pause();
      await controller.stop(reset: true);
      await controller.setPlaybackSpeed(1.5);
      await controller.setRepeatMode(RepeatMode.one);
      await controller.setSelectedTrack(TrackType.audio, 'nor');

      expect(fake.playCalls, ['fake-player-1']);
      expect(fake.pauseCalls, ['fake-player-1']);
      expect(fake.stopCalls, ['fake-player-1']);
      expect(fake.setPlaybackSpeedCalls, [1.5]);
      expect(fake.setRepeatModeCalls, [RepeatMode.one]);
      expect(fake.setSelectedTrackCalls.single.trackId, 'nor');
      expect(fake.setSelectedTrackCalls.single.type, TrackType.audio);
    });

    test('mirrors state pushed through its notifier', () {
      final notifier = fake.stateNotifier.getPlayerNotifier('fake-player-1')!;

      notifier.setPlaybackState(PlaybackState.playing);

      expect(controller.value.playbackState, PlaybackState.playing);
    });

    test('proxies the seekable range from its notifier', () {
      final notifier = fake.stateNotifier.getPlayerNotifier('fake-player-1')!;

      notifier.setStateFromSnapshot(snapshot(
        playerId: 'fake-player-1',
        seekableRangeStartMs: 1000,
        seekableRangeEndMs: 9000,
      ));

      expect(controller.seekableRangeStartMs, 1000);
      expect(controller.seekableRangeEndMs, 9000);
    });

    test('tracks whether it is the primary player', () {
      expect(controller.isPrimary, isFalse);

      fake.stateNotifier.setPrimaryPlayer('fake-player-1');

      expect(controller.isPrimary, isTrue);
    });

    test('disposing the primary player is refused', () {
      fake.stateNotifier.setPrimaryPlayer('fake-player-1');

      // The assert fires in debug; release falls through to an early return
      // plus a debugPrint. Either way the primary player survives.
      expect(() => controller.dispose(), throwsAssertionError);
      expect(fake.disposePlayerCalls, isEmpty);
    });

    test('dispose tears down the native player', () async {
      await controller.dispose();

      expect(fake.disposePlayerCalls, ['fake-player-1']);
    });

    test('getTracks passes through the platform snapshot', () async {
      fake.tracks = PlayerTracksSnapshot(
        playerId: 'fake-player-1',
        audioTracks: [track(id: 'nor', language: 'nor', isSelected: true)],
        textTracks: [],
        videoTracks: [],
      );

      final tracks = await controller.getTracks();

      expect(tracks?.audioTracks.safe.single.id, 'nor');
    });
  });

  group('seek guards', () {
    late FakeBccmPlayerInterface fake;

    setUp(() => fake = FakeBccmPlayerInterface.install());
    tearDown(() => fake.restore());

    test('seekTo before initialize throws rather than seeking a nonexistent player', () {
      final controller = BccmPlayerController(mediaItem(id: 'a'));

      expect(() => controller.seekTo(Duration.zero), throwsException);
      expect(fake.seekToCalls, isEmpty);
    });

    test('seekToLive before initialize throws', () {
      final controller = BccmPlayerController(mediaItem(id: 'a'));

      expect(() => controller.seekToLive(), throwsException);
      expect(fake.seekToLiveCalls, isEmpty);
    });

    test('the seekable range reads as unknown before initialize', () {
      final controller = BccmPlayerController(mediaItem(id: 'a'));

      expect(controller.seekableRangeStartMs, isNull);
      expect(controller.seekableRangeEndMs, isNull);
    });

    test('the queue is unavailable before initialize', () {
      final controller = BccmPlayerController(mediaItem(id: 'a'));

      expect(() => controller.queue, throwsException);
    });
  });

  group('isChromecast', () {
    late FakeBccmPlayerInterface fake;

    setUp(() => fake = FakeBccmPlayerInterface.install());
    tearDown(() => fake.restore());

    test('is true only for the chromecast player id', () {
      final controller = BccmPlayerController.empty();
      expect(controller.isChromecast, isFalse);

      final cast = fake.stateNotifier.getOrAddPlayerNotifier('chromecast');
      controller.swapPlayerNotifier(cast);

      expect(controller.isChromecast, isTrue);
    });
  });

  group('attach / detach', () {
    late FakeBccmPlayerInterface fake;
    late BccmPlayerController controller;

    setUp(() async {
      fake = FakeBccmPlayerInterface.install();
      controller = BccmPlayerController(mediaItem(id: 'a'));
      await controller.initialize();
    });

    tearDown(() => fake.restore());

    test('currentPlayerView is the most recently attached view', () {
      final first = _FakePlayerView();
      final second = _FakePlayerView();

      controller.attach(first);
      expect(controller.currentPlayerView, same(first));

      controller.attach(second);
      expect(controller.currentPlayerView, same(second),
          reason: 'a newly attached view takes over rendering');
    });

    test('detaching falls back to the remaining view', () {
      final first = _FakePlayerView();
      final second = _FakePlayerView();
      controller.attach(first);
      controller.attach(second);

      controller.detach(second);

      expect(controller.currentPlayerView, same(first));
    });

    test('detaching the last view leaves none', () {
      final view = _FakePlayerView();
      controller.attach(view);

      controller.detach(view);

      expect(controller.currentPlayerView, isNull);
    });

    test('attach and detach both notify listeners', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      final view = _FakePlayerView();

      controller.attach(view);
      controller.detach(view);

      expect(notifications, 2);
    });

    test('attaching to a disposed controller is ignored', () async {
      await controller.dispose();

      controller.attach(_FakePlayerView());

      expect(controller.currentPlayerView, isNull);
    });
  });

  group('events', () {
    late FakeBccmPlayerInterface fake;
    late BccmPlayerController controller;

    setUp(() async {
      fake = FakeBccmPlayerInterface.install();
      controller = BccmPlayerController(mediaItem(id: 'a'));
      await controller.initialize();
    });

    tearDown(() => fake.restore());

    test('yields only events for this player, and survives events without a playerId', () async {
      final received = <Object?>[];
      final sub = controller.events.listen(received.add);
      addTearDown(sub.cancel);

      fake.emitPlayerEvent(PositionDiscontinuityEvent(playerId: 'fake-player-1'));
      fake.emitPlayerEvent(PositionDiscontinuityEvent(playerId: 'some-other-player'));
      // Pigeon has no inheritance, so the filter reads `playerId` off a dynamic
      // and has to tolerate values that simply don't have one.
      fake.emitPlayerEvent(Object());

      await Future.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect((received.single as PositionDiscontinuityEvent).playerId, 'fake-player-1');
    });

    test('stops yielding once the controller is disposed', () async {
      final received = <Object?>[];
      final sub = controller.events.listen(received.add);
      addTearDown(sub.cancel);

      await controller.dispose();
      fake.emitPlayerEvent(PositionDiscontinuityEvent(playerId: 'fake-player-1'));
      await Future.delayed(Duration.zero);

      expect(received, isEmpty);
    });
  });

  group('swapPlayerNotifier', () {
    late FakeBccmPlayerInterface fake;

    setUp(() => fake = FakeBccmPlayerInterface.install());
    tearDown(() => fake.restore());

    test('stops following the old notifier', () {
      // This is the cast-handover path. A leaked listener means two notifiers
      // both writing `value`, and the local player clobbering cast state.
      final controller = BccmPlayerController.empty();
      final local = fake.stateNotifier.getOrAddPlayerNotifier('local');
      final cast = fake.stateNotifier.getOrAddPlayerNotifier('chromecast');

      controller.swapPlayerNotifier(local);
      controller.swapPlayerNotifier(cast);

      local.setPlaybackState(PlaybackState.playing);
      expect(controller.value.playerId, 'chromecast');
      expect(controller.value.playbackState, isNot(PlaybackState.playing));

      cast.setPlaybackState(PlaybackState.paused);
      expect(controller.value.playbackState, PlaybackState.paused);
    });
  });

  group('BccmPlayerNative.primaryController', () {
    test('follows the primary player as it changes', () {
      // Installed as the real instance so the getter's
      // `BccmPlayerInterface.instance.stateNotifier` is its own. No channel is
      // touched until a method is actually called.
      final native = BccmPlayerNative();
      BccmPlayerInterface.instance = native;
      addTearDown(() {
        for (final n in [...native.stateNotifier.state.players.values]) {
          n.dispose(force: true);
        }
      });

      final controller = native.primaryController;
      expect(controller.value.playerId, 'unknown');

      native.stateNotifier.setPrimaryPlayer('p1');
      expect(controller.value.playerId, 'p1');

      native.stateNotifier.setPrimaryPlayer('chromecast');
      expect(controller.value.playerId, 'chromecast');
      expect(controller.isChromecast, isTrue);
    });

    test('is the same controller across reads', () {
      final native = BccmPlayerNative();
      BccmPlayerInterface.instance = native;

      expect(native.primaryController, same(native.primaryController));
    });
  });
}

/// A [State] stand-in for attach/detach bookkeeping. Never mounted — the
/// controller only ever holds it in a set and hands it back.
class _FakePlayerView extends State<VideoPlatformView> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
