import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/controls.dart';
import 'package:bccm_player/src/widgets/mini_player/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fake_platform.dart';
import '../utils/fixtures.dart';

void main() {
  late FakeBccmPlayerInterface fake;
  late BccmPlayerController controller;

  // The controller is built here rather than inside a testWidgets body on
  // purpose: PlayerStateNotifier starts a periodic timer, and a timer created
  // inside the body lands in the test's fake-async zone and trips the
  // pending-timer assertion before tearDown can dispose it.
  setUp(() async {
    fake = FakeBccmPlayerInterface.install();
    controller = BccmPlayerController(mediaItem(id: 'a'));
    await controller.initialize();
  });

  tearDown(() => fake.restore());

  Future<void> pumpMiniPlayer(WidgetTester tester, MiniPlayer miniPlayer) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(body: miniPlayer),
    ));
  }

  group('artwork', () {
    testWidgets('shows a thumbnail for a non-empty uri', (tester) async {
      await pumpMiniPlayer(
        tester,
        const MiniPlayer(
          secondaryTitle: 'Show',
          title: 'Episode',
          isPlaying: false,
          artworkUri: 'https://example.test/a.jpg',
        ),
      );

      expect(find.byType(FadeInImage), findsOneWidget);
    });

    testWidgets('omits the thumbnail for an empty uri', (tester) async {
      // The apps pass '' rather than null when an episode has no image.
      await pumpMiniPlayer(
        tester,
        const MiniPlayer(
          secondaryTitle: 'Show',
          title: 'Episode',
          isPlaying: false,
          artworkUri: '',
        ),
      );

      expect(find.byType(FadeInImage), findsNothing);
    });

    testWidgets('requires either an artwork uri or an image provider', (tester) async {
      expect(
        () => MiniPlayer(secondaryTitle: null, title: 'Episode', isPlaying: false),
        throwsAssertionError,
      );
    });
  });

  group('titles', () {
    testWidgets('renders both titles', (tester) async {
      await pumpMiniPlayer(
        tester,
        const MiniPlayer(
          secondaryTitle: 'Show name',
          title: 'Episode name',
          isPlaying: false,
          artworkUri: 'https://example.test/a.jpg',
        ),
      );

      expect(find.text('Show name'), findsOneWidget);
      expect(find.text('Episode name'), findsOneWidget);
    });

    testWidgets('omits the secondary title when null', (tester) async {
      await pumpMiniPlayer(
        tester,
        const MiniPlayer(
          secondaryTitle: null,
          title: 'Episode name',
          isPlaying: false,
          artworkUri: 'https://example.test/a.jpg',
        ),
      );

      expect(find.text('Episode name'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('play / pause', () {
    testWidgets('a paused player offers play, and tapping it calls onPlayTap', (tester) async {
      var plays = 0;
      var pauses = 0;
      await pumpMiniPlayer(
        tester,
        MiniPlayer(
          secondaryTitle: null,
          title: 'Episode',
          isPlaying: false,
          artworkUri: 'https://example.test/a.jpg',
          playSemanticLabel: 'Play',
          pauseSemanticLabel: 'Pause',
          onPlayTap: () => plays++,
          onPauseTap: () => pauses++,
        ),
      );

      expect(find.bySemanticsLabel('Play'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Play'));

      expect(plays, 1);
      expect(pauses, 0);
    });

    testWidgets('a playing player offers pause, and tapping it calls onPauseTap', (tester) async {
      var plays = 0;
      var pauses = 0;
      await pumpMiniPlayer(
        tester,
        MiniPlayer(
          secondaryTitle: null,
          title: 'Episode',
          isPlaying: true,
          artworkUri: 'https://example.test/a.jpg',
          playSemanticLabel: 'Play',
          pauseSemanticLabel: 'Pause',
          onPlayTap: () => plays++,
          onPauseTap: () => pauses++,
        ),
      );

      expect(find.bySemanticsLabel('Pause'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Pause'));

      expect(pauses, 1);
      expect(plays, 0);
    });

    testWidgets('loading replaces the button with an indicator', (tester) async {
      await pumpMiniPlayer(
        tester,
        const MiniPlayer(
          secondaryTitle: null,
          title: 'Episode',
          isPlaying: true,
          loading: true,
          artworkUri: 'https://example.test/a.jpg',
          pauseSemanticLabel: 'Pause',
        ),
      );

      expect(find.byType(LoadingIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Pause'), findsNothing);
    });

    testWidgets('a custom loading indicator is used when given', (tester) async {
      await pumpMiniPlayer(
        tester,
        const MiniPlayer(
          secondaryTitle: null,
          title: 'Episode',
          isPlaying: true,
          loading: true,
          artworkUri: 'https://example.test/a.jpg',
          loadingIndicator: Text('custom'),
        ),
      );

      expect(find.text('custom'), findsOneWidget);
      expect(find.byType(LoadingIndicator), findsNothing);
    });
  });

  group('close button', () {
    testWidgets('is shown and wired by default', (tester) async {
      var closes = 0;
      await pumpMiniPlayer(
        tester,
        MiniPlayer(
          secondaryTitle: null,
          title: 'Episode',
          isPlaying: false,
          artworkUri: 'https://example.test/a.jpg',
          onCloseTap: () => closes++,
        ),
      );

      // Three tappables: artwork area aside, the play button and the close
      // button are the GestureDetectors; close is the last one.
      final closeButton = find.byType(GestureDetector).last;
      await tester.tap(closeButton);

      expect(closes, 1);
    });

    testWidgets('is omitted when hidden', (tester) async {
      await pumpMiniPlayer(
        tester,
        const MiniPlayer(
          secondaryTitle: null,
          title: 'Episode',
          isPlaying: false,
          artworkUri: 'https://example.test/a.jpg',
          hideCloseButton: true,
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget, reason: 'only the play/pause tappable');
    });
  });

  group('progress bar', () {
    /// The filled part of the 2px bar, if it is drawn at all.
    Finder barFinder() => find.descendant(
          of: find.byType(SmoothVideoProgress),
          matching: find.byType(Container),
        );

    testWidgets('draws nothing when the media has no duration', (tester) async {
      // Guards a division by zero: without the duration check the width would
      // be NaN.
      await pumpMiniPlayer(
        tester,
        MiniPlayer(
          secondaryTitle: null,
          title: 'Episode',
          isPlaying: true,
          artworkUri: 'https://example.test/a.jpg',
          playerController: controller,
        ),
      );

      expect(find.byType(SmoothVideoProgress), findsOneWidget);
      expect(barFinder(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fills the fraction of the width matching the position', (tester) async {
      final notifier = fake.stateNotifier.getPlayerNotifier(controller.value.playerId)!;
      notifier.setStateFromSnapshot(snapshot(
        playerId: controller.value.playerId,
        playbackState: PlaybackState.paused,
        currentMediaItem: mediaItem(durationMs: 100000),
        playbackPositionMs: 25000,
      ));

      await pumpMiniPlayer(
        tester,
        MiniPlayer(
          secondaryTitle: null,
          title: 'Episode',
          isPlaying: false,
          artworkUri: 'https://example.test/a.jpg',
          playerController: controller,
        ),
      );
      await tester.pump();

      final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final size = tester.getSize(barFinder());

      expect(size.width, closeTo(screenWidth * 0.25, 1));
      expect(size.height, 2);
    });

    testWidgets('falls back to the primary controller when none is given', (tester) async {
      // The apps rely on this: MiniPlayer with no controller tracks whatever is
      // playing.
      await pumpMiniPlayer(
        tester,
        const MiniPlayer(
          secondaryTitle: null,
          title: 'Episode',
          isPlaying: false,
          artworkUri: 'https://example.test/a.jpg',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SmoothVideoProgress), findsOneWidget);
    });
  });
}
