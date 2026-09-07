import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fake_platform.dart';
import '../utils/fixtures.dart';

/// Covers the wiring between the settings sheet and [TrackSelection] — the
/// resolution rules themselves are tested directly in
/// `test/model/track_selection_test.dart`.
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

  void setTracks({
    List<Track?> audio = const [],
    List<Track?> text = const [],
    List<Track?> video = const [],
  }) {
    fake.tracks = PlayerTracksSnapshot(
      playerId: controller.value.playerId,
      audioTracks: audio,
      textTracks: text,
      videoTracks: video,
    );
  }

  /// Opens the settings sheet and settles it.
  Future<void> openSheet(WidgetTester tester, {BccmPlayerViewConfig? config}) async {
    final viewController = BccmPlayerViewController(playerController: controller, config: config);
    addTearDown(viewController.dispose);

    await tester.pumpWidget(MaterialApp(
      home: BccmPlayerTheme(
        playerTheme: BccmPlayerThemeData(),
        builder: (context) => Scaffold(
          body: SettingsButton(
            viewController: viewController,
            controlsTheme: BccmControlsThemeData.defaultTheme(context),
          ),
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
  }

  testWidgets('offers every row when the media supports it', (tester) async {
    setTracks(
      audio: [track(id: 'nor', label: 'Norsk', isSelected: true), track(id: 'deu', label: 'Deutsch')],
      text: [track(id: 'sub-nor', label: 'Norsk')],
      video: [track(id: 'v1', height: 1080), track(id: 'v2', height: 720)],
    );

    await openSheet(tester);

    expect(find.text('Audio: Norsk'), findsOneWidget);
    expect(find.text('Subtitles: None'), findsOneWidget);
    expect(find.text('Playback speed: 1.0x'), findsOneWidget);
    expect(find.textContaining('Quality: Auto'), findsOneWidget);
  });

  testWidgets('hides the audio row when there is only one track', (tester) async {
    setTracks(audio: [track(id: 'nor', label: 'Norsk')]);

    await openSheet(tester);

    expect(find.textContaining('Audio:'), findsNothing);
  });

  testWidgets('hides the quality row when every variant is the same height', (tester) async {
    setTracks(video: [track(id: 'v1', height: 1080), track(id: 'v2', height: 1080)]);

    await openSheet(tester);

    expect(find.textContaining('Quality:'), findsNothing);
  });

  testWidgets('hides playback speed for a live stream', (tester) async {
    notifier.setMediaItem(mediaItem(id: 'live', isLive: true));
    setTracks();

    await openSheet(tester);

    expect(find.textContaining('Playback speed:'), findsNothing);
    expect(find.text('No settings available for this video.'), findsOneWidget);
  });

  testWidgets('honours hideQualitySelector from the config', (tester) async {
    setTracks(video: [track(id: 'v1', height: 1080), track(id: 'v2', height: 720)]);

    await openSheet(
      tester,
      config: BccmPlayerViewConfig(
        controlsConfig: BccmPlayerControlsConfig(hideQualitySelector: true),
      ),
    );

    expect(find.textContaining('Quality:'), findsNothing);
  });

  testWidgets('lists only downloaded tracks for offline media', (tester) async {
    notifier.setMediaItem(mediaItem(id: 'downloaded', isOffline: true));
    setTracks(audio: [
      track(id: 'nor', label: 'Norsk', downloaded: true),
      track(id: 'deu', label: 'Deutsch', downloaded: true),
      track(id: 'fra', label: 'Français', downloaded: false),
    ]);

    await openSheet(tester);
    await tester.tap(find.textContaining('Audio:'));
    await tester.pumpAndSettle();

    expect(find.text('Norsk'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('Français'), findsNothing);
  });

  testWidgets('selecting an audio track pushes it to the platform', (tester) async {
    setTracks(audio: [
      track(id: 'nor', label: 'Norsk', isSelected: true),
      track(id: 'deu', label: 'Deutsch'),
    ]);

    await openSheet(tester);
    await tester.tap(find.text('Audio: Norsk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(fake.setSelectedTrackCalls.single.type, TrackType.audio);
    expect(fake.setSelectedTrackCalls.single.trackId, 'deu');
  });

  testWidgets('shows the empty state when nothing is configurable', (tester) async {
    notifier.setMediaItem(mediaItem(id: 'live', isLive: true));
    setTracks(audio: [track(id: 'nor')]);

    await openSheet(tester);

    expect(find.text('No settings available for this video.'), findsOneWidget);
  });

  testWidgets('renders caller-supplied extra settings above the built-in rows', (tester) async {
    setTracks();

    await openSheet(
      tester,
      config: BccmPlayerViewConfig(
        controlsConfig: BccmPlayerControlsConfig(
          extraSettingsBuilder: (context) => [const ListTile(title: Text('Extra thing'))],
        ),
      ),
    );

    expect(find.text('Extra thing'), findsOneWidget);
  });
}
