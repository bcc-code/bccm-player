import 'package:pigeon/pigeon.dart';

// IMPORTANT INFORMATION
// This is a template pigeon file,
// After doing edits to this file you have to run pigeon to generate playback_platform_pigeon.g.dart:
//
// ```sh
// dart run pigeon --input pigeons/playback_platform_pigeon.dart
// ```
//
// See the "Contributing" docs for bccm_player for more info.

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/pigeon/playback_platform_pigeon.g.dart',
  dartOptions: DartOptions(),
  javaOut: 'android/src/main/java/media/bcc/bccm_player/pigeon/PlaybackPlatformApi.java',
  javaOptions: JavaOptions(package: 'media.bcc.bccm_player.pigeon'),
  objcHeaderOut: 'ios/Classes/Pigeon/PlaybackPlatformApi.h',
  objcSourceOut: 'ios/Classes/Pigeon/PlaybackPlatformApi.m',
  objcOptions: ObjcOptions(),
))

/// The main interface, used by the flutter side to control the player.
@HostApi()
abstract class PlaybackPlatformPigeon {
  @async
  void attach();

  @async
  @ObjCSelector("newPlayer:disableNpaw:")
  String newPlayer(BufferMode? bufferMode, bool? disableNpaw);

  @async
  @ObjCSelector("createVideoTexture")
  int createVideoTexture();

  @async
  @ObjCSelector("disposeVideoTexture:")
  bool disposeVideoTexture(int textureId);

  @async
  @ObjCSelector("switchToVideoTextureForPlayer:textureId:")
  int switchToVideoTexture(String playerId, int textureId);

  @async
  @ObjCSelector("disposePlayer:")
  bool disposePlayer(String playerId);

  @async
  @ObjCSelector("replaceCurrentMediaItem:mediaItem:playbackPositionFromPrimary:autoplay:")
  void replaceCurrentMediaItem(String playerId, MediaItem mediaItem, bool? playbackPositionFromPrimary, bool? autoplay);

  @ObjCSelector("setPlayerViewVisibility:visible:")
  void setPlayerViewVisibility(int viewId, bool visible);

  @async
  @ObjCSelector("setPrimary:")
  void setPrimary(String id);

  @ObjCSelector("play:")
  void play(String playerId);

  @async
  @ObjCSelector("seek:positionMs:")
  void seekTo(String playerId, double positionMs);

  @async
  @ObjCSelector("seekToLive:")
  void seekToLive(String playerId);

  @ObjCSelector("pause:")
  void pause(String playerId);

  @ObjCSelector("stop:reset:")
  void stop(String playerId, bool reset);

  @async
  @ObjCSelector("setVolume:volume:")
  void setVolume(String playerId, double volume);

  @async
  @ObjCSelector("setRepeatMode:repeatMode:")
  void setRepeatMode(String playerId, RepeatMode repeatMode);

  @async
  @ObjCSelector("setSelectedTrack:type:trackId:")
  void setSelectedTrack(String playerId, TrackType type, String? trackId);

  @async
  @ObjCSelector("setPlaybackSpeed:speed:")
  void setPlaybackSpeed(String playerId, double speed);

  @ObjCSelector("exitFullscreen:")
  void exitFullscreen(String playerId);

  @ObjCSelector("enterFullscreen:")
  void enterFullscreen(String playerId);

  @async
  @ObjCSelector("setMixWithOthers:mixWithOthers:")
  void setMixWithOthers(String playerId, bool mixWithOthers);

  @ObjCSelector("setNpawConfig:")
  void setNpawConfig(NpawConfig? config);

  /// Ends the current NPAW view and starts a fresh one for [playerId]. When
  /// [metadata] is provided, its `npaw.content.*` extras define the new view's
  /// content (id/saga/transactionCode/...); otherwise the current item is reused.
  /// Used to split a continuous live stream into one NPAW view per program,
  /// without replacing the media item.
  @ObjCSelector("startNpawView:metadata:")
  void startNpawView(String playerId, MediaMetadata? metadata);

  @ObjCSelector("setAppConfig:")
  void setAppConfig(AppConfig? config);

  @async
  @ObjCSelector("getTracks:")
  PlayerTracksSnapshot? getTracks(String? playerId);

  @async
  @ObjCSelector("getPlayerState:")
  PlayerStateSnapshot? getPlayerState(String? playerId);

  @async
  @ObjCSelector("getChromecastState")
  ChromecastState? getChromecastState();

  @ObjCSelector("openExpandedCastController")
  void openExpandedCastController();

  @ObjCSelector("openCastDialog")
  void openCastDialog();

  @async
  @ObjCSelector("fetchMediaInfo:mimeType:")
  MediaInfo fetchMediaInfo(String url, String? mimeType);

  @async
  int getAndroidPerformanceClass();
}

enum BufferMode {
  standard,
  fastStartShortForm,
}

enum RepeatMode {
  off,
  one,
}

enum DrmType {
  widevine,
  fairplay,
}

class NpawConfig {
  late String? appName;
  late String? appReleaseVersion;
  late String? accountCode;
  late bool? deviceIsAnonymous;
}

class AppConfig {
  late String? appLanguage;
  late List<String?> audioLanguages;
  late List<String?> subtitleLanguages;
  late String? analyticsId;
  late String? sessionId;
}

class User {
  late String? id;
}

