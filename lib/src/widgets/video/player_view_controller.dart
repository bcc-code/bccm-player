import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../bccm_player.dart';
import 'flutter_player_view.dart';

/// This is used to configure and control a specific player view.
///
/// It is supposed to be used 1:1 with a [BccmPlayerView].
///
/// Hover over the properties to see what they do.
/// * [resetSystemOverlays] is a callback that will be called when the player exits fullscreen. Defaults to using [SystemUiMode.edgeToEdge].
/// * [castPlayerBuilder] is a builder that will be used to build the cast player.
/// * [useSurfaceView] will use a SurfaceView instead of a TextureView on Android. Fixes HDR but flutter has a bug with SurfaceViews. See [the docs](https://bcc-code.github.io/bccm-player/advanced-usage/hdr-content/)
class BccmPlayerViewController extends ChangeNotifier implements AbstractBccmPlayerViewController {
  @override
  final BccmPlayerController playerController;
  final PlayerControlsOptions controlsOptions;
  final bool useSurfaceView;
  final FullscreenPageRouteBuilderFactory? fullscreenRouteBuilderFactory;
  final WidgetBuilder? castPlayerBuilder;
  final VoidCallback? resetSystemOverlays;
  bool _isFullscreen = false;
  bool get isFullscreen => _isFullscreen;
  NavigatorState? _currentFullscreenNavigator;
  BccmPlayerViewController? _fullscreenViewController;

  BccmPlayerViewController({
    required this.playerController,
    PlayerControlsOptions? controlsOptions,
    this.useSurfaceView = false,
    this.castPlayerBuilder,
    this.fullscreenRouteBuilderFactory,
    this.resetSystemOverlays,
  }) : controlsOptions = controlsOptions ?? PlayerControlsOptions();

  @override
  Future<void> enterFullscreen({BuildContext? context}) async {
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    debugPrint('bccm: setPreferredOrientations landscape');

    context ??= playerController.currentPlayerView?.context;

    assert(context != null,
        "No attached VideoPlayerView, and can't enter fullscreen without a BuildContext. To solve this, either create a VideoPlayerView using this controller or use an explicit context: enterFullscreen(context: context).");
    if (context == null) {
      return;
    }

    //_stateNotifier?.setIsFlutterFullscreen(true);
    _currentFullscreenNavigator = Navigator.of(context, rootNavigator: true);
    _isFullscreen = true;
    notifyListeners();

    _fullscreenViewController = copyWith(playerController: playerController);
    _fullscreenViewController!._isFullscreen = true;
    _fullscreenViewController!._currentFullscreenNavigator = _currentFullscreenNavigator;
    await Navigator.of(context, rootNavigator: true).push(defaultFullscreenBuilder(_fullscreenViewController!));
    _fullscreenViewController?.dispose();
    _fullscreenViewController = null;
    _currentFullscreenNavigator = null;

    if (resetSystemOverlays != null) {
      resetSystemOverlays!();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    debugPrint('bccm: setPreferredOrientations portraitUp');

    //_stateNotifier?.setIsFlutterFullscreen(false);
    WakelockPlus.disable();
  }

  @override
  Future<void> exitFullscreen() async {
    _isFullscreen = false;
    notifyListeners();
    _currentFullscreenNavigator?.maybePop();
    _currentFullscreenNavigator = null;
  }

  BccmPlayerViewController copyWith({
    BccmPlayerController? playerController,
    PlayerControlsOptions? controlsOptions,
    bool? useSurfaceView,
    FullscreenPageRouteBuilderFactory? fullscreenRouteBuilderFactory,
    WidgetBuilder? castPlayerBuilder,
    VoidCallback? resetSystemOverlays,
  }) {
    return BccmPlayerViewController(
      playerController: playerController ?? this.playerController,
      controlsOptions: controlsOptions ?? this.controlsOptions,
      useSurfaceView: useSurfaceView ?? this.useSurfaceView,
      fullscreenRouteBuilderFactory: fullscreenRouteBuilderFactory ?? this.fullscreenRouteBuilderFactory,
      castPlayerBuilder: castPlayerBuilder ?? this.castPlayerBuilder,
      resetSystemOverlays: resetSystemOverlays ?? this.resetSystemOverlays,
    );
  }

  FullscreenPageRouteBuilderFactory get defaultFullscreenBuilder => (BccmPlayerViewController viewController) => PageRouteBuilder(
        pageBuilder: (context, aAnim, bAnim) => Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                color: Colors.black,
              ),
              SizedBox.expand(
                child: Align(
                  alignment: Alignment.center,
                  child: FlutterBccmPlayerView(viewController),
                ),
              ),
            ],
          ),
        ),
        transitionsBuilder: (context, aAnim, bAnim, child) => FadeTransition(
          opacity: aAnim,
          child: child,
        ),
        fullscreenDialog: true,
      );
}

/// A BccmPlayerViewController that uses native controls.
class BccmPlayerNativeViewController extends AbstractBccmPlayerViewController {
  BccmPlayerNativeViewController(super.playerController);

  @override
  void enterFullscreen() {
    BccmPlayerInterface.instance.enterFullscreen(playerController.value.playerId);
  }

  @override
  void exitFullscreen() {
    BccmPlayerInterface.instance.exitFullscreen(playerController.value.playerId);
  }
}

/// Abstract interface to be implemented by a specific type of VideoPlayerView.
///
/// Use [BccmPlayerViewController] for a normal player view based on flutter controls.
///
/// Use [BccmPlayerNativeViewController] for a view with native controls.
abstract class AbstractBccmPlayerViewController {
  final BccmPlayerController playerController;

  AbstractBccmPlayerViewController(this.playerController);

  void enterFullscreen();
  void exitFullscreen();
  void dispose() {}
}

typedef FullscreenPageRouteBuilderFactory = PageRouteBuilder Function(BccmPlayerViewController viewController);
