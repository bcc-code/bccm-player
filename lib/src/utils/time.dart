import 'dart:math';

/// Convert milliseconds to 'hh:mm:ss'
String getFormattedDuration(num durationMs) {
  // Player state supplies these, and AVPlayer reports NaN/infinite times before
  // a manifest loads. `toInt()` throws on those, which would take the controls
  // down, and a negative duration formats as nonsense ("00:59" for -1000ms).
  // Callers currently sanitise via safeDouble/safeInt upstream; this makes the
  // formatter total so that guard stopping being load-bearing is not a crash.
  final safeMs = durationMs.isFinite ? max(0, durationMs.toInt()) : 0;
  final duration = Duration(milliseconds: safeMs);
  return [
    if (duration.inHours != 0) duration.inHours.toString().padLeft(2, '0'),
    (duration.inMinutes % 60).toString().padLeft(2, '0'),
    (duration.inSeconds % 60).toString().padLeft(2, '0')
  ].join(':');
}

double calcTimeLeftMs({required num? duration, required num? currentMs}) {
  currentMs ??= 0;
  duration ??= 0;
  if (!duration.isFinite) duration = 0;
  if (!currentMs.isFinite) currentMs = 0;

  return max(0, (duration - currentMs).toDouble());
}
