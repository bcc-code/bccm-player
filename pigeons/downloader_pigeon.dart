import 'package:pigeon/pigeon.dart';

// IMPORTANT INFORMATION
// This is a template pigeon file,
// After doing edits to this file you have to run pigeon to generate downloader_pigeon.g.dart:
//
// ```sh
// dart run pigeon --input pigeons/downloader_pigeon.dart
// ```
//
// See the "Contributing" docs for bccm_player for more info.

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/pigeon/downloader_pigeon.g.dart',
  dartOptions: DartOptions(),
  javaOut: 'android/src/main/java/media/bcc/bccm_player/pigeon/DownloaderApi.java',
  javaOptions: JavaOptions(package: 'media.bcc.bccm_player.pigeon'),
  swiftOut: 'ios/Classes/Pigeon/DownloaderApi.swift',
))

/// An API called by the native side to notify about chromecast changes
@HostApi()
abstract class DownloaderPigeon {
  @async
  @ObjCSelector("startDownload:")
  Download startDownload(DownloadConfig downloadConfig);

  @async
  @ObjCSelector("getDownloadStatus:")
  double getDownloadStatus(String downloadKey);

  @async
  @ObjCSelector("getDownloads")
  List<Download> getDownloads();

  @async
  @ObjCSelector("getDownload:")
  Download? getDownload(String downloadKey);

  @async
  @ObjCSelector("removeDownload:")
  void removeDownload(String downloadKey);

  /// Returns free space in bytes
  @async
  @ObjCSelector("getFreeDiskSpace")
  double getFreeDiskSpace();
}

class DownloadConfig {
  late String url;
  late String mimeType;
  late String title;
  late List<String?> audioTrackIds;
  late List<String?> videoTrackIds;
  // We store the metadata as string (json), so that we don't have to implement serialization and deserialization on both Android and iOS.
  late Map<String?, String?> additionalData;
}

enum DownloadStatus {
  downloading,
  paused,
  finished,
  failed,
  queued,
  removing,
}

class Download {
  late String key;
  late DownloadConfig config;
  late String? offlineUrl;
  late double fractionDownloaded;
  late DownloadStatus status;
  late String? error;
}

@FlutterApi()
abstract class DownloaderListenerPigeon {
  @ObjCSelector("onDownloadStatusChanged:")
  void onDownloadStatusChanged(DownloadChangedEvent event);
  @ObjCSelector("onDownloadRemoved:")
  void onDownloadRemoved(DownloadRemovedEvent event);
  @ObjCSelector("onDownloadFailed:")
  void onDownloadFailed(DownloadFailedEvent event);
}

class DownloadFailedEvent {
  late String key;
  late String? error;
}

class DownloadRemovedEvent {
  late String key;
}

class DownloadChangedEvent {
  late Download download;
}
