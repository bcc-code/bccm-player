import 'package:bccm_player/src/pigeon/chromecast_pigeon.g.dart';
import 'package:bccm_player/src/native/root_pigeon_playback_listener.dart';
import 'package:bccm_player/src/native/chromecast_pigeon_listener.dart';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:bccm_player/src/state/state_playback_listener.dart';
import 'package:flutter/widgets.dart';

import 'bccm_player.dart';

/// An implementation of [BccmPlayerPlatform] that uses pigeon.
class BccmPlayerNative extends BccmPlayerInterface {
  final PlaybackPlatformPigeon _pigeon = PlaybackPlatformPigeon();
  late final RootPigeonPlaybackListener _rootPlaybackListener;
  final ChromecastPigeonListener _chromecastListener = ChromecastPigeonListener();
  BccmPlayerController? _primaryController;
  void Function()? _removePrimaryPlayerListener;
  Future<void>? setupFuture;

  /// This class is currently long lived so dispose is not used
  void dispose() {
    _removePrimaryPlayerListener?.call();
  }

  @override
  get primaryController {
    if (_primaryController != null) {
      return _primaryController!;
    } else {
      final controller = BccmPlayerController.empty();
      _removePrimaryPlayerListener = BccmPlayerInterface.instance.stateNotifier.addListener((state) {
        if (state.primaryPlayerId != controller.value.playerId) {
          final id = state.primaryPlayerId;
          if (id != null) {
            final notifier = BccmPlayerInterface.instance.stateNotifier.getPlayerNotifier(id);
            assert(notifier != null, 'Something went wrong. Primary player should always have a notifier. id was $id');
            if (notifier != null) {
              // ignore: invalid_use_of_protected_member
              controller.swapPlayerNotifier(notifier);
            }
          }
        }
      }, fireImmediately: true);
      return _primaryController = controller;
    }
  }

  @override
  get chromecastEventStream => _chromecastListener.stream;

  @override
  get playerEventStream => _rootPlaybackListener.stream;

  @override
  Future<void> setup() async {
    return setupFuture ??= _setup();
  }

  Future<void> _setup() async {
    WidgetsFlutterBinding.ensureInitialized();
    await _pigeon.attach();
    _rootPlaybackListener = RootPigeonPlaybackListener(this);
    _rootPlaybackListener.addListener(StatePlaybackListener(stateNotifier));
    ChromecastPigeon.setup(_chromecastListener);
    PlaybackListenerPigeon.setup(_rootPlaybackListener);
    // load primary player state
    final initialState = await getPlayerState();
    if (initialState != null) {
      stateNotifier.getOrAddPlayerNotifier(initialState.playerId).setStateFromSnapshot(initialState);
      stateNotifier.setPrimaryPlayer(initialState.playerId);
    }
  }

  @override
  Future<String> newPlayer({BufferMode? bufferMode, bool? disableNpaw}) async {
    final playerId = await _pigeon.newPlayer(bufferMode, disableNpaw);
    stateNotifier.getOrAddPlayerNotifier(playerId);
    return playerId;
  }

  @override
  Future<void> disposePlayer(String playerId) {
    return _pigeon.disposePlayer(playerId);
  }

  @override
  Future<bool> setPrimary(String id) async {
    await _pigeon.setPrimary(id);
    return true;
  }

  @override
  Future<void> replaceCurrentMediaItem(String playerId, MediaItem mediaItem, {bool? playbackPositionFromPrimary, bool? autoplay = true}) async {
    debugPrint('player replace');
    await _pigeon.replaceCurrentMediaItem(playerId, mediaItem, playbackPositionFromPrimary, autoplay);
  }

  @override
  Future<void> queueMediaItem(String playerId, MediaItem mediaItem) {
    return _pigeon.queueMediaItem(playerId, mediaItem);
  }

  @override
  Future<ChromecastState?> getChromecastState() {
    return _pigeon.getChromecastState();
  }

  @override
  Future<PlayerTracksSnapshot?> getPlayerTracks({String? playerId}) {
    return _pigeon.getTracks(playerId);
  }

  @override
  Future<PlayerStateSnapshot?> getPlayerState({String? playerId}) {
    return _pigeon.getPlayerState(playerId);
  }

  @override
  void openExpandedCastController() {
    _pigeon.openExpandedCastController();
  }

  @override
  void openCastDialog() {
    _pigeon.openCastDialog();
  }

  @override
  Future<void> addPlaybackListener(PlaybackListenerPigeon listener) async {
    _rootPlaybackListener.addListener(listener);
  }

  @override
  void play(String playerId) {
    _pigeon.play(playerId);
  }

  @override
  Future<void> seekTo(String playerId, double positionMs) {
    return _pigeon.seekTo(playerId, positionMs);
  }

  @override
  void pause(String playerId) {
    _pigeon.pause(playerId);
  }

  @override
  void stop(String playerId, bool reset) {
    debugPrint('player stop');
    _pigeon.stop(playerId, reset);
  }

  @override
  Future<void> setSelectedTrack(String playerId, TrackType type, String? trackId) {
    return _pigeon.setSelectedTrack(playerId, type, trackId);
  }

  @override
  Future<void> setPlaybackSpeed(String playerId, double speed) {
    return _pigeon.setPlaybackSpeed(playerId, speed);
  }

  @override
  Future<void> setVolume(String playerId, double volume) {
    return _pigeon.setVolume(playerId, volume);
  }

  @override
  void exitFullscreen(String playerId) {
    _pigeon.exitFullscreen(playerId);
  }

  @override
  Future<void> enterFullscreen(String playerId) {
    return _pigeon.enterFullscreen(playerId);
  }

  @override
  Future setNpawConfig(NpawConfig? config) {
    return _pigeon.setNpawConfig(config);
  }

  @override
  void setAppConfig(AppConfig? config) {
    _pigeon.setAppConfig(config);
  }

  @override
  void setPlayerViewVisibility(int viewId, bool visible) {
    _pigeon.setPlayerViewVisibility(viewId, visible);
  }

  @override
  Future<void> setMixWithOthers(String playerId, bool mixWithOthers) {
    return _pigeon.setMixWithOthers(playerId, mixWithOthers);
  }

  @override
  Future<MediaInfo> fetchMediaInfo({required String url, String? mimeType}) {
    return _pigeon.fetchMediaInfo(url, mimeType);
  }

  @override
  Future<int> switchToVideoTexture(String playerId, int textureId) {
    return _pigeon.switchToVideoTexture(playerId, textureId);
  }

  @override
  Future<int> createVideoTexture() {
    return _pigeon.createVideoTexture();
  }

  @override
  Future<bool> disposeVideoTexture(int textureId) {
    return _pigeon.disposeVideoTexture(textureId);
  }

  @override
  Future<void> setRepeatMode(String playerId, RepeatMode repeatMode) {
    return _pigeon.setRepeatMode(playerId, repeatMode);
  }
}
