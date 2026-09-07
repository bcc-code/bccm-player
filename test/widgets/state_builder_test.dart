import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fake_platform.dart';
import '../utils/fixtures.dart';

void main() {
  late FakeBccmPlayerInterface fake;
  late PlayerStateNotifier p1;
  late PlayerStateNotifier p2;
  late PlayerStateNotifier local;
  late PlayerStateNotifier cast;

  // Players are created here, not inside the test bodies: PlayerStateNotifier
  // starts a periodic timer, and one created inside a testWidgets body lands in
  // that test's fake-async zone and trips the pending-timer assertion before
  // tearDown can dispose it.
  setUp(() {
    fake = FakeBccmPlayerInterface.install();
    p1 = fake.stateNotifier.getOrAddPlayerNotifier('p1');
    p2 = fake.stateNotifier.getOrAddPlayerNotifier('p2');
    local = fake.stateNotifier.getOrAddPlayerNotifier('local');
    cast = fake.stateNotifier.getOrAddPlayerNotifier('chromecast');
  });

  tearDown(() => fake.restore());

  group('BccmPlayerStateBuilder', () {
    testWidgets('builds with the selected value for an explicit player', (tester) async {
      final notifier = p1;
      notifier.setPlaybackState(PlaybackState.playing);

      await tester.pumpWidget(MaterialApp(
        home: BccmPlayerStateBuilder<PlaybackState>(
          playerId: 'p1',
          select: (state) => state.playbackState,
          builder: (context, state) => Text('$state'),
        ),
      ));

      expect(find.text('PlaybackState.playing'), findsOneWidget);
    });

    testWidgets('rebuilds when the selected value changes', (tester) async {
      final notifier = p1;
      notifier.setPlaybackState(PlaybackState.paused);

      await tester.pumpWidget(MaterialApp(
        home: BccmPlayerStateBuilder<PlaybackState>(
          playerId: 'p1',
          select: (state) => state.playbackState,
          builder: (context, state) => Text('$state'),
        ),
      ));
      expect(find.text('PlaybackState.paused'), findsOneWidget);

      notifier.setPlaybackState(PlaybackState.playing);
      await tester.pump();

      expect(find.text('PlaybackState.playing'), findsOneWidget);
    });

    testWidgets('does not rebuild for state changes outside the selection', (tester) async {
      final notifier = p1;
      notifier.setPlaybackState(PlaybackState.playing);
      var builds = 0;

      await tester.pumpWidget(MaterialApp(
        home: BccmPlayerStateBuilder<PlaybackState>(
          playerId: 'p1',
          select: (state) => state.playbackState,
          builder: (context, state) {
            builds++;
            return const SizedBox.shrink();
          },
        ),
      ));
      final initial = builds;

      notifier.setPlaybackPosition(9999);
      await tester.pump();

      expect(builds, initial, reason: 'position is not part of the selection');
    });

    testWidgets('hands the builder null for an unknown player', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: BccmPlayerStateBuilder<PlaybackState>(
          playerId: 'does-not-exist',
          select: (state) => state.playbackState,
          builder: (context, state) => Text(state == null ? 'no player' : '$state'),
        ),
      ));

      expect(find.text('no player'), findsOneWidget);
    });

    testWidgets('a null playerId follows the primary player', (tester) async {
      final primary = p1;
      primary.setPlaybackState(PlaybackState.playing);
      fake.stateNotifier.setPrimaryPlayer('p1');

      await tester.pumpWidget(MaterialApp(
        home: BccmPlayerStateBuilder<PlaybackState>(
          playerId: null,
          select: (state) => state.playbackState,
          builder: (context, state) => Text('$state'),
        ),
      ));

      expect(find.text('PlaybackState.playing'), findsOneWidget);
    });

    testWidgets('a null playerId picks up a change of primary player', (tester) async {
      // The cast-handover case: the same widget has to start reading the other
      // player without being rebuilt by its parent.
      local.setPlaybackState(PlaybackState.playing);
      cast.setPlaybackState(PlaybackState.paused);
      fake.stateNotifier.setPrimaryPlayer('local');

      await tester.pumpWidget(MaterialApp(
        home: BccmPlayerStateBuilder<PlaybackState>(
          playerId: null,
          select: (state) => state.playbackState,
          builder: (context, state) => Text('$state'),
        ),
      ));
      expect(find.text('PlaybackState.playing'), findsOneWidget);

      fake.stateNotifier.setPrimaryPlayer('chromecast');
      await tester.pump();

      expect(find.text('PlaybackState.paused'), findsOneWidget);
    });

    testWidgets('builds null when there is no primary player at all', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: BccmPlayerStateBuilder<PlaybackState>(
          playerId: null,
          select: (state) => state.playbackState,
          builder: (context, state) => Text(state == null ? 'no player' : '$state'),
        ),
      ));

      expect(find.text('no player'), findsOneWidget);
    });
  });

  group('StateNotifierSelectBuilder', () {
    testWidgets('switches to a new notifier when the widget is updated', (tester) async {
      final first = p1;
      first.setPlaybackState(PlaybackState.playing);
      final second = p2;
      second.setPlaybackState(PlaybackState.paused);

      Widget build(PlayerStateNotifier notifier) => MaterialApp(
            home: StateNotifierSelectBuilder<PlayerState, PlaybackState>(
              stateNotifier: notifier,
              select: (state) => state.playbackState,
              builder: (context, state, child) => Text('$state'),
            ),
          );

      await tester.pumpWidget(build(first));
      expect(find.text('PlaybackState.playing'), findsOneWidget);

      await tester.pumpWidget(build(second));
      expect(find.text('PlaybackState.paused'), findsOneWidget);
    });

    testWidgets('stops listening to the notifier it was moved off', (tester) async {
      final first = p1;
      first.setPlaybackState(PlaybackState.playing);
      final second = p2;
      second.setPlaybackState(PlaybackState.paused);

      Widget build(PlayerStateNotifier notifier) => MaterialApp(
            home: StateNotifierSelectBuilder<PlayerState, PlaybackState>(
              stateNotifier: notifier,
              select: (state) => state.playbackState,
              builder: (context, state, child) => Text('$state'),
            ),
          );

      await tester.pumpWidget(build(first));
      await tester.pumpWidget(build(second));

      first.setPlaybackState(PlaybackState.stopped);
      await tester.pump();

      expect(find.text('PlaybackState.paused'), findsOneWidget,
          reason: 'the old notifier must no longer drive this widget');
    });

    testWidgets('passes the child straight through', (tester) async {
      final notifier = p1;

      await tester.pumpWidget(MaterialApp(
        home: StateNotifierSelectBuilder<PlayerState, PlaybackState>(
          stateNotifier: notifier,
          select: (state) => state.playbackState,
          child: const Text('child'),
          builder: (context, state, child) => child!,
        ),
      ));

      expect(find.text('child'), findsOneWidget);
    });

    testWidgets('removes its listener on dispose', (tester) async {
      final notifier = p1;

      await tester.pumpWidget(MaterialApp(
        home: StateNotifierSelectBuilder<PlayerState, PlaybackState>(
          stateNotifier: notifier,
          select: (state) => state.playbackState,
          builder: (context, state, child) => const SizedBox.shrink(),
        ),
      ));
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      // A setState on a disposed State would throw here.
      notifier.setPlaybackState(PlaybackState.stopped);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('compares selections by identity, so equal strings still rebuild', (tester) async {
      // `_listener` uses `!identical(temp, state)` rather than `!=`. For enums,
      // bools and small ints that behaves like equality, but a select that
      // builds a String rebuilds on every notification even when the value has
      // not changed. Pinned rather than changed: it is a rebuild-frequency
      // wrinkle, not a correctness bug.
      final notifier = p1;
      notifier.setMediaItem(mediaItem(id: 'a', title: 'Same'));
      var builds = 0;

      await tester.pumpWidget(MaterialApp(
        home: StateNotifierSelectBuilder<PlayerState, String>(
          stateNotifier: notifier,
          // A fresh String instance each time, equal but never identical.
          select: (state) => 'title: ${state.currentMediaItem?.metadata?.title}',
          builder: (context, state, child) {
            builds++;
            return const SizedBox.shrink();
          },
        ),
      ));
      final initial = builds;

      notifier.setMediaItem(mediaItem(id: 'a', title: 'Same'));
      await tester.pump();

      expect(builds, greaterThan(initial));
    });
  });
}
