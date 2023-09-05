import 'dart:async';
import 'dart:convert';

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/pigeon/downloader_pigeon.g.dart';
import 'package:collection/collection.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class DownloaderListener implements DownloaderListenerPigeon {
  final StreamController<DownloadStatusChangedEvent> _streamController = StreamController.broadcast();

  Stream<DownloadStatusChangedEvent> get stream => _streamController.stream;

  @override
  void onDownloadStatusChanged(DownloadStatusChangedEvent event) {
    _streamController.add(event);
  }
}

class DownloaderNative extends DownloaderInterface {
  final DownloaderPigeon _pigeon = DownloaderPigeon();
  final DownloaderListener _listener = DownloaderListener();

  DownloaderNative() {
    DownloaderListenerPigeon.setup(_listener);
  }

  @override
  Stream<DownloadStatusChangedEvent> get downloadStatusEvents => _listener.stream;

  @override
  Future<Download> startDownload(DownloadConfig config) async {
    return await _pigeon.startDownload(config);
  }

  @override
  Future<Download?> getDownload(String downloadKey) async {
    return await _pigeon.getDownload(downloadKey);
  }

  @override
  Future<double> getDownloadStatus(String downloadKey) async {
    return await _pigeon.getDownloadStatus(downloadKey);
  }

  @override
  Future<List<Download>> getDownloads() async {
    return (await _pigeon.getDownloads()).whereNotNull().toList();
  }

  @override
  Future<void> removeDownload(String downloadKey) async {
    await _pigeon.removeDownload(downloadKey);
  }
}

abstract class DownloaderInterface extends PlatformInterface {
  DownloaderInterface() : super(token: _token);

  static final Object _token = Object();

  static DownloaderInterface _instance = DownloaderNative();
  static DownloaderInterface get instance => _instance;

  static set instance(DownloaderInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<DownloadStatusChangedEvent> get downloadStatusEvents;

  /// Gets information about tracks (minimum), potentionally drm stuff later, etc.
  // Future<MediaInfo> getMediaInfo({required String url});

  /// Starts the download, returns a key to check status.
  Future<Download> startDownload(DownloadConfig config);

  /// get download progress as double from 0 to 1.
  Future<double> getDownloadStatus(String downloadKey);

  /// get all downloaded media
  Future<List<Download>> getDownloads();

  /// get the downloaded media (with url and any additionalData)
  Future<Download?> getDownload(String downloadKey);

  /// removes
  Future<void> removeDownload(String downloadKey);
}
