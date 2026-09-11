import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../../bccm_player_web.dart';
import 'js/bccm_video_player.dart' as js;

const lanTo3letter = {
  'no': "nor",
  'en': "eng",
  'nl': "nld",
  'de': "deu",
  'fr': "fra",
  'es': "spa",
  'fi': "fin",
  'ru': "rus",
  'pt': "por",
  'ro': "ron",
  'tr': "tur",
  'pl': "pol",
  'hu': "hun",
  'it': "ita",
  'da': "dan",
};

/// Wraps one `bccm-video-player` instance and adapts it to the plugin's
/// platform interface.
///
/// The player is mounted into an element owned by this class and handed to
/// Flutter through [ui_web.platformViewRegistry], so it composes inside the
/// widget tree rather than floating above it as an overlay.
///
/// The same element is returned every time the factory is invoked. Flutter
/// builds a second [HtmlElementView] with this view type when the fullscreen
/// route pushes, and appending an element elsewhere moves it — which is what
/// keeps one live player across the transition instead of two half-dead ones.
class VideoJsPlayer {
  final String playerId;
  final PlaybackListenerPigeon listener;
  final BccmPlayerWeb plugin;

  final _containerReady = Completer<web.HTMLElement>();
  web.HTMLElement? _container;
  js.Player? _player;
  MediaItem? _currentMediaItem;
  bool _isBuffering = false;
  PlaybackState _playbackState = PlaybackState.stopped;

  /// The underlying `<video>`, once the player has been created. Playback
  /// commands go straight to it — the JS package intentionally does not wrap
  /// the standard media API.
  web.HTMLVideoElement? get mediaElement => _player?.mediaEl;

  js.Player? get jsPlayer => _player;

  /// The element handed to Flutter's platform view. Fullscreen is requested on
  /// this rather than on the `<video>`, so the player's own control bar stays
  /// visible while fullscreen.
  web.HTMLElement? get container => _container;

  String get viewType => 'bccm-player-$playerId';

  VideoJsPlayer(
    this.playerId, {
    required this.listener,
    required this.plugin,
  }) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final existing = _container;
      if (existing != null) {
        return existing;
      }
      final container = web.document.createElement('div') as web.HTMLElement;
      container.id = viewType;
      container.style
        ..width = '100%'
        ..height = '100%'
        ..backgroundColor = '#000000';

      // video.js sizes itself from its own element, not the container.
      final style = web.document.createElement('style') as web.HTMLStyleElement;
      style.textContent = '#$viewType > .video-js { width: 100%; height: 100% }';
      container.appendChild(style);

