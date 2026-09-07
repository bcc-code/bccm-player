import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fake_platform.dart';
import '../utils/fixtures.dart';

void main() {
  late FakeBccmPlayerInterface fake;
  late BccmPlayerController controller;
  late PlayerStateNotifier notifier;

  setUp(() async {
    fake = FakeBccmPlayerInterface.install();
    controller = BccmPlayerController(mediaItem(id: 'a'));
    await controller.initialize();
    notifier = fake.stateNotifier.getPlayerNotifier(controller.value.playerId)!;
  });

  tearDown(() => fake.restore());

  void setState({
    required PlaybackState playbackState,
    double? durationMs,
    double? positionMs,
  }) {
    notifier.setStateFromSnapshot(snapshot(
      playerId: controller.value.playerId,
      playbackState: playbackState,
      currentMediaItem: durationMs == null ? null : mediaItem(durationMs: durationMs),
      playbackPositionMs: positionMs,
    ));
  }

  Future<void> pumpButton(
    WidgetTester tester, {
    VoidCallback? onTap,
    String? text,
    Duration appearAtTimeLeft = const Duration(seconds: 10),
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PlayNextButton(
          playerController: controller,
          onTap: onTap,
          text: text,
          appearAtTimeLeft: appearAtTimeLeft,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('visibility', () {
    testWidgets('appears once the time left drops below the threshold', (tester) async {
      setState(playbackState: PlaybackState.playing, durationMs: 100000, positionMs: 95000);

      await pumpButton(tester);

      expect(find.text('Next Video'), findsOneWidget);
    });

    testWidgets('stays hidden while there is plenty left', (tester) async {
      setState(playbackState: PlaybackState.playing, durationMs: 100000, positionMs: 50000);

      await pumpButton(tester);

      expect(find.text('Next Video'), findsNothing);
    });

    testWidgets('never appears for media shorter than the threshold', (tester) async {
      // A five second clip would otherwise show the button for its whole
      // duration.
      setState(playbackState: PlaybackState.playing, durationMs: 5000, positionMs: 0);

      await pumpButton(tester);

      expect(find.text('Next Video'), findsNothing);
    });

    testWidgets('stays hidden while the duration is unknown', (tester) async {
      setState(playbackState: PlaybackState.playing, positionMs: 1000);

      await pumpButton(tester);

      expect(find.text('Next Video'), findsNothing);
    });

    testWidgets('appears when playback crosses the threshold after mounting', (tester) async {
      setState(playbackState: PlaybackState.playing, durationMs: 100000, positionMs: 50000);
      await pumpButton(tester);
      expect(find.text('Next Video'), findsNothing);

      setState(playbackState: PlaybackState.playing, durationMs: 100000, positionMs: 92000);
      await tester.pumpAndSettle();

      expect(find.text('Next Video'), findsOneWidget);
    });

    testWidgets('respects a custom threshold', (tester) async {
      setState(playbackState: PlaybackState.playing, durationMs: 100000, positionMs: 75000);

      await pumpButton(tester, appearAtTimeLeft: const Duration(seconds: 30));

      expect(find.text('Next Video'), findsOneWidget);
    });
  });

  group('content', () {
    testWidgets('uses custom label text', (tester) async {
      setState(playbackState: PlaybackState.playing, durationMs: 100000, positionMs: 95000);

      await pumpButton(tester, text: 'Neste episode');

      expect(find.text('Neste episode'), findsOneWidget);
      expect(find.text('Next Video'), findsNothing);
    });

    testWidgets('shows a spinner instead of the play icon at the very end', (tester) async {
      // timeLeft == 0 while still playing means the next item is being loaded.
      setState(playbackState: PlaybackState.playing, durationMs: 100000, positionMs: 100000);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PlayNextButton(playerController: controller, onTap: () {}),
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the play icon, not a spinner, before the end', (tester) async {
      setState(playbackState: PlaybackState.playing, durationMs: 100000, positionMs: 95000);

      await pumpButton(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('interaction', () {
    testWidgets('tapping invokes onTap', (tester) async {
      var taps = 0;
      setState(playbackState: PlaybackState.playing, durationMs: 100000, positionMs: 95000);

      await pumpButton(tester, onTap: () => taps++);
      await tester.tap(find.text('Next Video'));

      expect(taps, 1);
    });
  });
}
