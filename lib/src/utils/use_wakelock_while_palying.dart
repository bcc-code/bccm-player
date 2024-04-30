import 'package:bccm_player/bccm_player.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Enables wakelock while playing and while this widget is mounted.
void useWakelockWhilePlaying(BccmPlayerController player) {
  useEffect(() {
    void listener() {
      if (player.value.playbackState != PlaybackState.paused) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    }

    player.addListener(listener);
    return () {
      player.removeListener(listener);
      WakelockPlus.disable();
    };
  }, [player]);
}
