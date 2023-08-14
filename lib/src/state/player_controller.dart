import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:collection/collection.dart';

import '../../bccm_player.dart';
import '../pigeon/playback_platform_pigeon.g.dart';

/// The controller represents a player, and it's used to control and listen to player state.
///
/// You can use [BccmPlayerController.primary] to get the always-available primary player.
/// See [the docs](https://bcc-code.github.io/bccm-player/) for more info about the primary player.
///
/// As it is a [ValueNotifier], you can also use it to listen to changes in the player state: [BccmPlayerController.value].
/// Under the hood it's actually just a proxy to a [StateNotifier], which you can use directly via [BccmPlayerController.stateNotifier].
/// This is useful if you want to use riverpod/flutter_state_notifier.
///
/// See also:
/// * [primaryPlayerProvider] and [playerProviderFor] for riverpod providers of the stateNotifier.
/// * [BccmPlayerInterface.instance] which is being used under the hood. You can use this to call methods directly on the native side given a playerId.
/// * [BccmPlayerInterface.stateNotifier] which holds some global state, including the primaryPlayerId and all active players.
/// * [BccmPlayerController.primary] which is the primary player.
class BccmPlayerController extends ValueNotifier<PlayerState> {
  PlayerStateNotifier? _stateNotifier;
  RemoveListener? _removeStateListener;
  /* BccmPlayerConfiguration configuration; */
  final MediaItem? _intialMediaItem;
  StateNotifier<PlayerState>? get stateNotifier => _stateNotifier;
  final Set<State<VideoPlatformView>> _attachedPlayerViews = {};
  bool _isDisposed = false;

  static BccmPlayerController get primary => BccmPlayerInterface.instance.primaryController;

  State<VideoPlatformView>? get currentPlayerView {
    return _attachedPlayerViews.lastOrNull;
  }

  void attach(State<VideoPlatformView> playerView) {
    if (_isDisposed) return;
    _attachedPlayerViews.add(playerView);
    notifyListeners();
  }

  void detach(State<VideoPlatformView> playerView) {
    if (_isDisposed) return;
    _attachedPlayerViews.remove(playerView);
    notifyListeners();
  }

  /// Creates a [BccmPlayerController] with a [MediaItem].
  /// Use with e.g. [BccmPlayerView] or [VideoPlatformView].
  ///
  /// **Important:** You must call [initialize] to start loading the video.
  ///
  /// Example:
  ///
  /// ```dart
  /// final controller = BccmPlayerController(
  ///   MediaItem(
  ///     url: 'https://your-url-here/main.m3u8',
  ///     mimeType: 'application/x-mpegURL',
  ///     metadata: MediaMetadata(title: 'Apple advanced (HLS/HDR)'),
  ///   ),
  /// );
  /// controller.initialize();
  /// ```
  ///
  /// See also:
  ///
  /// * [BccmPlayerController.networkUrl] for a convenience constructor to create a [BccmPlayerController] with a network url.
  BccmPlayerController(MediaItem mediaItem)
      : _intialMediaItem = mediaItem,
        super(const PlayerState(
          playerId: 'unknown',
          isInitialized: false,
        ));

  /// Creates a [BccmPlayerController] with an empty [MediaItem].
  ///
  /// Intended for internal use only.
  @protected
  BccmPlayerController.empty()
      : _intialMediaItem = null,
        super(const PlayerState(playerId: 'unknown', isInitialized: false));

  /// Convenience constructor to create a [BccmPlayerController] with a network url.
  ///
  /// You must call [initialize] before using the controller.
  ///
  /// For more than the simplest use cases, we recommended to use the default constructor with a [MediaItem] instead.
  BccmPlayerController.networkUrl(
    Uri url, {
    String? mimeType,
  })  : _intialMediaItem = MediaItem(
          url: url.toString(),
          mimeType: mimeType,
        ),
        super(const PlayerState(playerId: 'unknown', isInitialized: false));

  /// Checks if this player is the current primary player.
  ///
  /// See also:
  /// * [primary] to get the current primary player.
  /// * [setPrimary] to set this player as the primary player.
  bool get isPrimary => BccmPlayerInterface.instance.stateNotifier.getPrimaryPlayerId() == value.playerId;

  /// Checks if this player represents a cast session.
  bool get isChromecast => value.playerId == 'chromecast';

