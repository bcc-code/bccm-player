import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';

extension TrackX on Track {
  String get labelWithFallback {
    if (height != null) {
      var conditionalFrameRate = '';
      if (frameRate != null && frameRate != 30) {
        conditionalFrameRate = ' (${frameRate!.toInt().toString()}fps)';
      }

      return "${height}p$conditionalFrameRate";
    }
    return (label ?? language ?? id); //  + (downloaded == true ? " (downloaded)" : "")
  }
}

extension TrackListX on List<Track?> {
  Iterable<Track> get safe => whereType<Track>();
}

extension VideoSizeX on VideoSize {
  double get aspectRatio => width / height;
}

const autoTrackId = "auto";