      _container = container;
      if (!_containerReady.isCompleted) {
        _containerReady.complete(container);
      }
      return container;
    });

    // VideoPlatformView refuses to mount the platform view until the player
    // reports `isInitialized`, and the container only exists once it mounts.
    // Emitting an empty snapshot up front breaks that circular wait.
    _emitState();
  }

  Future<void> replaceCurrentMediaItem(MediaItem mediaItem, {bool? autoplay}) async {
    assert(mediaItem.url != null);
    _currentMediaItem = mediaItem;

    // createPlayer looks the container up by id, so it must actually be in the
    // document. Flutter calling the view factory is not enough: it inserts the
    // element into the view slot afterwards, and it detaches it again whenever
    // the view unmounts (navigating between tabs, for instance).
    final container = await _awaitAttachedContainer();
    if (container == null) {
      debugPrint('bccm: player view for $playerId never attached; not creating a player.');
      return;
    }

    _player?.dispose();
    _player = await createPlayer(mediaItem, autoplay: autoplay).toDart;
    _attachMediaListeners();

    listener.onMediaItemTransition(
      MediaItemTransitionEvent(playerId: playerId, mediaItem: mediaItem),
    );
    _emitState();
  }

  JSPromise<js.Player> createPlayer(MediaItem mediaItem, {bool? autoplay}) {
    final npawExtraEntries = mediaItem.metadata?.extras?.entries
        .where((e) => e.key != null && e.key?.startsWith('npaw.') == true)
        .map((e) => MapEntry(e.key!.replaceFirst('npaw.', ''), e.value));
    // Converted to a JS object because a Dart Map is not a valid interop type.
    final npawOverrides = npawExtraEntries != null ? Map.fromEntries(npawExtraEntries).jsify() as JSObject? : null;

    return js.createPlayer(
      viewType,
      js.Options(
        src: js.SrcOptions(src: mediaItem.url!, type: mediaItem.mimeType ?? 'application/x-mpegURL'),
        languagePreferenceDefaults: js.LanguagePreferenceDefaults(
          audio: lanTo3letter[plugin.appConfig?.audioLanguages.firstOrNull],
          subtitles: lanTo3letter[plugin.appConfig?.subtitleLanguages.firstOrNull],
        ),
        autoplay: autoplay ?? true,
        live: mediaItem.isLive,
        npaw: js.NpawOptions(
          enabled: plugin.npawConfig?.accountCode != null,
          accountCode: plugin.npawConfig?.accountCode,
          appName: plugin.npawConfig?.appName ?? '',
          tracking: js.NpawTrackingOptions(
            isLive: mediaItem.isLive,
            userId: plugin.appConfig?.analyticsId,
            sessionId: plugin.appConfig?.sessionId?.toString(),
            metadata: js.NpawMetadataOptions(
              title: mediaItem.metadata?.title,
              overrides: npawOverrides,
            ),
          ),
        ),
      ),
    );
  }

  /// Resolves once the container is both created and actually in the document.
  ///
  /// Polling rather than observing: the element is created by Flutter's view
  /// factory and attached by the engine a frame or more later, and there is no
  /// callback for that.
  Future<web.HTMLElement?> _awaitAttachedContainer({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final container = await _containerReady.future;
    if (container.isConnected) return container;

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (container.isConnected) return container;
    }
    return null;
  }

  /// Everything the plugin reports as player state comes from the standard
  /// media events on the `<video>` element.
  void _attachMediaListeners() {
    final media = _player?.mediaEl;
    if (media == null) return;

    void on(String type, void Function() handler) {
      media.addEventListener(type, ((web.Event _) => handler()).toJS);
    }

    on('playing', () {
      _playbackState = PlaybackState.playing;
      _isBuffering = false;
      _emitPlaybackState();
    });
    on('play', () {
      _playbackState = PlaybackState.playing;
      _emitPlaybackState();
    });
    on('pause', () {
      _playbackState = PlaybackState.paused;
      _emitPlaybackState();
    });
    on('waiting', () {
      _isBuffering = true;
      _emitPlaybackState();
    });
    on('ended', () {
      _playbackState = PlaybackState.stopped;
      _emitPlaybackState();
      listener.onPlaybackEnded(PlaybackEndedEvent(playerId: playerId, mediaItem: _currentMediaItem));
    });
    on('timeupdate', _emitState);
    on('durationchange', _emitState);
    on('volumechange', _emitState);
    on('ratechange', _emitState);
    on('seeked', () {
      listener.onPositionDiscontinuity(
        PositionDiscontinuityEvent(playerId: playerId, playbackPositionMs: _positionMs),
      );
      _emitState();
    });
  }

  double? get _positionMs {
    final media = _player?.mediaEl;
    if (media == null) return null;
    final seconds = media.currentTime;
    return seconds.isFinite ? seconds * 1000 : null;
  }

  /// The DVR window, straight off `HTMLMediaElement.seekable`.
  (double?, double?) get _seekableRangeMs {
    final media = _player?.mediaEl;
    if (media == null) return (null, null);
    final seekable = media.seekable;
    if (seekable.length == 0) return (null, null);
    final start = seekable.start(0);
    final end = seekable.end(seekable.length - 1);
    return (start.isFinite ? start * 1000 : null, end.isFinite ? end * 1000 : null);
  }

  void _emitPlaybackState() {
    listener.onPlaybackStateChanged(
      PlaybackStateChangedEvent(
        playerId: playerId,
        playbackState: _playbackState,
        isBuffering: _isBuffering,
      ),
    );
    _emitState();
  }

  /// The player's state right now, read straight off the media element.
  PlayerStateSnapshot get currentSnapshot {
    final media = _player?.mediaEl;
    final (rangeStart, rangeEnd) = _seekableRangeMs;
    return PlayerStateSnapshot(
      playerId: playerId,
      playbackState: _playbackState,
      isBuffering: _isBuffering,
      isFullscreen: false,
      playbackSpeed: media?.playbackRate ?? 1.0,
      videoSize: media != null && media.videoWidth > 0 && media.videoHeight > 0
          ? VideoSize(width: media.videoWidth, height: media.videoHeight)
          : null,
      currentMediaItem: _withDuration(_currentMediaItem, media?.duration ?? double.nan),
      playbackPositionMs: _positionMs,
      volume: media?.volume,
      seekableRangeStartMs: rangeStart,
      seekableRangeEndMs: rangeEnd,
    );
  }

  void _emitState() {
    listener.onPlayerStateUpdate(
      PlayerStateUpdateEvent(playerId: playerId, snapshot: currentSnapshot),
    );
  }

  /// The media item arrives from Dart without a duration; the browser is the
  /// only thing that knows it. Copied rather than mutated: the pigeon classes
  /// are mutable but now carry value equality, so editing one in place makes it
  /// compare equal to the state it replaced and the update is dropped.
  MediaItem? _withDuration(MediaItem? item, double durationSeconds) {
    if (item == null || !durationSeconds.isFinite) return item;
    return MediaItem(
      id: item.id,
      url: item.url,
      mimeType: item.mimeType,
      isLive: item.isLive,
      isOffline: item.isOffline,
      playbackStartPositionMs: item.playbackStartPositionMs,
      lastKnownAudioLanguage: item.lastKnownAudioLanguage,
      lastKnownSubtitleLanguage: item.lastKnownSubtitleLanguage,
      metadata: MediaMetadata(
        artworkUri: item.metadata?.artworkUri,
        title: item.metadata?.title,
        artist: item.metadata?.artist,
        extras: item.metadata?.extras,
        durationMs: durationSeconds * 1000,
      ),
    );
  }

  void dispose() {
    _player?.dispose();
    _player = null;
    _container?.remove();
    _container = null;
  }
}
