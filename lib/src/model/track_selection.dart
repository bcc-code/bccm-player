import 'package:collection/collection.dart';

import '../pigeon/pigeon_extensions.dart';
import '../pigeon/playback_platform_pigeon.g.dart';

/// What the settings sheet should offer for a given set of player tracks.
///
/// Derived entirely from a [PlayerTracksSnapshot] plus a few flags — no
/// `BuildContext`, no player, no I/O — so it can be tested directly. It was
/// previously inlined in the settings widget's `build`, where none of it could
/// be reached by a test.
///
/// Presentation stays in the widget: this decides *which* rows to show and
/// *which* tracks each row lists, not what they are labelled.
class TrackSelection {
  const TrackSelection({
    required this.audioTracks,
    required this.textTracks,
    required this.videoTracks,
    required this.selectedAudioTrack,
    required this.selectedTextTrack,
    required this.selectedVideoTrack,
    required this.showAudioSelector,
    required this.showSubtitleSelector,
    required this.showPlaybackSpeed,
    required this.showQualitySelector,
  });

  /// Audio tracks to offer, already filtered for offline playback.
  final List<Track> audioTracks;

  /// Text tracks to offer, already filtered for offline playback.
  final List<Track> textTracks;

  /// Video tracks to offer, reduced to one per distinct height.
  final List<Track> videoTracks;

  /// The currently selected track of each type, looked up on the *unfiltered*
  /// lists — the player can have a track selected that offline filtering would
  /// otherwise hide.
  final Track? selectedAudioTrack;
  final Track? selectedTextTrack;

  /// `null` means the player is choosing the video track automatically.
  final Track? selectedVideoTrack;

  final bool showAudioSelector;
  final bool showSubtitleSelector;
  final bool showPlaybackSpeed;
  final bool showQualitySelector;

  /// Whether there is anything at all to show, ignoring caller-supplied extras.
  bool get isEmpty => !showAudioSelector && !showSubtitleSelector && !showPlaybackSpeed && !showQualitySelector;

  /// Resolves [tracks] into the rows the settings sheet should render.
  ///
  /// * [isOffline] hides tracks that were not downloaded.
  /// * [isLive] hides the playback-speed row unless [hidePlaybackSpeed] says
  ///   otherwise explicitly.
  /// * [hidePlaybackSpeed] / [hideQualitySelector] are the caller's overrides;
  ///   `null` means "use the default behaviour".
  factory TrackSelection.from(
    PlayerTracksSnapshot? tracks, {
    bool isOffline = false,
    bool isLive = false,
    bool? hidePlaybackSpeed,
    bool? hideQualitySelector,
  }) {
    bool available(Track track) => !isOffline || track.downloaded == null || track.downloaded == true;

    final allAudio = tracks?.audioTracks.safe.toList() ?? const <Track>[];
    final allText = tracks?.textTracks.safe.toList() ?? const <Track>[];
    final allVideo = tracks?.videoTracks.safe.toList() ?? const <Track>[];

    final selectedAudio = allAudio.firstWhereOrNull((t) => t.isSelected);
    final selectedText = allText.firstWhereOrNull((t) => t.isSelected);
    final selectedVideo = allVideo.firstWhereOrNull((t) => t.isSelected);

    final audio = allAudio.where(available).toList();
    // A selected track that offline filtering removed is added back, otherwise
    // the row would show a selection the user cannot see or return to.
    if (selectedAudio != null && !audio.contains(selectedAudio)) {
      audio.add(selectedAudio);
    }

    final text = allText.where(available).toList();

    // One entry per distinct height, keeping the first. Tracks with no height
    // all collapse into a single entry.
    final seenHeights = <int>{};
    final video = allVideo.where((t) => seenHeights.add(t.height ?? 0)).toList();

    return TrackSelection(
      audioTracks: audio,
      textTracks: text,
      videoTracks: video,
      selectedAudioTrack: selectedAudio,
      selectedTextTrack: selectedText,
      selectedVideoTrack: selectedVideo,
      // Only worth offering a choice when there is more than one thing to pick.
      showAudioSelector: audio.length > 1,
      // Subtitles differ: a single track is still a choice, because "None" is
      // always an option alongside it.
      showSubtitleSelector: text.isNotEmpty,
      // Explicit `false` forces the row on even for live; `null` defers to
      // whether this is a live stream.
      showPlaybackSpeed: hidePlaybackSpeed == false || (hidePlaybackSpeed == null && !isLive),
      showQualitySelector: hideQualitySelector != true && video.length > 1,
    );
  }
}
