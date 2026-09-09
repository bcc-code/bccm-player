import 'package:bccm_player/bccm_player.dart';
import 'package:mockito/annotations.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

@GenerateNiceMocks([
  // ignore: deprecated_member_use
  MockSpec<BccmPlayerInterface>(mixingIn: [MockPlatformInterfaceMixin]),
  MockSpec<PlayerPluginStateNotifier>(),
  // PlayerStateNotifier is deliberately not mocked. Its `state`/`debugState`/`getState`
  // return a non-nullable PlayerState, so mockito synthesises a `SmartFake` for it — and
  // since freezed 4 puts DiagnosticableTreeMixin on the generated mixin, PlayerState's
  // interface requires `toString({DiagnosticLevel minLevel})`, which SmartFake cannot
  // satisfy. The mock was unused, so the spec is simply dropped.
])
export 'mocks.mocks.dart';
