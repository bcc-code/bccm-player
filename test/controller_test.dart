import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/state/player_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'utils/mocks.mocks.dart';

void main() {
  late MockBccmPlayerInterface mockPlayerInterface;

  setUp(() {
    mockPlayerInterface = MockBccmPlayerInterface();
    BccmPlayerInterface.instance = mockPlayerInterface;
  });

  test('intialize', () async {
    // Arrange
    const fakePlayerId = '12345678-1234-1234-1234-123456789012';
    const fakeUrl = 'url.mp4';

    final stateNotifier = MockPlayerPluginStateNotifier();
    final playerStateNotifier = PlayerStateNotifier(keepAlive: false, player: const PlayerState(playerId: fakePlayerId));

    when(mockPlayerInterface.stateNotifier).thenAnswer((_) => stateNotifier);
    when(stateNotifier.getOrAddPlayerNotifier(any)).thenReturn(playerStateNotifier);
    when(mockPlayerInterface.newPlayer()).thenAnswer((_) async => fakePlayerId);

    // Act
    final BccmPlayerController controller = BccmPlayerController.networkUrl(Uri.parse(fakeUrl));
    await controller.initialize();

    // Assert
    verify(mockPlayerInterface.newPlayer()).called(1);
    final replaceCurrentMediaItemCall = verify(mockPlayerInterface.replaceCurrentMediaItem(fakePlayerId, captureAny));
    expect((replaceCurrentMediaItemCall.captured[0] as MediaItem).url, fakeUrl);

    playerStateNotifier.dispose();
  });
}
