// Mocks generated by Mockito 5.4.4 from annotations
// in bccm_player/test/utils/mocks.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:bccm_player/bccm_player.dart' as _i2;
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart' as _i7;
import 'package:bccm_player/src/queue/queue_controller.dart' as _i4;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i6;
import 'package:plugin_platform_interface/plugin_platform_interface.dart'
    as _i5;
import 'package:state_notifier/state_notifier.dart' as _i8;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakePlayerPluginStateNotifier_0 extends _i1.SmartFake
    implements _i2.PlayerPluginStateNotifier {
  _FakePlayerPluginStateNotifier_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeBccmPlayerController_1 extends _i1.SmartFake
    implements _i2.BccmPlayerController {
  _FakeBccmPlayerController_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeMediaInfo_2 extends _i1.SmartFake implements _i2.MediaInfo {
  _FakeMediaInfo_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakePlayerPluginState_3 extends _i1.SmartFake
    implements _i2.PlayerPluginState {
  _FakePlayerPluginState_3(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakePlayerStateNotifier_4 extends _i1.SmartFake
    implements _i2.PlayerStateNotifier {
  _FakePlayerStateNotifier_4(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeTimer_5 extends _i1.SmartFake implements _i3.Timer {
  _FakeTimer_5(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeQueueManager_6 extends _i1.SmartFake implements _i4.QueueManager {
  _FakeQueueManager_6(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakePlayerState_7 extends _i1.SmartFake implements _i2.PlayerState {
  _FakePlayerState_7(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [BccmPlayerInterface].
///
/// See the documentation for Mockito's code generation for more information.
class MockBccmPlayerInterface extends _i1.Mock
    with _i5.MockPlatformInterfaceMixin
    implements _i2.BccmPlayerInterface {
  @override
  _i2.PlayerPluginStateNotifier get stateNotifier => (super.noSuchMethod(
        Invocation.getter(#stateNotifier),
        returnValue: _FakePlayerPluginStateNotifier_0(
          this,
          Invocation.getter(#stateNotifier),
        ),
        returnValueForMissingStub: _FakePlayerPluginStateNotifier_0(
          this,
          Invocation.getter(#stateNotifier),
        ),
      ) as _i2.PlayerPluginStateNotifier);

  @override
  _i3.Stream<_i2.ChromecastEvent> get chromecastEventStream =>
      (super.noSuchMethod(
        Invocation.getter(#chromecastEventStream),
        returnValue: _i3.Stream<_i2.ChromecastEvent>.empty(),
        returnValueForMissingStub: _i3.Stream<_i2.ChromecastEvent>.empty(),
      ) as _i3.Stream<_i2.ChromecastEvent>);

  @override
  _i3.Stream<dynamic> get playerEventStream => (super.noSuchMethod(
        Invocation.getter(#playerEventStream),
        returnValue: _i3.Stream<dynamic>.empty(),
        returnValueForMissingStub: _i3.Stream<dynamic>.empty(),
      ) as _i3.Stream<dynamic>);

  @override
  _i2.BccmPlayerController get primaryController => (super.noSuchMethod(
        Invocation.getter(#primaryController),
        returnValue: _FakeBccmPlayerController_1(
          this,
          Invocation.getter(#primaryController),
        ),
        returnValueForMissingStub: _FakeBccmPlayerController_1(
          this,
          Invocation.getter(#primaryController),
        ),
      ) as _i2.BccmPlayerController);

  @override
  _i3.Future<void> setup() => (super.noSuchMethod(
        Invocation.method(
          #setup,
          [],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  _i3.Future<String> newPlayer({
    _i2.BufferMode? bufferMode,
    bool? disableNpaw,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #newPlayer,
          [],
          {
            #bufferMode: bufferMode,
            #disableNpaw: disableNpaw,
          },
        ),
        returnValue: _i3.Future<String>.value(_i6.dummyValue<String>(
          this,
          Invocation.method(
            #newPlayer,
            [],
            {
              #bufferMode: bufferMode,
              #disableNpaw: disableNpaw,
            },
          ),
        )),
        returnValueForMissingStub:
            _i3.Future<String>.value(_i6.dummyValue<String>(
          this,
          Invocation.method(
            #newPlayer,
            [],
            {
              #bufferMode: bufferMode,
              #disableNpaw: disableNpaw,
            },
          ),
        )),
      ) as _i3.Future<String>);

  @override
  _i3.Future<void> disposePlayer(String? playerId) => (super.noSuchMethod(
        Invocation.method(
          #disposePlayer,
          [playerId],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  _i3.Future<bool> setPrimary(String? id) => (super.noSuchMethod(
        Invocation.method(
          #setPrimary,
          [id],
        ),
        returnValue: _i3.Future<bool>.value(false),
        returnValueForMissingStub: _i3.Future<bool>.value(false),
      ) as _i3.Future<bool>);

  @override
  _i3.Future<void> replaceCurrentMediaItem(
    String? playerId,
    _i2.MediaItem? mediaItem, {
    bool? playbackPositionFromPrimary,
    bool? autoplay = true,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #replaceCurrentMediaItem,
          [
            playerId,
            mediaItem,
          ],
          {
            #playbackPositionFromPrimary: playbackPositionFromPrimary,
            #autoplay: autoplay,
          },
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  _i3.Future<void> replaceCurrentOfflineAsset(
    String? playerId,
    String? downloadKey, {
    bool? playbackPositionFromPrimary,
    bool? autoplay = true,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #replaceCurrentOfflineAsset,
          [
            playerId,
            downloadKey,
          ],
          {
            #playbackPositionFromPrimary: playbackPositionFromPrimary,
            #autoplay: autoplay,
          },
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  _i3.Future<void> queueMediaItem(
    String? playerId,
    _i2.MediaItem? mediaItem,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #queueMediaItem,
          [
            playerId,
            mediaItem,
          ],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  _i3.Future<_i7.ChromecastState?> getChromecastState() => (super.noSuchMethod(
        Invocation.method(
          #getChromecastState,
          [],
        ),
        returnValue: _i3.Future<_i7.ChromecastState?>.value(),
        returnValueForMissingStub: _i3.Future<_i7.ChromecastState?>.value(),
      ) as _i3.Future<_i7.ChromecastState?>);

  @override
  _i3.Future<_i2.PlayerTracksSnapshot?> getPlayerTracks({String? playerId}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getPlayerTracks,
          [],
          {#playerId: playerId},
        ),
        returnValue: _i3.Future<_i2.PlayerTracksSnapshot?>.value(),
        returnValueForMissingStub:
            _i3.Future<_i2.PlayerTracksSnapshot?>.value(),
      ) as _i3.Future<_i2.PlayerTracksSnapshot?>);

  @override
  _i3.Future<_i7.PlayerStateSnapshot?> getPlayerState({String? playerId}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getPlayerState,
          [],
          {#playerId: playerId},
        ),
        returnValue: _i3.Future<_i7.PlayerStateSnapshot?>.value(),
        returnValueForMissingStub: _i3.Future<_i7.PlayerStateSnapshot?>.value(),
      ) as _i3.Future<_i7.PlayerStateSnapshot?>);

  @override
  void openExpandedCastController() => super.noSuchMethod(
        Invocation.method(
          #openExpandedCastController,
          [],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void openCastDialog() => super.noSuchMethod(
        Invocation.method(
          #openCastDialog,
          [],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.Future<void> addPlaybackListener(_i7.PlaybackListenerPigeon? listener) =>
      (super.noSuchMethod(
        Invocation.method(
          #addPlaybackListener,
          [listener],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  _i3.Future<void> removePlaybackListener(
          _i7.PlaybackListenerPigeon? listener) =>
      (super.noSuchMethod(
        Invocation.method(
          #removePlaybackListener,
          [listener],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  void play(String? playerId) => super.noSuchMethod(
        Invocation.method(
          #play,
          [playerId],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.Future<void> seekTo(
    String? playerId,
    double? positionMs,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #seekTo,
          [
            playerId,
            positionMs,
          ],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  void pause(String? playerId) => super.noSuchMethod(
        Invocation.method(
          #pause,
          [playerId],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void stop(
    String? playerId,
    bool? reset,
  ) =>
      super.noSuchMethod(
        Invocation.method(
          #stop,
          [
            playerId,
            reset,
          ],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.Future<void> setSelectedTrack(
    String? playerId,
    _i2.TrackType? type,
    String? trackId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #setSelectedTrack,
          [
            playerId,
            type,
            trackId,
          ],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  _i3.Future<void> setPlaybackSpeed(
    String? playerId,
    double? speed,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #setPlaybackSpeed,
          [
            playerId,
            speed,
          ],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  _i3.Future<void> setVolume(
    String? playerId,
    double? volume,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #setVolume,
          [
            playerId,
            volume,
          ],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  void exitFullscreen(String? playerId) => super.noSuchMethod(
        Invocation.method(
          #exitFullscreen,
          [playerId],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.Future<void> enterFullscreen(String? playerId) => (super.noSuchMethod(
        Invocation.method(
          #enterFullscreen,
          [playerId],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  void setAppConfig(_i2.AppConfig? config) => super.noSuchMethod(
        Invocation.method(
          #setAppConfig,
          [config],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void setPlayerViewVisibility(
    int? viewId,
    bool? visible,
  ) =>
      super.noSuchMethod(
        Invocation.method(
          #setPlayerViewVisibility,
          [
            viewId,
            visible,
          ],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.Future<void> setMixWithOthers(
    String? playerId,
    bool? mixWithOthers,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #setMixWithOthers,
          [
            playerId,
            mixWithOthers,
          ],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  _i3.Future<int> createVideoTexture() => (super.noSuchMethod(
        Invocation.method(
          #createVideoTexture,
          [],
        ),
        returnValue: _i3.Future<int>.value(0),
        returnValueForMissingStub: _i3.Future<int>.value(0),
      ) as _i3.Future<int>);

  @override
  _i3.Future<bool> disposeVideoTexture(int? textureId) => (super.noSuchMethod(
        Invocation.method(
          #disposeVideoTexture,
          [textureId],
        ),
        returnValue: _i3.Future<bool>.value(false),
        returnValueForMissingStub: _i3.Future<bool>.value(false),
      ) as _i3.Future<bool>);

  @override
  _i3.Future<int> switchToVideoTexture(
    String? playerId,
    int? textureId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #switchToVideoTexture,
          [
            playerId,
            textureId,
          ],
        ),
        returnValue: _i3.Future<int>.value(0),
        returnValueForMissingStub: _i3.Future<int>.value(0),
      ) as _i3.Future<int>);

  @override
  _i3.Future<_i2.MediaInfo> fetchMediaInfo({
    required String? url,
    String? mimeType,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #fetchMediaInfo,
          [],
          {
            #url: url,
            #mimeType: mimeType,
          },
        ),
        returnValue: _i3.Future<_i2.MediaInfo>.value(_FakeMediaInfo_2(
          this,
          Invocation.method(
            #fetchMediaInfo,
            [],
            {
              #url: url,
              #mimeType: mimeType,
            },
          ),
        )),
        returnValueForMissingStub:
            _i3.Future<_i2.MediaInfo>.value(_FakeMediaInfo_2(
          this,
          Invocation.method(
            #fetchMediaInfo,
            [],
            {
              #url: url,
              #mimeType: mimeType,
            },
          ),
        )),
      ) as _i3.Future<_i2.MediaInfo>);

  @override
  _i3.Future<void> setRepeatMode(
    String? playerId,
    _i2.RepeatMode? repeatMode,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #setRepeatMode,
          [
            playerId,
            repeatMode,
          ],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  _i3.Future<int> getAndroidPerformanceClass() => (super.noSuchMethod(
        Invocation.method(
          #getAndroidPerformanceClass,
          [],
        ),
        returnValue: _i3.Future<int>.value(0),
        returnValueForMissingStub: _i3.Future<int>.value(0),
      ) as _i3.Future<int>);
}

/// A class which mocks [PlayerPluginStateNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockPlayerPluginStateNotifier extends _i1.Mock
    implements _i2.PlayerPluginStateNotifier {
  @override
  bool get keepAlive => (super.noSuchMethod(
        Invocation.getter(#keepAlive),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  set onError(_i8.ErrorListener? _onError) => super.noSuchMethod(
        Invocation.setter(
          #onError,
          _onError,
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool get mounted => (super.noSuchMethod(
        Invocation.getter(#mounted),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  _i3.Stream<_i2.PlayerPluginState> get stream => (super.noSuchMethod(
        Invocation.getter(#stream),
        returnValue: _i3.Stream<_i2.PlayerPluginState>.empty(),
        returnValueForMissingStub: _i3.Stream<_i2.PlayerPluginState>.empty(),
      ) as _i3.Stream<_i2.PlayerPluginState>);

  @override
  _i2.PlayerPluginState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakePlayerPluginState_3(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakePlayerPluginState_3(
          this,
          Invocation.getter(#state),
        ),
      ) as _i2.PlayerPluginState);

  @override
  set state(_i2.PlayerPluginState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i2.PlayerPluginState get debugState => (super.noSuchMethod(
        Invocation.getter(#debugState),
        returnValue: _FakePlayerPluginState_3(
          this,
          Invocation.getter(#debugState),
        ),
        returnValueForMissingStub: _FakePlayerPluginState_3(
          this,
          Invocation.getter(#debugState),
        ),
      ) as _i2.PlayerPluginState);

  @override
  bool get hasListeners => (super.noSuchMethod(
        Invocation.getter(#hasListeners),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  void dispose({bool? force}) => super.noSuchMethod(
        Invocation.method(
          #dispose,
          [],
          {#force: force},
        ),
        returnValueForMissingStub: null,
      );

  @override
  void setPrimaryPlayer(String? playerId) => super.noSuchMethod(
        Invocation.method(
          #setPrimaryPlayer,
          [playerId],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i2.PlayerStateNotifier? getPlayerNotifier(String? playerId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getPlayerNotifier,
          [playerId],
        ),
        returnValueForMissingStub: null,
      ) as _i2.PlayerStateNotifier?);

  @override
  _i2.PlayerStateNotifier getOrAddPlayerNotifier(String? playerId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getOrAddPlayerNotifier,
          [playerId],
        ),
        returnValue: _FakePlayerStateNotifier_4(
          this,
          Invocation.method(
            #getOrAddPlayerNotifier,
            [playerId],
          ),
        ),
        returnValueForMissingStub: _FakePlayerStateNotifier_4(
          this,
          Invocation.method(
            #getOrAddPlayerNotifier,
            [playerId],
          ),
        ),
      ) as _i2.PlayerStateNotifier);

  @override
  bool updateShouldNotify(
    _i2.PlayerPluginState? old,
    _i2.PlayerPluginState? current,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateShouldNotify,
          [
            old,
            current,
          ],
        ),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  _i8.RemoveListener addListener(
    _i8.Listener<_i2.PlayerPluginState>? listener, {
    bool? fireImmediately = true,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #addListener,
          [listener],
          {#fireImmediately: fireImmediately},
        ),
        returnValue: () {},
        returnValueForMissingStub: () {},
      ) as _i8.RemoveListener);
}

/// A class which mocks [PlayerStateNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockPlayerStateNotifier extends _i1.Mock
    implements _i2.PlayerStateNotifier {
  @override
  bool get keepAlive => (super.noSuchMethod(
        Invocation.getter(#keepAlive),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  _i3.Timer get positionUpdateTimer => (super.noSuchMethod(
        Invocation.getter(#positionUpdateTimer),
        returnValue: _FakeTimer_5(
          this,
          Invocation.getter(#positionUpdateTimer),
        ),
        returnValueForMissingStub: _FakeTimer_5(
          this,
          Invocation.getter(#positionUpdateTimer),
        ),
      ) as _i3.Timer);

  @override
  set positionUpdateTimer(_i3.Timer? _positionUpdateTimer) =>
      super.noSuchMethod(
        Invocation.setter(
          #positionUpdateTimer,
          _positionUpdateTimer,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i4.QueueManager get queueManager => (super.noSuchMethod(
        Invocation.getter(#queueManager),
        returnValue: _FakeQueueManager_6(
          this,
          Invocation.getter(#queueManager),
        ),
        returnValueForMissingStub: _FakeQueueManager_6(
          this,
          Invocation.getter(#queueManager),
        ),
      ) as _i4.QueueManager);

  @override
  set queueManager(_i4.QueueManager? _queueManager) => super.noSuchMethod(
        Invocation.setter(
          #queueManager,
          _queueManager,
        ),
        returnValueForMissingStub: null,
      );

  @override
  set onError(_i8.ErrorListener? _onError) => super.noSuchMethod(
        Invocation.setter(
          #onError,
          _onError,
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool get mounted => (super.noSuchMethod(
        Invocation.getter(#mounted),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  _i3.Stream<_i2.PlayerState> get stream => (super.noSuchMethod(
        Invocation.getter(#stream),
        returnValue: _i3.Stream<_i2.PlayerState>.empty(),
        returnValueForMissingStub: _i3.Stream<_i2.PlayerState>.empty(),
      ) as _i3.Stream<_i2.PlayerState>);

  @override
  _i2.PlayerState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakePlayerState_7(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakePlayerState_7(
          this,
          Invocation.getter(#state),
        ),
      ) as _i2.PlayerState);

  @override
  set state(_i2.PlayerState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i2.PlayerState get debugState => (super.noSuchMethod(
        Invocation.getter(#debugState),
        returnValue: _FakePlayerState_7(
          this,
          Invocation.getter(#debugState),
        ),
        returnValueForMissingStub: _FakePlayerState_7(
          this,
          Invocation.getter(#debugState),
        ),
      ) as _i2.PlayerState);

  @override
  bool get hasListeners => (super.noSuchMethod(
        Invocation.getter(#hasListeners),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  void dispose({bool? force}) => super.noSuchMethod(
        Invocation.method(
          #dispose,
          [],
          {#force: force},
        ),
        returnValueForMissingStub: null,
      );

  @override
  void resyncPlaybackPositionTimer() => super.noSuchMethod(
        Invocation.method(
          #resyncPlaybackPositionTimer,
          [],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i2.PlayerState getState() => (super.noSuchMethod(
        Invocation.method(
          #getState,
          [],
        ),
        returnValue: _FakePlayerState_7(
          this,
          Invocation.method(
            #getState,
            [],
          ),
        ),
        returnValueForMissingStub: _FakePlayerState_7(
          this,
          Invocation.method(
            #getState,
            [],
          ),
        ),
      ) as _i2.PlayerState);

  @override
  void setMediaItem(_i2.MediaItem? mediaItem) => super.noSuchMethod(
        Invocation.method(
          #setMediaItem,
          [mediaItem],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void setError(_i2.PlayerError? error) => super.noSuchMethod(
        Invocation.method(
          #setError,
          [error],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void setPlaybackState(_i2.PlaybackState? playbackState) => super.noSuchMethod(
        Invocation.method(
          #setPlaybackState,
          [playbackState],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void setPlaybackPosition(int? ms) => super.noSuchMethod(
        Invocation.method(
          #setPlaybackPosition,
          [ms],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void setIsInPipMode(bool? isInPipMode) => super.noSuchMethod(
        Invocation.method(
          #setIsInPipMode,
          [isInPipMode],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void setIsBuffering(bool? isBuffering) => super.noSuchMethod(
        Invocation.method(
          #setIsBuffering,
          [isBuffering],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void setStateFromSnapshot(_i7.PlayerStateSnapshot? snapshot) =>
      super.noSuchMethod(
        Invocation.method(
          #setStateFromSnapshot,
          [snapshot],
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool updateShouldNotify(
    _i2.PlayerState? old,
    _i2.PlayerState? current,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateShouldNotify,
          [
            old,
            current,
          ],
        ),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  _i8.RemoveListener addListener(
    _i8.Listener<_i2.PlayerState>? listener, {
    bool? fireImmediately = true,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #addListener,
          [listener],
          {#fireImmediately: fireImmediately},
        ),
        returnValue: () {},
        returnValueForMissingStub: () {},
      ) as _i8.RemoveListener);
}
