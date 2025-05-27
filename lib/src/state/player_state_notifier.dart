import 'dart:async';

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:bccm_player/src/queue/queue_controller.dart';
import 'package:bccm_player/src/utils/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../queue/default_queue_controller.dart';

part 'player_state_notifier.freezed.dart';

class PlayerStateNotifier extends StateNotifier<PlayerState> {
  final void Function()? onDispose;
  final bool keepAlive;
  late Timer positionUpdateTimer;
  QueueManager queueManager = DefaultQueueManager();

  PlayerStateNotifier({
    PlayerState? player,
    this.onDispose,
    required this.keepAlive,
  }) : super(player ?? const PlayerState(playerId: 'unknown')) {
    queueManager.setPlayer(this);
    positionUpdateTimer = Timer.periodic(const Duration(seconds: 1), _updatePosition);
  }

  static PlayerStateNotifier? primary() {
    final id = BccmPlayerInterface.instance.stateNotifier.getPrimaryPlayerId();
    if (id == null) return null;
    return BccmPlayerInterface.instance.stateNotifier.getPlayerNotifier(id);
  }

  static PlayerStateNotifier? existing(String playerId) {
    return BccmPlayerInterface.instance.stateNotifier.getPlayerNotifier(playerId);
  }

  @override
  // ignore: must_call_super
  void dispose({bool? force}) {
    // prevents riverpods StateNotifierProvider from disposing it
    if (!keepAlive || force == true) {
      onDispose?.call();
      positionUpdateTimer.cancel();
      queueManager.dispose();
      super.dispose();
    }
  }

  void _updatePosition(Timer t) {
    if (!mounted) return t.cancel();
    if (state.playbackPositionMs != null && state.playbackState == PlaybackState.playing && !state.isBuffering) {
      // Increase by 1000 * playbackSpeed, because timer is called every 1000ms
      final newPosition = state.playbackPositionMs! + (1000 * state.playbackSpeed).round();
      state = state.copyWith(playbackPositionMs: newPosition);
    }
  }

  void resyncPlaybackPositionTimer() {
    positionUpdateTimer.cancel();
    positionUpdateTimer = Timer.periodic(const Duration(seconds: 1), _updatePosition);
  }

  PlayerState getState() {
    return state;
  }

  void setMediaItem(MediaItem? mediaItem) {
    state = state.copyWith(currentMediaItem: mediaItem);
  }

  void setError(PlayerError? error) {
    state = state.copyWith(error: error);
  }

  void setPlaybackState(PlaybackState playbackState) {
    state = state.copyWith(playbackState: playbackState);
  }

  void setPlaybackPosition(int? ms) {
    state = state.copyWith(playbackPositionMs: ms);
  }

  void setIsInPipMode(bool isInPipMode) {
    state = state.copyWith(isInPipMode: isInPipMode);
  }

  void setIsBuffering(bool isBuffering) {
    state = state.copyWith(isBuffering: isBuffering);
  }

  void setStateFromSnapshot(PlayerStateSnapshot snapshot) {
    state = state.copyWithSnapshot(snapshot);
  }
}

@freezed
abstract class PlayerState with _$PlayerState {
  const PlayerState._();
  const factory PlayerState({
    required String playerId,
    MediaItem? currentMediaItem,
    VideoSize? videoSize,
    int? playbackPositionMs,
    @Default(1.0) double playbackSpeed,
    @Default(false) bool isNativeFullscreen,
    @Default(PlaybackState.stopped) PlaybackState playbackState,
    @Default(false) bool isBuffering,
    @Default(false) bool isInPipMode,
    @Default(false) bool isInitialized,
    int? textureId,
    double? volume,
    PlayerError? error,
  }) = _PlayerState;

  factory PlayerState.fromPlayerStateSnapshot(PlayerStateSnapshot state) {
    return PlayerState(
      playerId: state.playerId,
      currentMediaItem: state.currentMediaItem,
      videoSize: state.videoSize,
      playbackPositionMs: state.playbackPositionMs?.finiteOrNull()?.round(),
      playbackSpeed: state.playbackSpeed,
      playbackState: state.playbackState,
      isBuffering: state.isBuffering,
      isNativeFullscreen: state.isFullscreen,
      isInitialized: true,
      textureId: state.textureId,
      volume: state.volume,
      error: state.error,
    );
  }
}

extension on PlayerState {
  PlayerState copyWithSnapshot(PlayerStateSnapshot snapshot) {
    return PlayerState.fromPlayerStateSnapshot(snapshot).copyWith(
      isInPipMode: isInPipMode, // not part of snapshot
      isInitialized: true,
    );
  }
}
