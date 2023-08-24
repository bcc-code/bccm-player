// ignore_for_file: invalid_use_of_protected_member

import 'package:bccm_player/bccm_player.dart';

import '../cast/cast_player.dart';
import 'package:flutter/widgets.dart';

import '../controls/default_controls.dart';
import 'controlled_player_view.dart';
import 'native_player_view.dart';

/// A widget that displays a video player with controls given a [AbstractBccmPlayerViewController].
///
/// It has two implementations:
///
/// * [ManagedBccmPlayerView]\: the default implementation, which uses flutter-based controls and fullscreening, can be created via [BccmPlayerView].
/// * [NativeBccmPlayerView]\: a native implementation, which uses native controls and native fullscreening, can be created via [BccmPlayerView.native]
abstract class BccmPlayerView extends Widget {
  /// Displays the video represented by [playerController] with normal flutter-based controls and fullscreening.
  ///
  /// For a barebones setup, pass [BccmPlayerController.primary] as the controller and use [BccmPlayerController.replaceCurrentMediaItem] to set the media item.
  ///
  /// Example:
  ///
  /// ```dart  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///  return BccmPlayerView(playerController: BccmPlayerController.primary);
  /// }
  /// ```
  ///
  /// See also:
  ///
  /// * [BccmPlayerView.withViewController]\: allows you to pass a [BccmPlayerViewController] explicitly.
  /// * [BccmPlayerViewController]\: provides customization and state handling for the player **views**.
  /// * [BccmPlayerController]\: this represents the actual player. It allows you to read player state and control the player (play, pause, etc).
  /// * [VideoPlatformView]\: a pure video platform view (optionally with controls), used under-the-hood by this widget.
  /// * [DefaultControls]\: the default controls used for the player.
  /// * [DefaultCastPlayer]\: the default cast player ui.
  const factory BccmPlayerView(
    BccmPlayerController playerController, {
    BccmPlayerViewConfig? config,
    Key? key,
  }) = ManagedBccmPlayerView;

  /// Displays a video player with normal flutter-based controls according to the [viewController].
  ///
  /// A [BccmPlayerViewController] provides customization and state handling for the player views. It's always used internally,
  /// but this allows you to specify it explicitly so that you can call [BccmPlayerViewController.enterFullscreen] or listen to the state.
  ///
  /// For advanced use cases, you could potentially override BccmPlayerViewController to add some extra configurations and use it in your controls.
  ///
  /// See also:
  ///
  /// * [BccmPlayerView]\: the normal constructor manages a BccmPlayerViewController for you so you don't have to.
  const factory BccmPlayerView.withViewController(
    BccmPlayerViewController viewController, {
    Key? key,
  }) = ControlledBccmPlayerView;

  const factory BccmPlayerView.native(
    BccmPlayerController playerController, {
    Key? key,
  }) = NativeBccmPlayerView;
}

/// Creates and manages the lifetime of a [BccmPlayerViewController] to use with a [ControlledBccmPlayerView].
///
/// Read comments on [BccmPlayerView] for more details.
class ManagedBccmPlayerView extends StatefulWidget implements BccmPlayerView {
  final BccmPlayerController playerController;
  final BccmPlayerViewConfig config;

  const ManagedBccmPlayerView(
    this.playerController, {
    super.key,
    BccmPlayerViewConfig? config,
  }) : config = config ?? const BccmPlayerViewConfig();

  @override
  State<ManagedBccmPlayerView> createState() => _ManagedBccmPlayerViewState();
}

class _ManagedBccmPlayerViewState extends State<ManagedBccmPlayerView> {
  late BccmPlayerViewController viewController;

  @override
  void initState() {
    super.initState();
    viewController = BccmPlayerViewController(playerController: widget.playerController, config: widget.config);
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.playerController == widget.playerController && oldWidget.config != widget.config) {
      viewController.setConfig(widget.config);
    } else if (oldWidget.playerController != widget.playerController) {
      viewController.dispose();
      viewController = BccmPlayerViewController(playerController: widget.playerController, config: widget.config);
    }
  }

  @override
  void dispose() {
    viewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControlledBccmPlayerView(viewController);
  }
}
