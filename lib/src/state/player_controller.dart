import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../bccm_player.dart';
import '../widgets/video/video_player_view_fullscreen.dart';

class BccmPlayerController extends ValueNotifier<PlayerState> {
  PlayerStateNotifier? _stateNotifier;
  RemoveListener? _removeStateListener;
  /* BccmPlayerConfiguration configuration; */
  final MediaItem? _intialMediaItem;
  NavigatorState? _currentFullscreenNavigator;
  StateNotifier<PlayerState>? get stateNotifier => _stateNotifier;

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

  @protected
  BccmPlayerController.fromStateNotifier(PlayerStateNotifier notifier)
      : _intialMediaItem = null,
        super(notifier.state) {
    _listenToNotifier(notifier);
  }

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

  BccmPlayerController(MediaItem mediaItem)
      : _intialMediaItem = mediaItem,
        super(const PlayerState(playerId: 'unknown', isInitialized: false));

  @override
  Future<void> dispose() async {
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

  Future<void> seekTo(Duration moment) async {
    if (_stateNotifier == null) {
      throw Exception("Player is not initialized");
    }
    BccmPlayerInterface.instance.seekTo(value.playerId, moment.inMilliseconds.toDouble());
  }

  Future<void> setPlaybackSpeed(double speed) async {
    BccmPlayerInterface.instance.setPlaybackSpeed(value.playerId, speed);
  }

  Future<void> pause() async {
    BccmPlayerInterface.instance.pause(value.playerId);
  }

  Future<void> play() async {
    BccmPlayerInterface.instance.play(value.playerId);
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

  Future enterFullscreen({
    bool? useNativeControls = false,
    BuildContext? context,
    void Function()? resetSystemOverlays,
    WidgetBuilder? playNextButton,
  }) async {
    if (useNativeControls == true) {
      BccmPlayerInterface.instance.enterFullscreen(value.playerId);
    } else if (context == null) {
      throw ErrorDescription('enterFullscreen: context cant be null if useNativeControls is false.');
    } else {
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
}
