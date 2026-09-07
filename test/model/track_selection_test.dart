import 'package:bccm_player/src/model/track_selection.dart';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fixtures.dart';

void main() {
  PlayerTracksSnapshot snapshotOf({
    List<Track?> audio = const [],
    List<Track?> text = const [],
    List<Track?> video = const [],
  }) {
    return PlayerTracksSnapshot(
      playerId: 'p1',
      audioTracks: audio,
      textTracks: text,
      videoTracks: video,
    );
  }

  List<String> idsOfTracks(List<Track> tracks) => tracks.map((t) => t.id).toList();

  group('no tracks', () {
    test('a null snapshot yields nothing to show', () {
      final selection = TrackSelection.from(null);

      expect(selection.audioTracks, isEmpty);
      expect(selection.textTracks, isEmpty);
      expect(selection.videoTracks, isEmpty);
      expect(selection.selectedAudioTrack, isNull);
      expect(selection.showAudioSelector, isFalse);
      expect(selection.showSubtitleSelector, isFalse);
      expect(selection.showQualitySelector, isFalse);
    });

    test('an empty snapshot still offers playback speed for VOD', () {
      // Speed does not depend on tracks, so an audio-less VOD still gets a row.
      final selection = TrackSelection.from(snapshotOf());

      expect(selection.isEmpty, isFalse);
      expect(selection.showPlaybackSpeed, isTrue);
    });

    test('pigeon nulls in the track lists are dropped', () {
      final selection = TrackSelection.from(snapshotOf(
        audio: [track(id: 'a'), null, track(id: 'b')],
        text: [null],
      ));

      expect(idsOfTracks(selection.audioTracks), ['a', 'b']);
      expect(selection.textTracks, isEmpty);
    });
  });

  group('audio', () {
    test('is offered only when there is a choice', () {
      expect(
        TrackSelection.from(snapshotOf(audio: [track(id: 'nor')])).showAudioSelector,
        isFalse,
        reason: 'a single audio track is not a choice',
      );
      expect(
        TrackSelection.from(snapshotOf(audio: [track(id: 'nor'), track(id: 'deu')])).showAudioSelector,
        isTrue,
      );
    });

    test('reports the selected track', () {
      final selection = TrackSelection.from(snapshotOf(
        audio: [track(id: 'nor'), track(id: 'deu', isSelected: true)],
      ));

      expect(selection.selectedAudioTrack?.id, 'deu');
    });
  });

  group('subtitles', () {
    test('a single track is still offered, because None is the other option', () {
      final selection = TrackSelection.from(snapshotOf(text: [track(id: 'nor')]));

      expect(selection.showSubtitleSelector, isTrue);
    });

    test('no tracks means no row', () {
      expect(TrackSelection.from(snapshotOf()).showSubtitleSelector, isFalse);
    });

    test('a null selected track means subtitles are off', () {
      final selection = TrackSelection.from(snapshotOf(text: [track(id: 'nor')]));

      expect(selection.selectedTextTrack, isNull);
    });
  });

  group('offline filtering', () {
    test('keeps only downloaded tracks when offline', () {
      final selection = TrackSelection.from(
        snapshotOf(
          audio: [track(id: 'nor', downloaded: true), track(id: 'deu', downloaded: false)],
          text: [track(id: 'sub-nor', downloaded: true), track(id: 'sub-deu', downloaded: false)],
        ),
        isOffline: true,
      );

      expect(idsOfTracks(selection.audioTracks), ['nor']);
      expect(idsOfTracks(selection.textTracks), ['sub-nor']);
    });

    test('treats an unknown downloaded flag as available', () {
      // Streams report `downloaded: null` rather than false.
      final selection = TrackSelection.from(
        snapshotOf(audio: [track(id: 'nor'), track(id: 'deu', downloaded: false)]),
        isOffline: true,
      );

      expect(idsOfTracks(selection.audioTracks), ['nor']);
    });

    test('does not filter when online', () {
      final selection = TrackSelection.from(
        snapshotOf(audio: [track(id: 'nor', downloaded: true), track(id: 'deu', downloaded: false)]),
      );

      expect(idsOfTracks(selection.audioTracks), ['nor', 'deu']);
    });

    test('keeps a selected track that filtering would have removed', () {
      // Otherwise the row would claim a selection the user cannot see, and
      // could not switch back to.
      final selection = TrackSelection.from(
        snapshotOf(audio: [
          track(id: 'nor', downloaded: true),
          track(id: 'deu', downloaded: false, isSelected: true),
        ]),
        isOffline: true,
      );

      expect(idsOfTracks(selection.audioTracks), ['nor', 'deu']);
      expect(selection.selectedAudioTrack?.id, 'deu');
    });

    test('does not duplicate a selected track that survived filtering', () {
      final selection = TrackSelection.from(
        snapshotOf(audio: [
          track(id: 'nor', downloaded: true, isSelected: true),
          track(id: 'deu', downloaded: true),
        ]),
        isOffline: true,
      );

      expect(idsOfTracks(selection.audioTracks), ['nor', 'deu']);
    });

    test('finds the selected track even when it was filtered out of the list', () {
      // The lookup runs on the unfiltered list on purpose.
      final selection = TrackSelection.from(
        snapshotOf(text: [track(id: 'sub-deu', downloaded: false, isSelected: true)]),
        isOffline: true,
      );

      expect(selection.selectedTextTrack?.id, 'sub-deu');
    });
  });

  group('video quality', () {
    test('reduces to one track per distinct height', () {
      final selection = TrackSelection.from(snapshotOf(video: [
        track(id: 'v1', height: 1080),
        track(id: 'v2', height: 1080),
        track(id: 'v3', height: 720),
      ]));

      expect(idsOfTracks(selection.videoTracks), ['v1', 'v3'], reason: 'the first of each height wins');
    });

    test('collapses every height-less track into one', () {
      final selection = TrackSelection.from(snapshotOf(video: [
        track(id: 'v1'),
        track(id: 'v2'),
        track(id: 'v3', height: 720),
      ]));

      expect(idsOfTracks(selection.videoTracks), ['v1', 'v3']);
    });

    test('is not offered when only one distinct height exists', () {
      // A ladder of same-height variants is not a quality choice.
      final selection = TrackSelection.from(snapshotOf(video: [
        track(id: 'v1', height: 1080),
        track(id: 'v2', height: 1080),
      ]));

      expect(selection.showQualitySelector, isFalse);
    });

    test('is offered for two or more distinct heights', () {
      final selection = TrackSelection.from(snapshotOf(video: [
        track(id: 'v1', height: 1080),
        track(id: 'v2', height: 720),
      ]));

      expect(selection.showQualitySelector, isTrue);
    });

    test('can be hidden explicitly', () {
      final selection = TrackSelection.from(
        snapshotOf(video: [track(id: 'v1', height: 1080), track(id: 'v2', height: 720)]),
        hideQualitySelector: true,
      );

      expect(selection.showQualitySelector, isFalse);
      expect(selection.videoTracks, hasLength(2), reason: 'hiding the row does not discard the tracks');
    });

    test('a null selected video track means automatic quality', () {
      final selection = TrackSelection.from(snapshotOf(video: [
        track(id: 'v1', height: 1080),
        track(id: 'v2', height: 720),
      ]));

      expect(selection.selectedVideoTrack, isNull);
    });

    test('reports an explicitly selected video track', () {
      final selection = TrackSelection.from(snapshotOf(video: [
        track(id: 'v1', height: 1080),
        track(id: 'v2', height: 720, isSelected: true),
      ]));

      expect(selection.selectedVideoTrack?.id, 'v2');
    });

    test('finds a selected track that height-deduping dropped from the list', () {
      final selection = TrackSelection.from(snapshotOf(video: [
        track(id: 'v1', height: 1080),
        track(id: 'v2', height: 1080, isSelected: true),
      ]));

      expect(idsOfTracks(selection.videoTracks), ['v1']);
      expect(selection.selectedVideoTrack?.id, 'v2', reason: 'lookup runs on the full list');
    });
  });

  group('playback speed', () {
    test('is shown for VOD by default', () {
      expect(TrackSelection.from(snapshotOf()).showPlaybackSpeed, isTrue);
    });

    test('is hidden for live by default', () {
      expect(TrackSelection.from(snapshotOf(), isLive: true).showPlaybackSpeed, isFalse);
    });

    test('an explicit false forces it on, even for live', () {
      // This is the only reason the flag is nullable rather than a plain bool.
      final selection = TrackSelection.from(snapshotOf(), isLive: true, hidePlaybackSpeed: false);

      expect(selection.showPlaybackSpeed, isTrue);
    });

    test('an explicit true hides it, even for VOD', () {
      final selection = TrackSelection.from(snapshotOf(), hidePlaybackSpeed: true);

      expect(selection.showPlaybackSpeed, isFalse);
    });
  });

  group('isEmpty', () {
    test('is true when a live stream has nothing else to offer', () {
      expect(TrackSelection.from(snapshotOf(), isLive: true).isEmpty, isTrue);
    });

    test('is false as soon as one row survives', () {
      final selection = TrackSelection.from(
        snapshotOf(text: [track(id: 'nor')]),
        isLive: true,
      );

      expect(selection.isEmpty, isFalse);
    });
  });
}
