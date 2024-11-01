import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:bccm_player/plugins/riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../../utils/debouncer.dart';
import '../../utils/extensions.dart';

class BccmPlaybackListener {
  Ref ref;
  final progressDebouncer = Debouncer(milliseconds: 1000);
  final void Function(String episodeId, int progressSeconds) updateProgress;
  final void Function(AnalyticsEvent event)? onAnalyticsEvent;

  BccmPlaybackListener({required this.ref, required this.updateProgress, this.onAnalyticsEvent}) {
    final stream = BccmPlayerInterface.instance.playerEventStream;
    final listener = stream.listen((event) {
      switch (event.runtimeType) {
        case PositionDiscontinuityEvent:
          onPositionDiscontinuity(event as PositionDiscontinuityEvent);
          break;
        case PlayerStateUpdateEvent:
          onPlayerStateUpdate(event as PlayerStateUpdateEvent);
          break;
        case AnalyticsEvent:
          if (onAnalyticsEvent != null) {
            onAnalyticsEvent!(event as AnalyticsEvent);
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
    );
  }

  void onPlayerStateUpdate(PlayerStateUpdateEvent event) {
    if (event.snapshot.playbackState != PlaybackState.playing) return;
    _updateProgress(
      episodeId: event.snapshot.currentMediaItem?.metadata?.extras?['id']?.asOrNull<String>(),
      positionMs: event.snapshot.playbackPositionMs?.finiteOrNull()?.round(),
    );
  }

  void _updateProgress({required String? episodeId, required int? positionMs}) {
    if (episodeId == null || positionMs == null) return;
    final progressSeconds = positionMs / 1000;
    progressDebouncer.run(() => updateProgress(episodeId, progressSeconds.round()));
  }
}
