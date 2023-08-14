// ignore_for_file: invalid_use_of_protected_member

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/widgets/video/simple_player_view.dart';

import '../cast/cast_player.dart';
import 'package:flutter/widgets.dart';

import '../controls/default_controls.dart';
import 'flutter_player_view.dart';
import 'native_player_view.dart';

typedef ControlsBuilder = Widget Function(
  BuildContext context,
  BccmPlayerViewController viewController,
);

/// A widget that displays a video player with controls given a [AbstractBccmPlayerViewController].
///
/// It has two implementations:
///
/// * [FlutterBccmPlayerView]\: the default implementation, which uses flutter-based controls and fullscreening, can be created via [BccmPlayerView].
/// * [NativeBccmPlayerView]\: a native implementation, which uses native controls and native fullscreening, can be created via [BccmPlayerView.native]
abstract class BccmPlayerView extends Widget {
  /// Displays a video player with flutter-based controls according to the configuration in the [viewController].
  ///
  /// Use [BccmPlayerView.simple] if you only need default settings, as it allows you to pass a [BccmPlayerController] without managing a [BccmPlayerViewController].
  ///
  /// See also:
  ///
  /// * [BccmPlayerViewController]\: provides customization and state handling for the player **views**.
  /// * [BccmPlayerController]\: this represents the actual player. It allows you to read player state and control the player (play, pause, etc).
  /// * [VideoPlatformView]\: a widget used under-the-hood to render the native video.
  /// * [DefaultControls]\: which is the default controls used for the player.
  /// * [CastPlayer]\: which is the widget that renders the cast player.
  const factory BccmPlayerView(BccmPlayerViewController viewController, {Key? key}) = FlutterBccmPlayerView;

  /// Displays a video player with native controls and native fullscreening.
  ///
  /// This is not a recommended approach as it does not support all features and is not customizable.
  const factory BccmPlayerView.native(BccmPlayerNativeViewController viewController, {Key? key}) = NativeBccmPlayerView;

  /// A simple method to display a default-everything video player given a [BccmPlayerController].
  /// It basically just creates a default [BccmPlayerViewController] and auto-disposes it for you.
  ///
  /// For a barebones setup, pass [BccmPlayerController.primary] as the controller and use [BccmPlayerController.replaceCurrentMediaItem] to set the media item.
  ///
  /// Example:
  ///
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   BccmPlayerController.primary.replaceCurrentMediaItem(MediaItem(...));
  /// }
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///  return BccmPlayerView.simple(BccmPlayerController.primary);
  /// }
  /// ```
  static simple(BccmPlayerController controller) => SimpleBccmPlayerView(controller);
}
