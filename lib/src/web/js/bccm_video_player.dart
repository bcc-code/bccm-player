@JS('window.bccmVideoPlayer')
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Bindings for the `bccm-video-player` npm package, which the host page is
/// expected to load before Flutter starts (exposed as `window.bccmVideoPlayer`).
///
/// Modelled on the package's own TypeScript definitions — see
/// `build/types/video-player/index.d.ts` in the published package.
///
/// These use extension types rather than the older `@JS`/`@anonymous` classes:
/// `dart:js_interop` only accepts static interop, so the previous form no longer
/// compiles under dart2js at all.
@JS()
external JSPromise<Player> createPlayer(String containerId, Options options);

@JS()
external void setNPAWOptions(Player player, NpawOptions options);

@JS()
external void restartNPAWView(Player player, NpawOptions options);

/// The handle returned by [createPlayer].
///
/// [mediaEl] is the real `<video>` element, which is where playback control and
/// all playback events come from — the package deliberately does not wrap them.
extension type Player._(JSObject _) implements JSObject {
  external web.HTMLElement get element;
  external web.HTMLVideoElement get mediaEl;

  external JSArray<TrackOption> getAudioLanguages();
  external JSArray<TrackOption> getSubtitleLanguages();
  external void setAudioTrackToLanguage([String? language]);
  external void setSubtitleTrackToLanguage([String? language]);
  external void setVideoQuality(int height);
  external void setLanguage(String lang);
  external void dispose();
}

extension type TrackOption._(JSObject _) implements JSObject {
  external String get language;
  external String get label;
}

extension type Options._(JSObject _) implements JSObject {
  external factory Options({
    SrcOptions src,
    LanguagePreferenceDefaults languagePreferenceDefaults,
    bool autoplay,
    bool? live,
    String? language,
    VideoJsOptions? videojs,
    NpawOptions? npaw,
  });
}

extension type SrcOptions._(JSObject _) implements JSObject {
  external factory SrcOptions({String? type, String? src});
}

extension type LanguagePreferenceDefaults._(JSObject _) implements JSObject {
  external factory LanguagePreferenceDefaults({String? audio, String? subtitles});
}

extension type VideoJsOptions._(JSObject _) implements JSObject {
  external factory VideoJsOptions({String? poster, String? crossOrigin});
}

extension type NpawOptions._(JSObject _) implements JSObject {
  external factory NpawOptions({
    bool? enabled,
    String? accountCode,
    String appName,
    NpawTrackingOptions tracking,
  });
}

extension type NpawTrackingOptions._(JSObject _) implements JSObject {
  external factory NpawTrackingOptions({
    bool? isLive,
    String? userId,
    String? sessionId,
    String? ageGroup,
    NpawMetadataOptions metadata,
  });
}

extension type NpawMetadataOptions._(JSObject _) implements JSObject {
  external factory NpawMetadataOptions({
    String? contentId,
    String? title,
    String? episodeTitle,
    String? seasonTitle,
    String? seasonId,
    String? showTitle,
    String? showId,
    // A plain Dart Map is not a valid interop type; callers pass `map.jsify()`.
    JSObject? overrides,
  });
}
