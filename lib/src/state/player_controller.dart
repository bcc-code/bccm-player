import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../bccm_player.dart';
import '../pigeon/playback_platform_pigeon.g.dart';
import '../widgets/video/video_player_view_fullscreen.dart';

class BccmPlayerController extends ValueNotifier<PlayerState> {
  PlayerStateNotifier? _stateNotifier;
  RemoveListener? _removeStateListener;
  /* BccmPlayerConfiguration configuration; */
  final MediaItem? _intialMediaItem;
  NavigatorState? _currentFullscreenNavigator;
  StateNotifier<PlayerState>? get stateNotifier => _stateNotifier;

  BccmPlayerController(MediaItem mediaItem)
      : _intialMediaItem = mediaItem,
        super(const PlayerState(
          playerId: 'unknown',
          isInitialized: false,
        ));

  @protected
  BccmPlayerController.empty()
      : _intialMediaItem = null,
        super(const PlayerState(playerId: 'unknown', isInitialized: false));

  BccmPlayerController.networkUrl(
    Uri url, {
    String? mimeType,
  })  : _intialMediaItem = MediaItem(
          url: url.toString(),
          mimeType: mimeType,
        ),
        super(const PlayerState(playerId: 'unknown', isInitialized: false));

  void swapPlayerNotifier(PlayerStateNotifier notifier) {
    _listenToNotifier(notifier);
  }

  void _listenToNotifier(PlayerStateNotifier notifier) {
    _removeStateListener?.call();
    _removeStateListener = notifier.addListener((state) {
      value = state;
    });
    _stateNotifier = notifier;
  }

  bool get isPrimary => BccmPlayerInterface.instance.primaryController.value.playerId == value.playerId;

  @override
  Future<void> dispose() async {
    assert(
      !isPrimary,
      "The primary player can't be disposed",
    );
    if (isPrimary) {
      debugPrint("Warning: The primary player can't be disposed, but it was attempted.");
      return;
    }
    _removeStateListener?.call();
    super.dispose();
    return BccmPlayerInterface.instance.disposePlayer(value.playerId);
  }

  Future<void> initialize() async {
    if (value.isInitialized) {
      return;
    }
    final playerId = await BccmPlayerInterface.instance.newPlayer();
    if (_intialMediaItem != null) {
      await BccmPlayerInterface.instance.replaceCurrentMediaItem(playerId, _intialMediaItem!);
    }
    final notifier = BccmPlayerInterface.instance.stateNotifier.getOrAddPlayerNotifier(playerId);
    _listenToNotifier(notifier);
  }

  Future<void> replaceCurrentMediaItem(
    MediaItem mediaItem, {
    bool? autoplay = true,
    bool? playbackPositionFromPrimary,
  }) {
    return BccmPlayerInterface.instance.replaceCurrentMediaItem(
      value.playerId,
      mediaItem,
      autoplay: autoplay,
      playbackPositionFromPrimary: playbackPositionFromPrimary,
    );
  }

  Future<void> seekTo(Duration moment) {
    if (_stateNotifier == null) {
      throw Exception("Player is not initialized");
    }
    return BccmPlayerInterface.instance.seekTo(value.playerId, moment.inMilliseconds.toDouble());
  }

  Future<void> setPlaybackSpeed(double speed) {
    return BccmPlayerInterface.instance.setPlaybackSpeed(value.playerId, speed);
  }

  Future<void> pause() async {
    BccmPlayerInterface.instance.pause(value.playerId);
  }

  Future<void> play() async {
    BccmPlayerInterface.instance.play(value.playerId);
  }

  Future<PlayerTracksSnapshot?> getTracks() {
    return BccmPlayerInterface.instance.getPlayerTracks(playerId: value.playerId);
  }

  Future<void> setSelectedTrack(TrackType type, String? trackId) {
    return BccmPlayerInterface.instance.setSelectedTrack(value.playerId, type, trackId);
  }

  void setPrimary() {
    BccmPlayerInterface.instance.setPrimary(value.playerId);
  }

  void exitFullscreen(String playerId) {
    if (_currentFullscreenNavigator != null) {
      _currentFullscreenNavigator?.maybePop();
    } else {
      BccmPlayerInterface.instance.exitFullscreen(playerId);
    }
  }

  /// Sets to mix audio with other apps/players.
  /// Untested on iOS, might be a bit buggy because we are setting this setting multiple places.
  Future<void> setMixWithOthers(bool bool) {
    return BccmPlayerInterface.instance.setMixWithOthers(value.playerId, bool);
  }

  Future enterFullscreen({
    bool? useNativeControls = false,
    BuildContext? context,
    void Function()? resetSystemOverlays,
    WidgetBuilder? playNextButton,
  }) async {
    if (useNativeControls == true) {
      return BccmPlayerInterface.instance.enterFullscreen(value.playerId);
    } else if (context == null) {
      throw ErrorDescription('enterFullscreen: context cant be null if useNativeControls is false.');
    }
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    debugPrint('bccm: setPreferredOrientations landscape');

    _stateNotifier?.setIsFlutterFullscreen(true);
    _currentFullscreenNavigator = Navigator.of(context, rootNavigator: true);
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, aAnim, bAnim) => VideoPlayerViewFullscreen(
          controller: this,
          playNextButton: playNextButton,
        ),
        transitionsBuilder: (context, aAnim, bAnim, child) => FadeTransition(
          opacity: aAnim,
          child: child,
        ),
        fullscreenDialog: true,
      ),
    );

    if (resetSystemOverlays != null) {
      resetSystemOverlays();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    debugPrint('bccm: setPreferredOrientations portraitUp');

    _stateNotifier?.setIsFlutterFullscreen(false);
    WakelockPlus.disable();
  }
}
