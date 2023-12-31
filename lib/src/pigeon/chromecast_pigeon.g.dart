// Autogenerated from Pigeon (v10.1.6), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name, unnecessary_import

import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';

class CastSessionUnavailableEvent {
  CastSessionUnavailableEvent({
    this.playbackPositionMs,
  });

  int? playbackPositionMs;

  Object encode() {
    return <Object?>[
      playbackPositionMs,
    ];
  }

  static CastSessionUnavailableEvent decode(Object result) {
    result as List<Object?>;
    return CastSessionUnavailableEvent(
      playbackPositionMs: result[0] as int?,
    );
  }
}

class _ChromecastPigeonCodec extends StandardMessageCodec {
  const _ChromecastPigeonCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is CastSessionUnavailableEvent) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128: 
        return CastSessionUnavailableEvent.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

/// An API called by the native side to notify about chromecast changes
abstract class ChromecastPigeon {
  static const MessageCodec<Object?> codec = _ChromecastPigeonCodec();

  void onSessionEnded();

  void onSessionEnding();

  void onSessionResumeFailed();

  void onSessionResumed();

  void onSessionResuming();

  void onSessionStartFailed();

  void onSessionStarted();

  void onSessionStarting();

  void onSessionSuspended();

  void onCastSessionAvailable();

  void onCastSessionUnavailable(CastSessionUnavailableEvent event);

  static void setup(ChromecastPigeon? api, {BinaryMessenger? binaryMessenger}) {
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.bccm_player.ChromecastPigeon.onSessionEnded', codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          // ignore message
          api.onSessionEnded();
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.bccm_player.ChromecastPigeon.onSessionEnding', codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          // ignore message
          api.onSessionEnding();
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.bccm_player.ChromecastPigeon.onSessionResumeFailed', codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          // ignore message
          api.onSessionResumeFailed();
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.bccm_player.ChromecastPigeon.onSessionResumed', codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          // ignore message
          api.onSessionResumed();
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.bccm_player.ChromecastPigeon.onSessionResuming', codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          // ignore message
          api.onSessionResuming();
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.bccm_player.ChromecastPigeon.onSessionStartFailed', codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          // ignore message
          api.onSessionStartFailed();
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.bccm_player.ChromecastPigeon.onSessionStarted', codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          // ignore message
          api.onSessionStarted();
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.bccm_player.ChromecastPigeon.onSessionStarting', codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          // ignore message
          api.onSessionStarting();
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.bccm_player.ChromecastPigeon.onSessionSuspended', codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          // ignore message
          api.onSessionSuspended();
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.bccm_player.ChromecastPigeon.onCastSessionAvailable', codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          // ignore message
          api.onCastSessionAvailable();
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.bccm_player.ChromecastPigeon.onCastSessionUnavailable', codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.bccm_player.ChromecastPigeon.onCastSessionUnavailable was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final CastSessionUnavailableEvent? arg_event = (args[0] as CastSessionUnavailableEvent?);
          assert(arg_event != null,
              'Argument for dev.flutter.pigeon.bccm_player.ChromecastPigeon.onCastSessionUnavailable was null, expected non-null CastSessionUnavailableEvent.');
          api.onCastSessionUnavailable(arg_event!);
          return;
        });
      }
    }
  }
}
