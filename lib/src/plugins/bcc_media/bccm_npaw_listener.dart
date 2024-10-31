import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:riverpod/riverpod.dart';

class BccmNpawListener {
  Ref ref;
  Function(NpawVideoStartEvent event)? onVideoStart;
  Function(NpawVideoStopEvent event)? onVideoStop;
  Function(NpawVideoPauseEvent event)? onVideoPause;
  Function(NpawVideoResumeEvent event)? onVideoResume;
  Function(NpawVideoPingEvent event)? onVideoPing;
  Function(NpawVideoSeekEvent event)? onVideoSeek;

  BccmNpawListener({
    required this.ref,
    this.onVideoStart,
    this.onVideoStop,
    this.onVideoPause,
    this.onVideoResume,
    this.onVideoPing,
    this.onVideoSeek,
  }) {
    final stream = BccmPlayerInterface.instance.npawEventStream;
    final listener = stream.listen((event) {
      switch (event.runtimeType) {
        case NpawVideoStartEvent:
          if (onVideoStart != null) {
            onVideoStart!(event as NpawVideoStartEvent);
          }
          break;
        case NpawVideoStopEvent:
          if (onVideoStop != null) {
            onVideoStop!(event as NpawVideoStopEvent);
          }
          break;
        case NpawVideoPauseEvent:
          if (onVideoPause != null) {
            onVideoPause!(event as NpawVideoPauseEvent);
          }
          break;
        case NpawVideoResumeEvent:
          if (onVideoResume != null) {
            onVideoResume!(event as NpawVideoResumeEvent);
          }
          break;
        case NpawVideoPingEvent:
          if (onVideoPing != null) {
            onVideoPing!(event as NpawVideoPingEvent);
          }
          break;
        case NpawVideoSeekEvent:
          if (onVideoSeek != null) {
            onVideoSeek!(event as NpawVideoSeekEvent);
          }
          break;
      }
    });
    ref.onDispose(() {
      listener.cancel();
    });
  }
}