class SetUrlArgs {
  late String playerId;
  late String url;
  bool? isLive;
}

class DrmConfiguration {
  late DrmType drmType;
  String? contentKeyId;
  String? fpsCertificateUrl;
  late String licenseServerUrl;
  Map<String?, String?>? licenseRequestHeaders;
}

class CastMedia {
  late String url;
  Map<String?, String?>? customData;
}

class MediaItem {
  String? id;
  String? url;
  String? mimeType;
  MediaMetadata? metadata;
  bool? isLive;
  bool? isOffline;
  double? playbackStartPositionMs;
  String? lastKnownAudioLanguage;
  String? lastKnownSubtitleLanguage;
  DrmConfiguration? drmConfiguration;
  CastMedia? castMedia;
}

class MediaMetadata {
  String? artworkUri;
  String? title;
  String? artist;
  double? durationMs;
  Map<String?, String?>? extras;
}

class PlayerStateSnapshot {
  late String playerId;
  late PlaybackState playbackState;
  late bool isBuffering;
  late bool isFullscreen;
  late double playbackSpeed;
  VideoSize? videoSize;
  MediaItem? currentMediaItem;
  // This is double because pigeon uses NSNumber for int :(
  double? playbackPositionMs;
  int? textureId;
  double? volume;
  PlayerError? error;
  // Start of the player's seekable range (DVR window start for live).
  // Null for non-seekable / pre-roll states.
  double? seekableRangeStartMs;
  // End of the player's seekable range — equals the live edge for live
  // streams. Null for non-seekable / pre-roll states.
  double? seekableRangeEndMs;
}

class PlayerError {
  late String? code;
  late String? message;
}

class VideoSize {
  late int width;
  late int height;
}

enum PlaybackState { stopped, paused, playing }

class ChromecastState {
  late CastConnectionState connectionState;
  MediaItem? mediaItem;
}

enum CastConnectionState {
  // ignore: unused_field
  none,
  noDevicesAvailable,
  notConnected,
  connecting,
  connected,
}

enum TrackType { audio, text, video }

class MediaInfo {
  late List<Track?> audioTracks;
  late List<Track?> textTracks;
  late List<Track?> videoTracks;
}

class PlayerTracksSnapshot {
  late String playerId;
  late List<Track?> audioTracks;
  late List<Track?> textTracks;
  late List<Track?> videoTracks;
}

class Track {
  late String id;
  late String? label;
  late String? language;
  late double? frameRate;
  late int? bitrate;
  late int? width;
  late int? height;
  late bool? downloaded;
  late bool isSelected;
}

@FlutterApi()
abstract class QueueManagerPigeon {
  @async
  @ObjCSelector("handlePlaybackEnded:mediaItem:")
  void handlePlaybackEnded(String playerId, MediaItem? current);

  @async
  @ObjCSelector("skipToNext:")
  void skipToNext(String playerId);

  @async
  @ObjCSelector("skipToPrevious:")
  void skipToPrevious(String playerId);
}

////////////////// Playback Listener

@FlutterApi()
abstract class PlaybackListenerPigeon {
  @ObjCSelector("onPrimaryPlayerChanged:")
  void onPrimaryPlayerChanged(PrimaryPlayerChangedEvent event);
  @ObjCSelector("onPositionDiscontinuity:")
  void onPositionDiscontinuity(PositionDiscontinuityEvent event);
  @ObjCSelector("onPlayerStateUpdate:")
  void onPlayerStateUpdate(PlayerStateUpdateEvent event);
  @ObjCSelector("onPlaybackStateChanged:")
  void onPlaybackStateChanged(PlaybackStateChangedEvent event);
  @ObjCSelector("onPlaybackEnded:")
  void onPlaybackEnded(PlaybackEndedEvent event);
  @ObjCSelector("onMediaItemTransition:")
  void onMediaItemTransition(MediaItemTransitionEvent event);
  @ObjCSelector("onPictureInPictureModeChanged:")
  void onPictureInPictureModeChanged(PictureInPictureModeChangedEvent event);
}

class PrimaryPlayerChangedEvent {
  late String? playerId;
}

// All event classes carry a `playerId`. Originally these were modelled
// with an `abstract class PlayerEvent { late String playerId; }` base
// + `implements PlayerEvent`, but pigeon 22.7.4 emits `extends
// PlayerEvent` in the generated Dart while not generating the abstract
// base, producing dangling references. Flattened to standalone classes
// to dodge the codegen bug.
class PlayerStateUpdateEvent {
  late String playerId;
  late PlayerStateSnapshot snapshot;
}

class PositionDiscontinuityEvent {
  late String playerId;
  double? playbackPositionMs;
}

class PlaybackStateChangedEvent {
  String playerId;
  PlaybackState playbackState;
  bool isBuffering;
  PlaybackStateChangedEvent({required this.playerId, required this.playbackState, required this.isBuffering});
}

class PlaybackEndedEvent {
  String playerId;
  MediaItem? mediaItem;
  PlaybackEndedEvent({required this.playerId, required this.mediaItem});
}

class PictureInPictureModeChangedEvent {
  String playerId;
  bool isInPipMode;
  PictureInPictureModeChangedEvent({required this.playerId, required this.isInPipMode});
}

class MediaItemTransitionEvent {
  String playerId;
  MediaItem? mediaItem;
  MediaItemTransitionEvent({required this.playerId, this.mediaItem});
}
