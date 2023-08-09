import 'package:bccm_player/bccm_player.dart';
import 'package:mockito/annotations.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

@GenerateNiceMocks([
  // ignore: deprecated_member_use
  MockSpec<BccmPlayerInterface>(mixingIn: [MockPlatformInterfaceMixin]),
  MockSpec<PlayerPluginStateNotifier>(),
  MockSpec<PlayerStateNotifier>(),
])
export 'mocks.mocks.dart';
