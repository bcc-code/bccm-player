import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bccm_player.dart';

/// Configuration usually passed to a [BccmPlayerView] or a [BccmPlayerViewController].
class BccmPlayerViewConfig {
  final BccmPlayerControlsConfig? _controlsConfig;
  final bool useSurfaceView;
  final bool allowSystemGestures;
  final FullscreenPageRouteBuilderFactory? fullscreenRouteBuilderFactory;
  final WidgetBuilder? castPlayerBuilder;
  final VoidCallback? resetSystemOverlays;
  final double? aspectRatioOverride;
  final bool? pipOnLeave;
  final BoxFit? videoFit;
  final bool? allowsVideoFrameAnalysis;

  /// A callback to control device orientations upon exiting fullscreen.
  ///
  /// **Return null to use defaults.**
  /// Default is DeviceOrientation.values.
  ///
  /// Example for a portraitUp-only app where fullscreen will always be landscapeLeft:
  ///
  /// ```dart
  /// BccmPlayerViewConfig(
  ///  deviceOrientationsNormal: (_) => [DeviceOrientations.portraitUp],
  ///  deviceOrientationsFullscreen: (_) => [DeviceOrientations.landscapeLeft],
  /// )
  /// ```
  final DeviceOrientationsCallback? deviceOrientationsNormal;

  /// A callback to control device orientations in fullscreen.
  ///
  /// **Return null to use defaults.**
  /// Default is [.landscapeLeft, .landscapeRight] for landscape videos, [.portraitUp, .portraitDown] for portrait videos and "all" orientations for square/uninitialized videos.
  ///
  /// Example where fullscreen will force landscapeLeft for uninitialized and square videos:
  ///
  /// ```dart
  /// BccmPlayerViewConfig(
  ///   deviceOrientationsNormal: (_) => [DeviceOrientations.portraitUp],
  ///   deviceOrientationsFullscreen: (viewController) {
  ///     final videoSize = viewController.playerController.value.videoSize;
  ///     if (videoSize == null || videoSize.aspectRatio == 1) {
  ///         // square or uninitialized
  ///         return [DeviceOrientation.landscapeLeft];
  ///     }
  ///     // return null to get default behavior
  ///     return null;
  ///   },
  /// )
  /// ```
  final DeviceOrientationsCallback? deviceOrientationsFullscreen;

  BccmPlayerControlsConfig get controlsConfig => _controlsConfig ?? BccmPlayerControlsConfig();

  /// Configuration usually passed to a [BccmPlayerView] or a [BccmPlayerViewController].
  ///
  /// * [controlsConfig] configuration for the controls.
  /// * [useSurfaceView] (android-only) will use a SurfaceView instead of a TextureView on Android. Fixes HDR but flutter has a bug with SurfaceViews. See [the docs](https://bcc-code.github.io/bccm-player/advanced-usage/hdr-content/)
  /// * [allowSystemGestures] (android-only) will allow system gestures (e.g. swipe to go back) on top of the native video. Default is `false` to prevent conflicts with the seekbar and such.
  /// * [isOffline] use this handle offline playback. E.g. to hide tracks that havent been downloaded.
  /// * [fullscreenRouteBuilderFactory] is a factory that creates a [PageRouteBuilder] that will be used to build the fullscreen route.
  /// * [resetSystemOverlays] is a callback that will be called when the player exits fullscreen. Defaults to using [SystemUiMode.edgeToEdge].
  /// * [deviceOrientationsNormal] is a callback used upon exiting fullscreen to get the orientations to set. Return null for defaults.
  /// * [deviceOrientationsFullscreen] is a callback used upon **entering** fullscreen to get the orientations to set. Return null for defaults.
  /// * [castPlayerBuilder] is a builder that will be used to build the cast player.
  const BccmPlayerViewConfig({
    BccmPlayerControlsConfig? controlsConfig,
    this.useSurfaceView = false,
    this.allowSystemGestures = false,
    this.castPlayerBuilder,
    this.fullscreenRouteBuilderFactory,
    this.resetSystemOverlays,
    this.deviceOrientationsNormal,
    this.deviceOrientationsFullscreen,
    this.aspectRatioOverride,
    this.pipOnLeave,
    this.videoFit,
    this.allowsVideoFrameAnalysis,
  }) : _controlsConfig = controlsConfig;

