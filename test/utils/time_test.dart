import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/utils/extensions.dart';
import 'package:bccm_player/src/utils/num.dart';
import 'package:bccm_player/src/utils/time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getFormattedDuration', () {
    test('omits the hours segment below one hour', () {
      expect(getFormattedDuration(0), '00:00');
      expect(getFormattedDuration(999), '00:00');
      expect(getFormattedDuration(1000), '00:01');
      expect(getFormattedDuration(59000), '00:59');
      expect(getFormattedDuration(60000), '01:00');
      expect(getFormattedDuration(3599000), '59:59');
    });

    test('includes hours from one hour up', () {
      expect(getFormattedDuration(3600000), '01:00:00');
      expect(getFormattedDuration(3661000), '01:01:01');
      expect(getFormattedDuration(36000000), '10:00:00');
    });

    test('treats non-finite input as zero rather than throwing', () {
      // Regression: `Duration(milliseconds: nan.toInt())` throws
      // UnsupportedError, which would take the whole controls overlay down.
      // Reachable whenever the safeDouble/safeInt guards upstream are bypassed.
      expect(getFormattedDuration(double.nan), '00:00');
      expect(getFormattedDuration(double.infinity), '00:00');
      expect(getFormattedDuration(double.negativeInfinity), '00:00');
    });

    test('clamps negative input to zero', () {
      // Regression: -1000ms used to format as "00:59", because Dart's % is
      // always non-negative.
      expect(getFormattedDuration(-1000), '00:00');
      expect(getFormattedDuration(-61000), '00:00');
    });
  });

  group('calcTimeLeftMs', () {
    test('is the remaining duration', () {
      expect(calcTimeLeftMs(duration: 5000, currentMs: 1000), 4000);
    });

    test('never goes negative when the position overshoots the duration', () {
      expect(calcTimeLeftMs(duration: 1000, currentMs: 2000), 0);
    });

    test('treats nulls as zero', () {
      expect(calcTimeLeftMs(duration: null, currentMs: null), 0);
      expect(calcTimeLeftMs(duration: 5000, currentMs: null), 5000);
      expect(calcTimeLeftMs(duration: null, currentMs: 1000), 0);
    });

    test('treats a non-finite duration as zero', () {
      expect(calcTimeLeftMs(duration: double.nan, currentMs: 5), 0);
      expect(calcTimeLeftMs(duration: double.infinity, currentMs: 5), 0);
    });

    test('treats a non-finite position as zero, leaving the full duration', () {
      expect(calcTimeLeftMs(duration: 5000, currentMs: double.nan), 5000);
    });
  });

  group('safeDouble', () {
    test('passes finite values through', () {
      expect(safeDouble(1.5), 1.5);
      expect(safeDouble(-1.5), -1.5);
      expect(safeDouble(0), 0);
    });

    test('maps non-finite values to zero', () {
      // This is the guard that keeps NaN out of the timeline arithmetic.
      expect(safeDouble(double.nan), 0);
      expect(safeDouble(double.infinity), 0);
      expect(safeDouble(double.negativeInfinity), 0);
    });
  });

  group('finiteOrNull', () {
    test('keeps finite values and nulls the rest', () {
      expect(1.5.finiteOrNull(), 1.5);
      expect(double.nan.finiteOrNull(), isNull);
      expect(double.infinity.finiteOrNull(), isNull);
    });
  });

  group('asOrNull', () {
    test('casts on a match and yields null otherwise', () {
      const Object? value = 'hello';
      expect(value.asOrNull<String>(), 'hello');
      expect(value.asOrNull<int>(), isNull);
      expect(null.asOrNull<String>(), isNull);
    });
  });

  group('VideoSize.aspectRatio', () {
    test('is width over height', () {
      expect(VideoSize(width: 1920, height: 1080).aspectRatio, 1920 / 1080);
      expect(VideoSize(width: 1080, height: 1920).aspectRatio, 1080 / 1920);
      expect(VideoSize(width: 100, height: 100).aspectRatio, 1);
    });

    test('is non-finite for a zero height rather than throwing', () {
      // Consumers branch on `> 1` / `< 1` (see BccmPlayerViewController's
      // orientation logic), so this needs to not blow up on an uninitialised
      // video size.
      expect(VideoSize(width: 1920, height: 0).aspectRatio.isFinite, isFalse);
    });
  });

  group('Track.labelWithFallback', () {
    Track videoTrack({int? height, double? frameRate}) =>
        Track(id: 'v', height: height, frameRate: frameRate, isSelected: false);

    test('describes a video track by height', () {
      expect(videoTrack(height: 720).labelWithFallback, '720p');
    });

    test('appends the frame rate only when it is not 30', () {
      expect(videoTrack(height: 720, frameRate: 30).labelWithFallback, '720p');
      expect(videoTrack(height: 720, frameRate: 60).labelWithFallback, '720p (60fps)');
      expect(videoTrack(height: 1080, frameRate: 59.94).labelWithFallback, '1080p (59fps)');
    });

    test('falls back label -> language -> id when there is no height', () {
      expect(
        Track(id: 'id', label: 'Norsk', language: 'nor', isSelected: false).labelWithFallback,
        'Norsk',
      );
      expect(Track(id: 'id', language: 'nor', isSelected: false).labelWithFallback, 'nor');
      expect(Track(id: 'id', isSelected: false).labelWithFallback, 'id');
    });
  });

  group('TrackListX.safe', () {
    test('drops the nulls pigeon leaves in track lists', () {
      final tracks = <Track?>[Track(id: 'a', isSelected: false), null, Track(id: 'b', isSelected: false)];

      expect(tracks.safe.map((t) => t.id), ['a', 'b']);
    });
  });
}
