import 'package:flutter/material.dart';

import '../../bccm_player.dart';

class BccmPlayerViewConfig {
  final PlayerControlsConfig? _controlsConfig;
  final bool useSurfaceView;
  final FullscreenPageRouteBuilderFactory? fullscreenRouteBuilderFactory;
  final WidgetBuilder? castPlayerBuilder;
  final VoidCallback? resetSystemOverlays;
  PlayerControlsConfig get controlsConfig => _controlsConfig ?? PlayerControlsConfig();

  const BccmPlayerViewConfig({
    PlayerControlsConfig? controlsConfig,
    this.useSurfaceView = false,
    this.castPlayerBuilder,
    this.fullscreenRouteBuilderFactory,
    this.resetSystemOverlays,
  }) : _controlsConfig = controlsConfig;

  BccmPlayerViewConfig copyWith({
    PlayerControlsConfig? controlsConfig,
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