  BccmPlayerViewConfig copyWith({
    BccmPlayerControlsConfig? controlsConfig,
    bool? useSurfaceView,
    FullscreenPageRouteBuilderFactory? fullscreenRouteBuilderFactory,
    WidgetBuilder? castPlayerBuilder,
    VoidCallback? resetSystemOverlays,
    bool? allowSystemGestures,
    DeviceOrientationsCallback? deviceOrientationsNormal,
    DeviceOrientationsCallback? deviceOrientationsFullscreen,
    double? aspectRatioOverride,
    bool? pipOnLeave,
    BoxFit? videoFit,
    bool? allowsVideoFrameAnalysis,
  }) {
    return BccmPlayerViewConfig(
      controlsConfig: controlsConfig ?? this.controlsConfig,
      useSurfaceView: useSurfaceView ?? this.useSurfaceView,
      fullscreenRouteBuilderFactory: fullscreenRouteBuilderFactory ?? this.fullscreenRouteBuilderFactory,
      castPlayerBuilder: castPlayerBuilder ?? this.castPlayerBuilder,
      resetSystemOverlays: resetSystemOverlays ?? this.resetSystemOverlays,
      allowSystemGestures: allowSystemGestures ?? this.allowSystemGestures,
      deviceOrientationsNormal: deviceOrientationsNormal ?? this.deviceOrientationsNormal,
      deviceOrientationsFullscreen: deviceOrientationsFullscreen ?? this.deviceOrientationsFullscreen,
      aspectRatioOverride: aspectRatioOverride ?? this.aspectRatioOverride,
      pipOnLeave: pipOnLeave ?? this.pipOnLeave,
      videoFit: videoFit ?? this.videoFit,
      allowsVideoFrameAnalysis: allowsVideoFrameAnalysis ?? this.allowsVideoFrameAnalysis,
    );
  }
}

class BccmPlayerControlsConfig {
  /// * [customBuilder] is a builder that will be used to build the controls if you want to completely customize them.
  /// * [rightSideSlot] is a widget that will be shown in the bottom right corner of the player.
  /// * [playbackSpeeds] is a list of playback speeds that will be shown in the settings menu.
  /// * [hidePlaybackSpeed] will hide the playback speed selector in the settings menu.
  /// * [hideQualitySelector] will hide the quality selector in the settings menu.
  BccmPlayerControlsConfig({
    this.customBuilder,
    this.rightSideSlot,
    List<double>? playbackSpeeds,
    this.hidePlaybackSpeed,
    this.hideQualitySelector,
    this.additionalActionsBuilder,
    this.extraSettingsBuilder,
    this.topRightNextToSettingsSlot,
  }) : playbackSpeeds = playbackSpeeds ?? [1.0, 1.25, 1.5, 1.75, 2.0];

  final ControlsBuilder? customBuilder;
  final WidgetBuilder? rightSideSlot;
  final List<double> playbackSpeeds;
  final bool? hidePlaybackSpeed;
  final bool? hideQualitySelector;
  final AdditionalControlsBuilder? additionalActionsBuilder;
  final ExtraSettingsBuilder? extraSettingsBuilder;
  final WidgetBuilder? topRightNextToSettingsSlot;

  BccmPlayerControlsConfig copyWith({
    ControlsBuilder? customBuilder,
    WidgetBuilder? rightSideSlot,
    List<double>? playbackSpeeds,
    bool? hidePlaybackSpeed,
    bool? hideQualitySelector,
    AdditionalControlsBuilder? additionalActionsBuilder,
    ExtraSettingsBuilder? extraSettingsBuilder,
    WidgetBuilder? topRightNextToSettingsSlot,
  }) {
    return BccmPlayerControlsConfig(
      customBuilder: customBuilder ?? this.customBuilder,
      rightSideSlot: rightSideSlot ?? this.rightSideSlot,
      playbackSpeeds: playbackSpeeds ?? this.playbackSpeeds,
      hidePlaybackSpeed: hidePlaybackSpeed ?? this.hidePlaybackSpeed,
      hideQualitySelector: hideQualitySelector ?? this.hideQualitySelector,
      additionalActionsBuilder: additionalActionsBuilder ?? this.additionalActionsBuilder,
      extraSettingsBuilder: extraSettingsBuilder ?? this.extraSettingsBuilder,
      topRightNextToSettingsSlot: topRightNextToSettingsSlot ?? this.topRightNextToSettingsSlot,
    );
  }
}

typedef ControlsBuilder = Widget Function(BuildContext context);
typedef ExtraSettingsBuilder = List<Widget>? Function(BuildContext context);
typedef AdditionalControlsBuilder = List<Widget>? Function(BuildContext context);
typedef DeviceOrientationsCallback = List<DeviceOrientation>? Function(BccmPlayerViewController viewController);
