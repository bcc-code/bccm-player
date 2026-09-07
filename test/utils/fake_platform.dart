import 'dart:async';

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A hand-written stand-in for the native platform.
///
/// [BccmPlayerInterface.instance] is a settable static guarded by
/// [PlatformInterface.verifyToken], and `_instance` is lazily initialised — so
/// assigning this fake before anything reads `instance` means [BccmPlayerNative]
/// (and therefore the pigeon channels) is never constructed at all.
///
/// Prefer this over the mockito mocks in `mocks.dart` whenever a test needs
/// *real* state management: `stateNotifier` is a field on the abstract class, so
/// a fake gets a working [PlayerPluginStateNotifier] for free. Use the mocks
/// instead when the point of the test is to verify an interaction.
///
/// Every call is recorded so tests can assert on what reached the platform.
class FakeBccmPlayerInterface extends BccmPlayerInterface with MockPlatformInterfaceMixin {
  FakeBccmPlayerInterface();

  /// Installs the fake and returns it. Call [restore] in `tearDown`.
  static FakeBccmPlayerInterface install() {
    final fake = FakeBccmPlayerInterface();
    BccmPlayerInterface.instance = fake;
    return fake;
  }

  /// Drops references held by the fake. The `instance` static itself cannot be
  /// reset to the real native implementation (and must not be, in tests), so
  /// each test installs a fresh fake over the previous one.
  void restore() {
    _playerEvents.close();
    _chromecastEvents.close();
    for (final notifier in stateNotifier.state.players.values) {
      notifier.dispose(force: true);
    }
  }

  // --- recorded calls -------------------------------------------------------

  final List<String> newPlayerCalls = [];
  final List<ReplaceMediaItemCall> replaceCurrentMediaItemCalls = [];
  final List<SeekCall> seekToCalls = [];
  final List<String> seekToLiveCalls = [];
  final List<String> playCalls = [];
  final List<String> pauseCalls = [];
  final List<String> stopCalls = [];
  final List<String> disposePlayerCalls = [];
  final List<String> setPrimaryCalls = [];
  final List<SelectedTrackCall> setSelectedTrackCalls = [];
  final List<double> setPlaybackSpeedCalls = [];
  final List<RepeatMode> setRepeatModeCalls = [];
  int openExpandedCastControllerCalls = 0;

  /// Value handed back by [newPlayer]. Incremented per call so successive
  /// players get distinct ids.
  int _nextPlayerId = 1;

  /// Value handed back by [getPlayerTracks].
  PlayerTracksSnapshot? tracks;

  /// Value handed back by [getPlayerState].
  PlayerStateSnapshot? playerStateSnapshot;

  final StreamController<Object?> _playerEvents = StreamController.broadcast();
  final StreamController<ChromecastEvent> _chromecastEvents = StreamController.broadcast();

  /// Pushes an event onto [playerEventStream], as the native side would.
  void emitPlayerEvent(Object? event) => _playerEvents.add(event);

  /// Pushes an event onto [chromecastEventStream].
  void emitChromecastEvent(ChromecastEvent event) => _chromecastEvents.add(event);

  // --- BccmPlayerInterface --------------------------------------------------

  @override
  Stream<Object?> get playerEventStream => _playerEvents.stream;

  @override
  Stream<ChromecastEvent> get chromecastEventStream => _chromecastEvents.stream;

  BccmPlayerController? _primaryController;

  @override
  BccmPlayerController get primaryController => _primaryController ??= BccmPlayerController.empty();

  @override
  Future<void> setup() async {}

  @override
  Future<String> newPlayer({BufferMode? bufferMode, bool? disableNpaw}) async {
    final id = 'fake-player-${_nextPlayerId++}';
    newPlayerCalls.add(id);
    stateNotifier.getOrAddPlayerNotifier(id);
    return id;
  }

  @override
  Future<void> disposePlayer(String playerId) async {
    disposePlayerCalls.add(playerId);
  }

  @override
  Future<bool> setPrimary(String id) async {
    setPrimaryCalls.add(id);
    stateNotifier.setPrimaryPlayer(id);
    return true;
  }

  @override
  Future<void> replaceCurrentMediaItem(
    String playerId,
    MediaItem mediaItem, {
    bool? playbackPositionFromPrimary,
    bool? autoplay = true,
  }) async {
    replaceCurrentMediaItemCalls.add(ReplaceMediaItemCall(
      playerId: playerId,
      mediaItem: mediaItem,
      playbackPositionFromPrimary: playbackPositionFromPrimary,
      autoplay: autoplay,
    ));
  }

  @override
  Future<void> seekTo(String playerId, double positionMs) async {
    seekToCalls.add(SeekCall(playerId: playerId, positionMs: positionMs));
  }

  @override
  Future<void> seekToLive(String playerId) async {
    seekToLiveCalls.add(playerId);
  }

  @override
  void play(String playerId) => playCalls.add(playerId);

  @override
  void pause(String playerId) => pauseCalls.add(playerId);

  @override
  void stop(String playerId, bool reset) => stopCalls.add(playerId);

  @override
  Future<void> setSelectedTrack(String playerId, TrackType type, String? trackId) async {
    setSelectedTrackCalls.add(SelectedTrackCall(playerId: playerId, type: type, trackId: trackId));
  }

  @override
  Future<void> setPlaybackSpeed(String playerId, double speed) async {
    setPlaybackSpeedCalls.add(speed);
  }

  @override
  Future<void> setRepeatMode(String playerId, RepeatMode repeatMode) async {
    setRepeatModeCalls.add(repeatMode);
  }

  @override
  Future<PlayerTracksSnapshot?> getPlayerTracks({String? playerId}) async => tracks;

  @override
  Future<PlayerStateSnapshot?> getPlayerState({String? playerId}) async => playerStateSnapshot;

  @override
  void openExpandedCastController() => openExpandedCastControllerCalls++;

  @override
  Future<MediaInfo> fetchMediaInfo({required String url, String? mimeType}) async {
    return MediaInfo(audioTracks: [], textTracks: [], videoTracks: []);
  }

  @override
  Future<int> getAndroidPerformanceClass() async => 0;
}

class ReplaceMediaItemCall {
  ReplaceMediaItemCall({
    required this.playerId,
    required this.mediaItem,
    required this.playbackPositionFromPrimary,
    required this.autoplay,
  });

  final String playerId;
  final MediaItem mediaItem;
  final bool? playbackPositionFromPrimary;
  final bool? autoplay;
}

class SeekCall {
  SeekCall({required this.playerId, required this.positionMs});

  final String playerId;
  final double positionMs;
}

class SelectedTrackCall {
  SelectedTrackCall({required this.playerId, required this.type, required this.trackId});

  final String playerId;
  final TrackType type;
  final String? trackId;
}
