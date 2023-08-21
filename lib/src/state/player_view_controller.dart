import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../bccm_player.dart';
import 'inherited_player_view_controller.dart';

/// This is used to configure and control a specific player view.
///
/// It is supposed to be used 1:1 with a [BccmPlayerView].
///
/// Hover over the properties to see what they do.
/// * [resetSystemOverlays] is a callback that will be called when the player exits fullscreen. Defaults to using [SystemUiMode.edgeToEdge].
/// * [castPlayerBuilder] is a builder that will be used to build the cast player.
/// * [useSurfaceView] will use a SurfaceView instead of a TextureView on Android. Fixes HDR but flutter has a bug with SurfaceViews. See [the docs](https://bcc-code.github.io/bccm-player/advanced-usage/hdr-content/)
class BccmPlayerViewController extends ChangeNotifier {
  final BccmPlayerController playerController;
  BccmPlayerViewConfig _config;
  BccmPlayerViewConfig get config => _config;
  bool _isFullscreen = false;
  bool get isFullscreen => _isFullscreen;
  bool _isDisposed = false;
  NavigatorState? _currentFullscreenNavigator;
  BccmPlayerViewController? _fullscreenViewController;
  BccmPlayerViewController? get fullscreenViewController => _fullscreenViewController;

  BccmPlayerViewController({
    required this.playerController,
    BccmPlayerViewConfig? config,
  }) : _config = config ?? const BccmPlayerViewConfig();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Enters fullscreen.
  ///
  /// Example:
  ///
  /// ```dart
  /// final viewController = BccmPlayerViewController(
  ///   playerController: controller,
  ///   config: config,
  /// );
  /// viewController.enterFullscreen(context: context)
  ///   .then((_) => viewController.dispose());
  ///
  /// // Note: If you want to change config, you need to use `viewController.fullscreenViewController`.
  /// viewController.fullscreenViewController.setConfig();
  /// ```
  Future<void> enterFullscreen({BuildContext? context}) async {
    if (isFullscreen) {
      debugPrint("bccm: Already in fullscreen, ignoring enterFullscreen() call.");
      return;
    }
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(_getFullscreenOrientations());

    context ??= playerController.currentPlayerView?.context;

    assert(context != null,
        "No attached VideoPlatformView, and can't enter fullscreen without a BuildContext. To solve this, use an explicit context: enterFullscreen(context: context).");
    if (context == null) {
      return;
    }

    _currentFullscreenNavigator = Navigator.of(context, rootNavigator: true);
    _isFullscreen = true;
    notifyListeners();

    _fullscreenViewController = copyWith(playerController: playerController);
    _fullscreenViewController!._isFullscreen = true;
    _fullscreenViewController!._currentFullscreenNavigator = _currentFullscreenNavigator;
    _fullscreenViewController!._fullscreenViewController = _fullscreenViewController;
    await Navigator.of(context, rootNavigator: true).push(defaultFullscreenBuilder(_fullscreenViewController!));
    _fullscreenViewController?.dispose();
    _fullscreenViewController = null;
    _currentFullscreenNavigator = null;
    _isFullscreen = false;
    if (!_isDisposed) {
      notifyListeners();
    }

    if (_config.resetSystemOverlays != null) {
      _config.resetSystemOverlays!();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    SystemChrome.setPreferredOrientations(_getNormalOrientations());
    WakelockPlus.disable();
  }

  List<DeviceOrientation> _getFullscreenOrientations() {
    List<DeviceOrientation>? orientations;
    if (config.deviceOrientationsFullscreen != null) {
      orientations = config.deviceOrientationsFullscreen!(this);
    }
    if (orientations != null) {
      return orientations;
    }

    final aspectRatio = playerController.value.videoSize?.aspectRatio;
    if (aspectRatio != null) {
      if (aspectRatio > 1) {
        return [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight];
      } else if (aspectRatio < 1) {
        return [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown];
      }
    }
    // not initialized or square
    return DeviceOrientation.values;
  }

  List<DeviceOrientation> _getNormalOrientations() {
    List<DeviceOrientation>? orientations;
    if (config.deviceOrientationsNormal != null) {
      orientations = config.deviceOrientationsNormal!(this);
    }
    if (orientations != null) {
      return orientations;
    }

    return DeviceOrientation.values.toList();
  }

  Future<void> exitFullscreen() async {
    _isFullscreen = false;
    notifyListeners();
    _currentFullscreenNavigator?.maybePop();
    _currentFullscreenNavigator = null;
  }

  BccmPlayerViewController copyWith({
    BccmPlayerController? playerController,
    BccmPlayerControlsConfig? controlsConfig,
    bool? useSurfaceView,
    FullscreenPageRouteBuilderFactory? fullscreenRouteBuilderFactory,
    WidgetBuilder? castPlayerBuilder,
    VoidCallback? resetSystemOverlays,
  }) {
    return BccmPlayerViewController(
      playerController: playerController ?? this.playerController,
      config: _config,
    );
  }

  void setConfig(BccmPlayerViewConfig config) {
    _config = config;
    notifyListeners();
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
                  child: BccmPlayerView.withViewController(viewController),
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

  static BccmPlayerViewController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedBccmPlayerViewController>()!.controller;
  }
}

typedef FullscreenPageRouteBuilderFactory = PageRouteBuilder Function(BccmPlayerViewController viewController);
