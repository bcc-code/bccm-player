// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.

import 'dart:async';
import 'dart:js_interop';

import 'package:bccm_player/src/native/root_pigeon_playback_listener.dart';
import 'package:bccm_player/src/state/state_playback_listener.dart';
import 'package:bccm_player/src/web/downloader_web.dart';
import 'package:bccm_player/src/widgets/video/web_player_overlay.dart';
import 'package:web/web.dart' as web;
import 'package:bccm_player/src/web/js/bccm_video_player.dart' as js;
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart' as pigeon;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'bccm_player.dart';
import 'src/web/video_js_player.dart';

/// A web implementation of the BccmPlayerPlatform of the BccmPlayer plugin.
class BccmPlayerWeb extends BccmPlayerInterface {
  AppConfig? appConfig;
  NpawConfig? npawConfig;
  Map<String, VideoJsPlayer> webVideoPlayers = {};
  final RootPigeonPlaybackListener _rootPlaybackListener = RootPigeonPlaybackListener();
  BccmPlayerController? _primaryController;

  /// Mirrors the native implementations: one long-lived controller that follows
  /// whichever player is currently primary, rather than a controller per player.
  @override
  BccmPlayerController get primaryController {
    final existing = _primaryController;
    if (existing != null) {
      return existing;
    }
    final controller = BccmPlayerController.empty();
    stateNotifier.addListener(
      (state) {
        final id = state.primaryPlayerId;
        if (id == null || id == controller.value.playerId) return;
        final notifier = stateNotifier.getPlayerNotifier(id);
        if (notifier != null) {
          controller.swapPlayerNotifier(notifier);
        }
      },
      fireImmediately: true,
    );
    return _primaryController = controller;
  }

  Future<void>? _setupFuture;

  @override
  Future<void> setup() async => _setupFuture ??= _setup();

  Future<void> _setup() async {
    // Without this the pigeon events emitted by VideoJsPlayer go nowhere: it is
    // what turns them into PlayerState. The native implementation does the same.
    _rootPlaybackListener.addListener(StatePlaybackListener(stateNotifier));
    // The native side creates a primary player while attaching; on web there is
    // nothing to attach to, so we create it here. Without it `primaryController`
    // has no notifier and throws on first use.
    final playerId = await newPlayer();
    await setPrimary(playerId);
  }

  static void registerWith(Registrar registrar) {
    BccmPlayerInterface.instance = BccmPlayerWeb();
    // Otherwise this stays DownloaderNative and every call fails against a
    // pigeon channel that does not exist on web.
    DownloaderInterface.instance = DownloaderWeb();
  }

  @override
  get chromecastEventStream => const Stream.empty();

  @override
  get playerEventStream => _rootPlaybackListener.stream;

  @override
  Future<String> newPlayer({BufferMode? bufferMode, bool? disableNpaw}) async {
    final playerId = DateTime.now().microsecondsSinceEpoch.toString();
    final player = VideoJsPlayer(playerId, listener: _rootPlaybackListener, plugin: this);
    webVideoPlayers[playerId] = player;
    stateNotifier.getOrAddPlayerNotifier(playerId);
    return playerId;
  }

  @override
  Future<void> replaceCurrentMediaItem(
    String playerId,
    pigeon.MediaItem mediaItem, {
    bool? playbackPositionFromPrimary,
    bool? autoplay = true,
  }) async {
    webVideoPlayers[playerId]?.replaceCurrentMediaItem(
      mediaItem,
      autoplay: autoplay,
    );
  }

  @override
  Future<bool> setPrimary(String id) async {
    stateNotifier.setPrimaryPlayer(id);
    return true;
  }

  @override
  Future<pigeon.ChromecastState?> getChromecastState() async {
    return null;
  }

  @override
  void openExpandedCastController() {}

  @override
  void openCastDialog() {}

  @override
  Future<void> addPlaybackListener(pigeon.PlaybackListenerPigeon listener) async {
    _rootPlaybackListener.addListener(listener);
  }

  @override
  void play(String playerId) {
    // play() rejects with AbortError if a pause() lands before it resolves,
    // which is routine when toggling quickly. Swallow it rather than letting it
    // surface as an unhandled rejection.
    webVideoPlayers[playerId]?.mediaElement?.play().toDart.catchError((_) => null);
  }

  @override
  void pause(String playerId) {
    webVideoPlayers[playerId]?.mediaElement?.pause();
  }

  @override
  void stop(String playerId, bool reset) {
    final media = webVideoPlayers[playerId]?.mediaElement;
    if (media == null) return;
    media.pause();
    if (reset) media.currentTime = 0;
  }

  @override
  Future<void> seekTo(String playerId, double positionMs) async {
    webVideoPlayers[playerId]?.mediaElement?.currentTime = positionMs / 1000;
  }

  /// Jumps to the live edge, i.e. the end of the DVR window the browser reports.
  @override
  Future<void> seekToLive(String playerId) async {
    final media = webVideoPlayers[playerId]?.mediaElement;
    if (media == null) return;
    final seekable = media.seekable;
    if (seekable.length == 0) return;
    media.currentTime = seekable.end(seekable.length - 1);
  }

  @override
  Future<void> setVolume(String playerId, double volume) async {
    webVideoPlayers[playerId]?.mediaElement?.volume = volume;
  }

  @override
  Future<void> setPlaybackSpeed(String playerId, double speed) async {
    webVideoPlayers[playerId]?.mediaElement?.playbackRate = speed;
  }