  /// Disposes the player.
  /// The primary player can't be disposed.
  ///
  /// You can use [isPrimary] to check if the player is the primary player and conditionally dispose.
  /// Example:
  ///
  /// ```dart
  /// if (!controller.isPrimary) {
  ///  controller.dispose();
  /// }
  /// ```
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
    _isDisposed = true;
    _removeStateListener?.call();
    super.dispose();
    return BccmPlayerInterface.instance.disposePlayer(value.playerId);
  }

  /// Creates the player on the native side and starts loading the [MediaItem] which was implicitly or explicitly specificed in the constructor.
  ///
  /// You can use [isInitialized] to check if the player is initialized.
  Future<void> initialize() async {
    if (value.isInitialized || _isDisposed) {
      return;
    }
    final playerId = await BccmPlayerInterface.instance.newPlayer();
    if (_intialMediaItem != null) {
      await BccmPlayerInterface.instance.replaceCurrentMediaItem(playerId, _intialMediaItem!);
    }
    if (_isDisposed) {
      return;
    }
    final notifier = BccmPlayerInterface.instance.stateNotifier.getOrAddPlayerNotifier(playerId);
    _listenToNotifier(notifier);
  }

  /// Replaces the current [MediaItem] with a new one.
  /// If [autoplay] is true, the new [MediaItem] will start playing immediately.
  /// If [playbackPositionFromPrimary] is true, the playback position will be copied from the primary player.
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

  /// Seeks to a specific moment in the video. Example usage for skipping forward 20 seconds:
  ///
  /// ```dart
  /// final currentMs = controller.value.playbackPositionMs;
  /// if (currentMs != null) {
  ///   controller.seekTo(Duration(milliseconds: currentMs + 20000));
  /// }
  /// ```
  Future<void> seekTo(Duration moment) {
    if (_stateNotifier == null) {
      throw Exception("Player is not initialized");
    }
    return BccmPlayerInterface.instance.seekTo(value.playerId, moment.inMilliseconds.toDouble());
  }

  /// Sets the playback speed, where 1.0 is normal speed.
  /// The setting is kept across videos.
  ///
  /// ```dart
  /// controller.setPlaybackSpeed(2); // Will start playing at twice speed.
  /// ```
  Future<void> setPlaybackSpeed(double speed) {
    return BccmPlayerInterface.instance.setPlaybackSpeed(value.playerId, speed);
  }

  /// Pauses the video.
  ///
  /// See also:
  /// * [stop] which can stop and optionally clear all media items.
  /// * [play] which can play the video again.
  Future<void> pause() async {
    BccmPlayerInterface.instance.pause(value.playerId);
  }

  /// Plays the current media item.
  ///
  /// **Important**: Make sure to call [initialize] first.
  Future<void> play() async {
    BccmPlayerInterface.instance.play(value.playerId);
  }

  /// Stops the video.
  ///
  /// If [reset] is true, the current media item will be removed too.
  Future<void> stop({required bool reset}) async {
    return BccmPlayerInterface.instance.stop(value.playerId, reset);
  }

  /// Gets the current video, audio and text tracks.
  ///
  /// Returns null if the player is not initialized.
  ///
  /// See also:
  /// * [Track.isSelected] to find which tracks are selected.
  /// * [setSelectedTrack] to set the selected track.
  /// * [TrackListX] for a null-safe fix when working with tracks: `tracks.audioTracks.safe.map(...)`
  Future<PlayerTracksSnapshot?> getTracks() {
    return BccmPlayerInterface.instance.getPlayerTracks(playerId: value.playerId);
  }

  /// Sets the selected track. All other tracks of the same type will be unselected.
  ///
  /// * [type] is the type of track to set.
  ///
  /// * [trackId] is the id of the track to set. For video tracks, this can be 'auto' to automatically select the best track.
  ///
  /// If [trackId] is null, all tracks of [type] will be unselected.
  ///
  /// See also:
  /// * [getTracks] to get the current tracks.
  Future<void> setSelectedTrack(TrackType type, String? trackId) {
    return BccmPlayerInterface.instance.setSelectedTrack(value.playerId, type, trackId);
  }

  /// Sets the player as the primary player.
  /// The primary player is the player that is used for casting and picture in picture.
  ///
  /// See also:
  /// * [primary] to get the current primary player.
  /// * [isPrimary] to check if this is the current primary player.
  void setPrimary() {
    BccmPlayerInterface.instance.setPrimary(value.playerId);
  }

  /// Sets to mix audio with other apps/players.
  /// Untested on iOS, where it might be a bit buggy because we are setting this setting multiple places.
  Future<void> setMixWithOthers(bool bool) {
    return BccmPlayerInterface.instance.setMixWithOthers(value.playerId, bool);
  }

  /// You are probably looking for [BccmPlayerViewController.enterFullscreen].
  ///
  /// This opens the player in native fullscreen with native controls.
  Future enterNativeFullscreen() async {
    return BccmPlayerInterface.instance.enterFullscreen(value.playerId);
  }

  /// Exits native fullscreen. You might be looking for [BccmPlayerViewController.exitFullscreen].
  Future exitNativeFullscreen() async {
    BccmPlayerInterface.instance.exitFullscreen(value.playerId);
  }

  /// @internal as you probably don't need to use this.
  /// Used by the primaryController to swap between cast and local player.
  @internal
  void swapPlayerNotifier(PlayerStateNotifier notifier) {
    assert(!_isDisposed, "PlayerController was used after being disposed");
    _listenToNotifier(notifier);
  }

  void _listenToNotifier(PlayerStateNotifier notifier) {
    _removeStateListener?.call();
    _removeStateListener = notifier.addListener((state) {
      value = state;
    });
    _stateNotifier = notifier;
  }
}
