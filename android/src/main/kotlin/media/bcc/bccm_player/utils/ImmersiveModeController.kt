package media.bcc.bccm_player.utils

import android.app.Activity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import java.lang.ref.WeakReference

/**
 * Hides/shows the system bars using [WindowInsetsControllerCompat].
 *
 * This exists because the legacy `View.setSystemUiVisibility` flags — and therefore Flutter's
 * `SystemUiMode.leanBack`/`immersive`/`immersiveSticky` — are ignored by the system for apps
 * targeting SDK 36. See the engine's own note in `PlatformPlugin.java`:
 *
 * > If the Flutter Android app targets Android SDK 16 (API 36) or later, then the Android system
 * > will ignore this value.
 *
 * [WindowInsetsControllerCompat] is unaffected by edge-to-edge enforcement, so it is the only
 * supported way to hide the bars at target 36. Below API 30 the compat class falls back to the
 * legacy flags, which are still honoured on those devices regardless of `targetSdk`.
 *
 * Callers may nest (a native PiP overlay can be opened from inside the Flutter fullscreen route),
 * so [enter]/[exit] are reference counted and the bar visibility present before the outermost
 * [enter] is what [exit] restores.
 */
object ImmersiveModeController {
    private var activityRef: WeakReference<Activity>? = null
    private var depth = 0
    private var barsWereVisible = true

    /** Hides the system bars. Reference counted — pair every call with [exit]. */
    fun enter(activity: Activity) {
        if (activityRef?.get() !== activity) {
            // Different (or recreated) activity: previous state is meaningless.
            activityRef = WeakReference(activity)
            depth = 0
        }
        if (depth == 0) {
            barsWereVisible = ViewCompat.getRootWindowInsets(activity.window.decorView)
                ?.isVisible(WindowInsetsCompat.Type.systemBars()) ?: true
        }
        depth++
        apply(activity)
    }

    /** Releases one [enter]; restores the pre-entry bar visibility once the last one is released. */
    fun exit(activity: Activity) {
        if (activityRef?.get() !== activity) return
        if (depth == 0) return
        depth--
        if (depth == 0 && barsWereVisible) {
            controllerFor(activity).show(WindowInsetsCompat.Type.systemBars())
        }
    }

    /**
     * Re-hides the bars if immersive mode is still active.
     *
     * The system reveals the bars again on focus loss/regain — PiP transitions, permission
     * dialogs, the notification shade, Cast dialogs — so this needs calling when focus returns.
     * Flutter itself will not fight it: in edge-to-edge the engine's `updateSystemUiOverlays()`
     * only re-applies `setDecorFitsSystemWindows(false)` and never calls `show(systemBars())`.
     */
    fun reapply(activity: Activity) {
        if (activityRef?.get() !== activity || depth == 0) return
        apply(activity)
    }

    fun isActive(activity: Activity): Boolean = activityRef?.get() === activity && depth > 0

    private fun apply(activity: Activity) {
        controllerFor(activity).apply {
            // Must be set before hide(), and every time: BEHAVIOR_DEFAULT reveals the bars
            // permanently on the first touch, which is the bar-reappearance bug this code
            // previously worked around by using the (now ignored) legacy flags. Only
            // BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE reproduces sticky-immersive semantics.
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            hide(WindowInsetsCompat.Type.systemBars())
        }
    }

    /**
     * Always resolve the controller from the window + decor view. Below API 30 the compat
     * implementation writes the legacy flags through whichever view it is given, so obtaining it
     * from a child view in one place and the decor view in another desynchronises the state.
     */
    private fun controllerFor(activity: Activity): WindowInsetsControllerCompat =
        WindowCompat.getInsetsController(activity.window, activity.window.decorView)
}
