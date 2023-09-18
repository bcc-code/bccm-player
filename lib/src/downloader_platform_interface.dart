import 'dart:async';
import 'package:bccm_player/src/pigeon/downloader_pigeon.g.dart';
import 'package:collection/collection.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class DownloaderListener implements DownloaderListenerPigeon {
  final StreamController<DownloadChangedEvent> _statusChangedStreamController = StreamController.broadcast();
  final StreamController<DownloadFailedEvent> _downloadFailedStreamController = StreamController.broadcast();
  final StreamController<DownloadRemovedEvent> _downloadRemovedStreamController = StreamController.broadcast();

  Stream<DownloadChangedEvent> get statusChanged => _statusChangedStreamController.stream;
  Stream<DownloadFailedEvent> get downloadFailed => _downloadFailedStreamController.stream;
  Stream<DownloadRemovedEvent> get downloadRemoved => _downloadRemovedStreamController.stream;

  @override
  void onDownloadStatusChanged(DownloadChangedEvent event) {
    print("onDownloadStatusChanged, ${event.encode()}");
    _statusChangedStreamController.add(event);
  }

  @override
  void onDownloadFailed(DownloadFailedEvent event) {
    print("onDownloadFailed, ${event.encode()}");
    _downloadFailedStreamController.add(event);
  }

  @override
  void onDownloadRemoved(DownloadRemovedEvent event) {
    print("onDownloadRemoved, ${event.encode()}");
    _downloadRemovedStreamController.add(event);
  }
}

class DownloaderNative extends DownloaderInterface {
  final DownloaderPigeon _pigeon = DownloaderPigeon();
  final DownloaderListener _listener = DownloaderListener();

  DownloaderNative() {
    DownloaderListenerPigeon.setup(_listener);
  }

  @override
  DownloaderListener get events => _listener;

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

  DownloaderListener get events;

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
