import 'package:flutter/material.dart';

import '../../../bccm_player.dart';

/// * [playNextButton] is a widget that will be shown in the bottom right corner of the player.
/// * [playbackSpeeds] is a list of playback speeds that will be shown in the settings menu.
/// * [hidePlaybackSpeed] will hide the playback speed selector in the settings menu.
/// * [hideQualitySelector] will hide the quality selector in the settings menu.
class PlayerControlsConfig {
  PlayerControlsConfig({
    this.customBuilder,
    this.playNextButton,
    List<double>? playbackSpeeds,
    this.hidePlaybackSpeed,
    this.hideQualitySelector,
  }) : playbackSpeeds = playbackSpeeds ?? [1.0, 1.25, 1.5, 1.75, 2.0];

  final ControlsBuilder? customBuilder;
  final WidgetBuilder? playNextButton;
  final List<double> playbackSpeeds;
  final bool? hidePlaybackSpeed;
  final bool? hideQualitySelector;
}