  @override
  Future<void> disposePlayer(String playerId) async {
    webVideoPlayers.remove(playerId)?.dispose();
    WebPlayerOverlay.disposeFor(playerId);
    // Disposing the notifier is what unregisters it from the plugin state.
    stateNotifier.getPlayerNotifier(playerId)?.dispose(force: true);
  }

  @override
  Future<PlayerTracksSnapshot?> getPlayerTracks({String? playerId}) async {
    final id = playerId ?? stateNotifier.getPrimaryPlayerId();
    final player = id != null ? webVideoPlayers[id]?.jsPlayer : null;
    if (id == null || player == null) return null;
    return PlayerTracksSnapshot(
      playerId: id,
      audioTracks: _toTracks(player.getAudioLanguages().toDart),
      textTracks: _toTracks(player.getSubtitleLanguages().toDart),
      // Quality is selected by height rather than enumerated as tracks.
      videoTracks: const [],
    );
  }

  @override
  Future<void> setSelectedTrack(String playerId, pigeon.TrackType type, String? trackId) async {
    final player = webVideoPlayers[playerId]?.jsPlayer;
    if (player == null) return;
    switch (type) {
      case pigeon.TrackType.audio:
        player.setAudioTrackToLanguage(trackId);
      case pigeon.TrackType.text:
        player.setSubtitleTrackToLanguage(trackId);
      case pigeon.TrackType.video:
        final height = int.tryParse(trackId ?? '');
        if (height != null) player.setVideoQuality(height);
    }
  }

  /// The JS package keys tracks by language, so the language doubles as the id.
  List<pigeon.Track> _toTracks(List<js.TrackOption> options) => options
      .map((o) => pigeon.Track(id: o.language, language: o.language, label: o.label, isSelected: false))
      .toList();

  @override
  Future setNpawConfig(pigeon.NpawConfig? config) async {
    npawConfig = config;
  }

  @override
  Future startNpawView(String playerId, pigeon.MediaMetadata? metadata) async {
    final player = webVideoPlayers[playerId]?.jsPlayer;
    final config = npawConfig;
    if (player == null || config?.accountCode == null) return;
    js.restartNPAWView(
      player,
      js.NpawOptions(
        enabled: true,
        accountCode: config!.accountCode,
        appName: config.appName ?? '',
        tracking: js.NpawTrackingOptions(
          userId: appConfig?.analyticsId,
          sessionId: appConfig?.sessionId?.toString(),
          metadata: js.NpawMetadataOptions(title: metadata?.title),
        ),
      ),
    );
  }

  @override
  Future<void> removePlaybackListener(pigeon.PlaybackListenerPigeon listener) async {
    _rootPlaybackListener.removeListener(listener);
  }

  @override
  Future<pigeon.PlayerStateSnapshot?> getPlayerState({String? playerId}) async {
    final id = playerId ?? stateNotifier.getPrimaryPlayerId();
    return id != null ? webVideoPlayers[id]?.currentSnapshot : null;
  }

  /// No audio-session concept on the web; every player mixes by default.
  @override
  Future<void> setMixWithOthers(String playerId, bool mixWithOthers) async {}

  /// Fullscreened in place via the browser API. A Flutter fullscreen route
  /// would re-parent the platform view's element and detach the media, so the
  /// element must never move.
  @override
  Future<void> enterFullscreen(String playerId) async {
    final container = webVideoPlayers[playerId]?.container;
    if (container == null) return;
    await container.requestFullscreen().toDart;

    // Resolve only once fullscreen ends, so callers can await it the same way
    // they await the fullscreen route on other platforms. The user can leave
    // via Esc or the player's own button, so the document is the source of
    // truth rather than our own exitFullscreen call.
    final exited = Completer<void>();
    late final JSFunction onChange;
    onChange = ((web.Event _) {
      if (web.document.fullscreenElement == container) return;
      web.document.removeEventListener('fullscreenchange', onChange);
      if (!exited.isCompleted) exited.complete();
    }).toJS;
    web.document.addEventListener('fullscreenchange', onChange);
    return exited.future;
  }

  @override
  void exitFullscreen(String playerId) {
    if (web.document.fullscreenElement != null) {
      web.document.exitFullscreen();
    }
  }

  /// Looping is not wired through to the media element yet; ignored rather than
  /// throwing so it cannot break an otherwise working player.
  @override
  Future<void> setRepeatMode(String playerId, pigeon.RepeatMode repeatMode) async {}

  /// Android-only concept.
  @override
  Future<int> getAndroidPerformanceClass() async => 0;

  @override
  void setAppConfig(pigeon.AppConfig? config) {
    appConfig = config;
  }

  @override
  void setPlayerViewVisibility(int viewId, bool visible) {}

  /// Would need a throwaway player to probe the manifest; not supported yet.
  @override
  Future<pigeon.MediaInfo> fetchMediaInfo({required String url, String? mimeType}) {
    throw UnsupportedError('fetchMediaInfo is not supported on web.');
  }

  /// The web player composes as a DOM element, so there is no texture to share.
  @override
  Future<int> createVideoTexture() => throw UnsupportedError('Video textures are not supported on web.');

  @override
  Future<bool> disposeVideoTexture(int textureId) => throw UnsupportedError('Video textures are not supported on web.');

  @override
  Future<int> switchToVideoTexture(String playerId, int textureId) =>
      throw UnsupportedError('Video textures are not supported on web.');
}
