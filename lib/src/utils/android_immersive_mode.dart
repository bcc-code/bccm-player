import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hides/shows the Android system bars natively, via `WindowInsetsControllerCompat`.
///
/// [SystemChrome.setEnabledSystemUIMode] cannot do this any more: the Flutter engine implements
/// `SystemUiMode.leanBack`, `immersive` and `immersiveSticky` with the legacy
/// `View.setSystemUiVisibility` flags, and Android ignores those for apps targeting SDK 36.
/// The engine says so itself in `PlatformPlugin.java`:
///
/// > If the Flutter Android app targets Android SDK 16 (API 36) or later, then the Android system
/// > will ignore this value.
///
/// `SystemUiMode.manual` with `overlays: []` goes through the same ignored path, so hiding the bars
/// at target 36 has to happen on the native side.
///
/// Calls are reference counted natively, so [enter] and [exit] must be paired.
/// No-ops on every platform except Android.
class AndroidImmersiveMode {
  const AndroidImmersiveMode._();

  static const _channel = MethodChannel('bccm_player/system_ui');

  static bool get _isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Hides the system bars, with swipe-to-reveal transient bars that auto-hide again.
  static Future<void> enter() => _invoke('enterImmersive');

  /// Releases one [enter], restoring the bar visibility from before the outermost call.
  static Future<void> exit() => _invoke('exitImmersive');

  static Future<void> _invoke(String method) async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Native side is older than this Dart code — fullscreen must not break because of it.
      debugPrint('bccm: $method not available on the native side, ignoring.');
    } on PlatformException catch (e) {
      debugPrint('bccm: $method failed: ${e.message}');
    }
  }
}
