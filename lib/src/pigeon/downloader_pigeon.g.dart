// Autogenerated from Pigeon (v10.1.6), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name, unnecessary_import

import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';

class DownloadConfig {
  DownloadConfig({
    required this.url,
    required this.mimeType,
    required this.title,
    required this.audioTrackIds,
    required this.videoTrackIds,
    required this.additionalData,
  });

  String url;

  String mimeType;

  String title;

  List<String?> audioTrackIds;

  List<String?> videoTrackIds;

  Map<String?, String?> additionalData;

  Object encode() {
    return <Object?>[
      url,
      mimeType,
      title,
      audioTrackIds,
      videoTrackIds,
      additionalData,
    ];
  }

  static DownloadConfig decode(Object result) {
    result as List<Object?>;
    return DownloadConfig(
      url: result[0]! as String,
      mimeType: result[1]! as String,
      title: result[2]! as String,
      audioTrackIds: (result[3] as List<Object?>?)!.cast<String?>(),
      videoTrackIds: (result[4] as List<Object?>?)!.cast<String?>(),
      additionalData: (result[5] as Map<Object?, Object?>?)!.cast<String?, String?>(),
    );
  }
}

class Download {
  Download({
    required this.key,
    required this.config,
    this.offlineUrl,
    required this.isFinished,
  });

  String key;

  DownloadConfig config;

  String? offlineUrl;

  bool isFinished;

  Object encode() {
    return <Object?>[
      key,
      config.encode(),
      offlineUrl,
      isFinished,
    ];
  }

  static Download decode(Object result) {
    result as List<Object?>;
    return Download(
      key: result[0]! as String,
      config: DownloadConfig.decode(result[1]! as List<Object?>),
      offlineUrl: result[2] as String?,
      isFinished: result[3]! as bool,
    );
  }
}

class DownloadStatusChangedEvent {
  DownloadStatusChangedEvent({
    required this.download,
    required this.progress,
  });

  Download download;

  double progress;

  Object encode() {
    return <Object?>[
      download.encode(),
      progress,
    ];
  }

  static DownloadStatusChangedEvent decode(Object result) {
    result as List<Object?>;
    return DownloadStatusChangedEvent(
      download: Download.decode(result[0]! as List<Object?>),
      progress: result[1]! as double,
    );
  }
}

class _DownloaderPigeonCodec extends StandardMessageCodec {
  const _DownloaderPigeonCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is Download) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is Download) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else if (value is DownloadConfig) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128: 
        return Download.decode(readValue(buffer)!);
      case 129: 
        return Download.decode(readValue(buffer)!);
      case 130: 
        return DownloadConfig.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

/// An API called by the native side to notify about chromecast changes
class DownloaderPigeon {
  /// Constructor for [DownloaderPigeon].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  DownloaderPigeon({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _DownloaderPigeonCodec();

  Future<Download> startDownload(DownloadConfig arg_downloadConfig) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.bccm_player.DownloaderPigeon.startDownload', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_downloadConfig]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as Download?)!;
    }
  }

  Future<double> getDownloadStatus(String arg_downloadKey) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.bccm_player.DownloaderPigeon.getDownloadStatus', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_downloadKey]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as double?)!;
    }
  }

  Future<List<Download?>> getDownloads() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.bccm_player.DownloaderPigeon.getDownloads', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as List<Object?>?)!.cast<Download?>();
    }
  }

  Future<Download?> getDownload(String arg_downloadKey) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.bccm_player.DownloaderPigeon.getDownload', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_downloadKey]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return (replyList[0] as Download?);
    }
  }

  Future<void> removeDownload(String arg_downloadKey) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.bccm_player.DownloaderPigeon.removeDownload', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_downloadKey]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }
}

class _DownloaderListenerPigeonCodec extends StandardMessageCodec {
  const _DownloaderListenerPigeonCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is Download) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is DownloadConfig) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else if (value is DownloadStatusChangedEvent) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128: 
        return Download.decode(readValue(buffer)!);
      case 129: 
        return DownloadConfig.decode(readValue(buffer)!);
      case 130: 
        return DownloadStatusChangedEvent.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

abstract class DownloaderListenerPigeon {
  static const MessageCodec<Object?> codec = _DownloaderListenerPigeonCodec();

  void onDownloadStatusChanged(DownloadStatusChangedEvent event);

  static void setup(DownloaderListenerPigeon? api, {BinaryMessenger? binaryMessenger}) {
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.bccm_player.DownloaderListenerPigeon.onDownloadStatusChanged', codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.bccm_player.DownloaderListenerPigeon.onDownloadStatusChanged was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final DownloadStatusChangedEvent? arg_event = (args[0] as DownloadStatusChangedEvent?);
          assert(arg_event != null,
              'Argument for dev.flutter.pigeon.bccm_player.DownloaderListenerPigeon.onDownloadStatusChanged was null, expected non-null DownloadStatusChangedEvent.');
          api.onDownloadStatusChanged(arg_event!);
          return;
        });
      }
    }
  }
}