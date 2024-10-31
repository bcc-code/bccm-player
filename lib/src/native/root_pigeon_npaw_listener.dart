import 'dart:async';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';

class RootPigeonNpawListener extends NpawListenerPigeon {
  RootPigeonNpawListener();

  final List<NpawListenerPigeon> _listeners = [];
  final StreamController<Object?> _streamController = StreamController.broadcast();

  Stream<Object?> get stream => _streamController.stream;

  void addListener(listener) {
    _listeners.add(listener);
  }

  void removeListener(listener) {
    _listeners.remove(listener);
  }

  @override
  void onVideoPause(NpawVideoPauseEvent event) {
    _streamController.add(event);
    for (var listener in _listeners) {
      listener.onVideoPause(event);
    }
  }

  @override
  void onVideoPing(NpawVideoPingEvent event) {
    _streamController.add(event);
    for (var listener in _listeners) {
      listener.onVideoPing(event);
    }
  }

  @override
  void onVideoResume(NpawVideoResumeEvent event) {
    _streamController.add(event);
    for (var listener in _listeners) {
      listener.onVideoResume(event);
    }
  }

  @override
  void onVideoSeek(NpawVideoSeekEvent event) {
    _streamController.add(event);
    for (var listener in _listeners) {
      listener.onVideoSeek(event);
    }
  }

  @override
  void onVideoStart(NpawVideoStartEvent event) {
    _streamController.add(event);
    for (var listener in _listeners) {
      listener.onVideoStart(event);
    }
  }

  @override
  void onVideoStop(NpawVideoStopEvent event) {
    _streamController.add(event);
    for (var listener in _listeners) {
      listener.onVideoStop(event);
    }
  }
}
