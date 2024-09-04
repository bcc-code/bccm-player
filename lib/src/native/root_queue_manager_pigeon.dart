import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:bccm_player/src/queue/queue_controller.dart';

class RootQueueManagerPigeon implements QueueManagerPigeon {
  QueueManager? _getQueueManager(String playerId) {
    return BccmPlayerInterface.instance.stateNotifier.getPlayerNotifier(playerId)?.queueManager;
  }

  @override
  Future<void> skipToNext(String playerId) async {
    return _getQueueManager(playerId)?.skipToNext();
  }

  @override
  Future<void> skipToPrevious(String playerId) async {
    return _getQueueManager(playerId)?.skipToPrevious();
  }

  @override
  Future<void> handlePlaybackEnded(String playerId, MediaItem? current) async {
    return _getQueueManager(playerId)?.handlePlaybackEnded(current);
  }
}
