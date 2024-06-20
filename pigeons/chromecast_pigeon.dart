import 'package:pigeon/pigeon.dart';

// IMPORTANT INFORMATION
// This is a template pigeon file,
// After doing edits to this file you have to run pigeon to generate playback_platform_pigeon.g.dart:
//
// ```sh
// dart run pigeon --input pigeons/chromecast_pigeon.dart
// ```
//
// See the "Contributing" docs for bccm_player for more info.

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/pigeon/chromecast_pigeon.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/media/bcc/bccm_player/pigeon/ChromecastControllerPigeon.kt',
  kotlinOptions: KotlinOptions(package: 'media.bcc.bccm_player.pigeon.chromecast'),
  objcHeaderOut: 'ios/Classes/Pigeon/ChromecastPigeon.h',
  objcSourceOut: 'ios/Classes/Pigeon/ChromecastPigeon.m',
  objcOptions: ObjcOptions(),
))

/// An API called by the native side to notify about chromecast changes
@FlutterApi()
abstract class ChromecastPigeon {
  @ObjCSelector("onSessionEnded")
  void onSessionEnded();

  @ObjCSelector("onSessionEnding")
  void onSessionEnding();

  @ObjCSelector("onSessionResumeFailed")
  void onSessionResumeFailed();

  @ObjCSelector("onSessionResumed")
  void onSessionResumed();

  @ObjCSelector("onSessionResuming")
  void onSessionResuming();

  @ObjCSelector("onSessionStartFailed")
  void onSessionStartFailed();

  @ObjCSelector("onSessionStarted")
  void onSessionStarted();

  @ObjCSelector("onSessionStarting")
  void onSessionStarting();

  @ObjCSelector("onSessionSuspended")
  void onSessionSuspended();

  @ObjCSelector("onCastSessionAvailable")
  void onCastSessionAvailable();

  @ObjCSelector("onCastSessionUnavailable:")
  void onCastSessionUnavailable(CastSessionUnavailableEvent event);
}

class CastSessionUnavailableEvent {
  int? playbackPositionMs;
}
