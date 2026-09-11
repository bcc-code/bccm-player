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
  bool _showPlayerControls = false;
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

  /// The single view type for every player. It must match the one
  /// `_WebPlayer` passes to [HtmlElementView].
  ///
  /// One registration for the whole plugin rather than one per player:
  /// [PlatformViewRegistry] has no unregister, and its factory map lives for the
  /// process, so a per-player view type leaks an entry — and, through the
  /// closure, the whole player — for every player ever created. The player id
  /// travels as `creationParams` instead.
  static const viewType = 'bccm-player';

  static final Map<String, VideoJsPlayer> _byPlayerId = {};
  static bool _viewFactoryRegistered = false;
  static bool _stylesInjected = false;

  static const _containerClass = 'bccm-player-container';
  static const _hideUiClass = 'bccm-player-hide-ui';

  /// One stylesheet for the plugin rather than one per player.
  ///
  /// The class names are the skin's own (`media-controls`, `media-overlay`,
  /// `bccm-center-controls`). It is a fully custom skin with no `vjs-` classes
  /// anywhere, so anything matching on those silently does nothing.
  static void _ensureStylesInjected() {
    if (_stylesInjected) return;
    _stylesInjected = true;
    final style = web.document.createElement('style') as web.HTMLStyleElement;
    style.textContent = '''
.$_containerClass > * { width: 100%; height: 100%; }

/* Inline, Flutter draws the controls, so the skin's own UI is hidden. It comes
   back in fullscreen, where the Flutter overlay is outside the fullscreened
   element and therefore not visible. */
.$_hideUiClass .media-controls,
.$_hideUiClass .media-overlay,
.$_hideUiClass .bccm-center-controls { display: none !important; }
''';
    web.document.head?.appendChild(style);
  }

  /// Keeps the skin's visibility and interactivity in step with fullscreen.
  ///
  /// Driven from Dart rather than CSS: Flutter's `IgnorePointer` cannot stop a
  /// platform view from receiving events, because it is a real DOM element
  /// getting real browser events. That is what made a single tap hit both the
  /// Flutter button and the skin's.
  ///
  /// `inert` rather than `pointer-events: none`, because the skin can still
  /// hold keyboard focus while hidden. Flutter marks the platform view
  /// `aria-hidden`, so a focused element inside it is a real accessibility
  /// violation — browsers warn about exactly this and suggest `inert`, which
  /// blocks pointer events, focus and assistive-tech access together.
  void _syncPlayerUi([web.HTMLElement? element]) {
    final container = element ?? _container;
    if (container == null) return;
    // Fullscreen always needs them: the Flutter overlay sits outside the
    // fullscreened element, so its controls are not visible there.
    final showSkin = _showPlayerControls || _isFullscreen;
    if (showSkin) {
      container.classList.remove(_hideUiClass);
    } else {
      container.classList.add(_hideUiClass);
    }
    container.inert = !showSkin;
    // Something inside may already hold focus when the skin is hidden. Only
    // blur if the focus is actually ours — never steal it from the app.
    final focused = web.document.activeElement;
    if (!showSkin && focused != null && container.contains(focused)) {
      (focused as web.HTMLElement).blur();
    }
  }

  /// Whether the player draws its own controls, as [VideoPlatformView.showControls]
  /// asks for. Applied when the view is created, so a player shown in two views
  /// at once follows whichever was built last.
  void setShowPlayerControls(bool value) {
    if (_showPlayerControls == value) return;
    _showPlayerControls = value;
    _syncPlayerUi();
  }

  static void _ensureViewFactoryRegistered() {
    if (_viewFactoryRegistered) return;
    _viewFactoryRegistered = true;
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId, {Object? params}) {
        final args = params as Map<Object?, Object?>?;
        final player = _byPlayerId[args?['playerId']];
        player?.setShowPlayerControls(args?['showControls'] == true);
        // A view can outlive its player (a stale widget rebuilding, say). An
        // empty div keeps that a blank frame rather than an exception.
        return player?._obtainContainer() ?? web.document.createElement('div');
      },
    );
  }

  /// True while this player's container is the fullscreen element. Tracked
  /// from the document rather than from our own calls, because the user can
  /// leave fullscreen with Esc or the player's own button.
  bool get _isFullscreen => _container != null && web.document.fullscreenElement == _container;

  /// The DOM id of this player's container. Distinct per player because
  /// `createPlayer` resolves the container by id.
  String get elementId => 'bccm-player-$playerId';

  VideoJsPlayer(
    this.playerId, {
    required this.listener,
    required this.plugin,
  }) {
    _ensureViewFactoryRegistered();
    _ensureStylesInjected();
    _byPlayerId[playerId] = this;

    // Entering or leaving fullscreen changes which controls are showing, so the
    // state has to be republished even though no media event fired.
    web.document.addEventListener('fullscreenchange', ((web.Event _) {
      _syncPlayerUi();
      _emitState();
    }).toJS);

    // VideoPlatformView refuses to mount the platform view until the player
    // reports `isInitialized`, and the container only exists once it mounts.
    // Emitting an empty snapshot up front breaks that circular wait.
    _emitState();
  }

  web.HTMLElement _obtainContainer() {
    final existing = _container;
    if (existing != null) {
      return existing;
    }
    final container = web.document.createElement('div') as web.HTMLElement;
    container.id = elementId;
    container.style
      ..width = '100%'
      ..height = '100%'
      ..backgroundColor = '#000000';

    container.classList.add(_containerClass);
    _syncPlayerUi(container);

    _container = container;
    if (!_containerReady.isCompleted) {
      _containerReady.complete(container);
    }
    return container;
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
      elementId,
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
      isFullscreen: _isFullscreen,
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
    _byPlayerId.remove(playerId);
    _player?.dispose();
    _player = null;
    _container?.remove();
    _container = null;
  }
}
