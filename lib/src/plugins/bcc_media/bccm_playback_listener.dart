import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:bccm_player/plugins/riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../../utils/debouncer.dart';
import '../../utils/extensions.dart';

class BccmPlaybackListener {
  Ref ref;
  final progressDebouncer = Debouncer(milliseconds: 1000);
  final void Function(String episodeId, int progressSeconds, int? durationSeconds) updateProgress;
  final void Function(MediaItemTransitionEvent event)? onMediaItemTransition;
  final void Function(PlaybackEndedEvent event)? onPlaybackEnded;

  BccmPlaybackListener({required this.ref, required this.updateProgress, this.onMediaItemTransition, this.onPlaybackEnded}) {
    final stream = BccmPlayerInterface.instance.playerEventStream;
    final listener = stream.listen((event) {
      switch (event.runtimeType) {
        case PositionDiscontinuityEvent:
          onPositionDiscontinuity(event as PositionDiscontinuityEvent);
          break;
        case PlayerStateUpdateEvent:
          onPlayerStateUpdate(event as PlayerStateUpdateEvent);
          break;
        case MediaItemTransitionEvent:
          if (onMediaItemTransition != null) {
            onMediaItemTransition!(event);
          }
          break;
        case PlaybackEndedEvent:
          if (onPlaybackEnded != null) {
            onPlaybackEnded!(event);
          }
          break;
      }
    });
    ref.onDispose(() {
      listener.cancel();
    });
  }

  void onPositionDiscontinuity(PositionDiscontinuityEvent event) {
    var player = ref.read(playerProviderFor(event.playerId));
    _updateProgress(
      episodeId: player?.currentMediaItem?.metadata?.extras?['id']?.asOrNull<String>(),
      positionMs: event.playbackPositionMs?.finiteOrNull()?.round(),
      durationMs: player?.currentMediaItem?.metadata?.durationMs?.round(),
    );
  }

  void onPlayerStateUpdate(PlayerStateUpdateEvent event) {
    if (event.snapshot.playbackState != PlaybackState.playing) return;
    var player = ref.read(playerProviderFor(event.playerId));
    _updateProgress(
      episodeId: event.snapshot.currentMediaItem?.metadata?.extras?['id']?.asOrNull<String>(),
      positionMs: event.snapshot.playbackPositionMs?.finiteOrNull()?.round(),
      durationMs: player?.currentMediaItem?.metadata?.durationMs?.round(),
    );
  }

  void _updateProgress({required String? episodeId, required int? positionMs, int? durationMs}) {
    if (episodeId == null || positionMs == null) return;
    final progressSeconds = positionMs / 1000;
    final durationSeconds = durationMs != null ? durationMs / 1000 : null;
    progressDebouncer.run(() => updateProgress(episodeId, progressSeconds.round(), durationSeconds?.round()));
  }
}
