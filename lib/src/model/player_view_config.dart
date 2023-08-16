import 'package:flutter/material.dart';

import '../../bccm_player.dart';

/// Configuration usually passed to a [BccmPlayerView] or a [BccmPlayerViewController].
class BccmPlayerViewConfig {
  final BccmPlayerControlsConfig? _controlsConfig;
  final bool useSurfaceView;
  final FullscreenPageRouteBuilderFactory? fullscreenRouteBuilderFactory;
  final WidgetBuilder? castPlayerBuilder;
  final VoidCallback? resetSystemOverlays;
  BccmPlayerControlsConfig get controlsConfig => _controlsConfig ?? BccmPlayerControlsConfig();

  /// Configuration usually passed to a [BccmPlayerView] or a [BccmPlayerViewController].
  ///
  /// * [controlsConfig] configuration for the controls.
  /// * [useSurfaceView] is a flag to use a SurfaceView for the player on android. NOTE: has limitations, see docs.
  /// * [fullscreenRouteBuilderFactory] is a factory that creates a [PageRouteBuilder] that will be used to build the fullscreen route.
  /// * [resetSystemOverlays] is a callback that will be called when the player exits fullscreen. Defaults to using [SystemUiMode.edgeToEdge].
  /// * [castPlayerBuilder] is a builder that will be used to build the cast player.
  /// * [useSurfaceView] will use a SurfaceView instead of a TextureView on Android. Fixes HDR but flutter has a bug with SurfaceViews. See [the docs](https://bcc-code.github.io/bccm-player/advanced-usage/hdr-content/)
  const BccmPlayerViewConfig({
    BccmPlayerControlsConfig? controlsConfig,
    this.useSurfaceView = false,
    this.castPlayerBuilder,
    this.fullscreenRouteBuilderFactory,
    this.resetSystemOverlays,
  }) : _controlsConfig = controlsConfig;

  BccmPlayerViewConfig copyWith({
    BccmPlayerControlsConfig? controlsConfig,
    bool? useSurfaceView,
    FullscreenPageRouteBuilderFactory? fullscreenRouteBuilderFactory,
    WidgetBuilder? castPlayerBuilder,
    VoidCallback? resetSystemOverlays,
  }) {
    return BccmPlayerViewConfig(
      controlsConfig: controlsConfig ?? this.controlsConfig,
      useSurfaceView: useSurfaceView ?? this.useSurfaceView,
      fullscreenRouteBuilderFactory: fullscreenRouteBuilderFactory ?? this.fullscreenRouteBuilderFactory,
      castPlayerBuilder: castPlayerBuilder ?? this.castPlayerBuilder,
      resetSystemOverlays: resetSystemOverlays ?? this.resetSystemOverlays,
    );
  }
}

class BccmPlayerControlsConfig {
  /// * [customBuilder] is a builder that will be used to build the controls if you want to completely customize them.
  /// * [playNextButton] is a widget that will be shown in the bottom right corner of the player.
  /// * [playbackSpeeds] is a list of playback speeds that will be shown in the settings menu.
  /// * [hidePlaybackSpeed] will hide the playback speed selector in the settings menu.
  /// * [hideQualitySelector] will hide the quality selector in the settings menu.
  BccmPlayerControlsConfig({
    this.customBuilder,
    this.playNextButton,
    List<double>? playbackSpeeds,
    this.hidePlaybackSpeed,
    this.hideQualitySelector,
    this.additionalActionsBuilder,
  }) : playbackSpeeds = playbackSpeeds ?? [1.0, 1.25, 1.5, 1.75, 2.0];

  final ControlsBuilder? customBuilder;
  final WidgetBuilder? playNextButton;
  final List<double> playbackSpeeds;
  final bool? hidePlaybackSpeed;
  final bool? hideQualitySelector;
  final AdditionalControlsBuilder? additionalActionsBuilder;
}

typedef ControlsBuilder = Widget Function(BuildContext context);
typedef AdditionalControlsBuilder = List<Widget>? Function(BuildContext context);
