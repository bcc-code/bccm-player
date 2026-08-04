package media.bcc.bccm_player.views

import android.app.Activity
import android.app.PictureInPictureParams
import android.content.pm.ActivityInfo
import android.os.Build
import android.util.Log
import android.util.Rational
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageButton
import android.widget.LinearLayout
import androidx.annotation.OptIn
import androidx.annotation.RequiresApi
import androidx.core.view.WindowCompat
import androidx.lifecycle.Lifecycle
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.PlayerView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.filterIsInstance
import kotlinx.coroutines.launch
import media.bcc.bccm_player.BccmPlayerPluginSingleton
import media.bcc.bccm_player.PictureInPictureModeChangedEvent
import media.bcc.bccm_player.R
import media.bcc.bccm_player.players.exoplayer.BccmPlayerViewController
import media.bcc.bccm_player.players.exoplayer.ExoPlayerController
import media.bcc.bccm_player.utils.ImmersiveModeController
import media.bcc.bccm_player.utils.SwipeTouchListener

class FullscreenPlayerView @OptIn(UnstableApi::class) constructor
    (
    val activity: Activity,
    val playerController: ExoPlayerController,
    forceLandscape: Boolean = true,
    pipOnLeave: Boolean = true,
) : LinearLayout(activity), BccmPlayerViewController {
    var playerView: PlayerView?
    val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    var isInPip: Boolean = false
    val orientationBeforeGoingFullscreen = activity.requestedOrientation
    var onExitListener: (() -> Unit)? = null
    var exitAfterPictureInPicture: Boolean = false
    private var hasExited = false
    override val isFullscreen = true
    override val shouldPipAutomatically = pipOnLeave

    init {
        makeActivityFullscreen(forceLandscape)
        LayoutInflater.from(context).inflate(R.layout.player_fullscreen_view, this, true)
        playerView = this.findViewById<PlayerView>(R.id.brunstad_player)
        playerView?.let {
            playerController.takeOwnership(it, this)
        }

        playerView?.videoSurfaceView?.setOnTouchListener(
            SwipeTouchListener(
                activity.window.decorView.height * 0.3,
                object : SwipeTouchListener.Listener {
                    override fun onTopToBottomSwipe() {
                        exit()
                    }
                })
        )

        playerView?.setFullscreenButtonClickListener {
            playerController.player.pause()
            exit()
        }

        val exitButton = findViewById<ImageButton>(R.id.bccm_exit)
        exitButton.setOnClickListener {
            playerController.player.pause()
            exit()
        }
        exitButton.visibility = View.VISIBLE

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val pipButton = findViewById<ImageButton>(R.id.pip_button)
            pipButton.visibility = View.VISIBLE
            pipButton.setOnClickListener {
                enterPictureInPicture()
            }
        }

        // Live ui
        setLiveUIEnabled(playerController.isLive)
        playerController.player.addListener(object : Player.Listener {
            private lateinit var player: Player
            override fun onEvents(player: Player, events: Player.Events) {
                this.player = player
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                Log.d("bccm", "fullscreenplayer playerView?.keepScreenOn = $isPlaying")
                playerView?.keepScreenOn = isPlaying
            }

            override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
                setLiveUIEnabled(playerController.isLive)
            }

            override fun onPlaybackStateChanged(playbackState: Int) {
                setLiveUIEnabled(playerController.isLive)
                val playerView = this@FullscreenPlayerView.playerView
                playerView?.setShowNextButton(false)
                playerView?.setShowPreviousButton(false)
            }
        })

        mainScope.launch {
            BccmPlayerPluginSingleton.eventBus.filterIsInstance<PictureInPictureModeChangedEvent>()
                .collect { event ->
                    isInPip = event.isInPictureInPictureMode
                    Log.d("bccm", "PictureInPictureModeChangedEvent2, isInPiP: $isInPip")

                    if (event.lifecycleState == Lifecycle.State.CREATED) {
                        playerController.player.pause()
                    }
                    if (!event.isInPictureInPictureMode) {
                        if (exitAfterPictureInPicture) {
                            exit();
                            return@collect
                        }
                        delay(500)
                        makeActivityFullscreen(true)
                    }
                }
        }
    }

    @UnstableApi
    override fun onOwnershipLost() {
        exit()
    }

    @UnstableApi
    override fun exitFullscreen() {
        exit()
    }

    private fun makeActivityFullscreen(forceLandscape: Boolean) {
        if (forceLandscape) {
            // Ignored on displays with smallest width >= 600dp when targeting SDK 36.
            activity.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_USER_LANDSCAPE
        }
        /* No-op when targeting SDK 35+ (edge-to-edge is mandatory there), but still required on
           devices running API < 35 so this overlay draws behind the system bars. */
        WindowCompat.setDecorFitsSystemWindows(activity.window, false)
        /* The legacy SYSTEM_UI_FLAG_IMMERSIVE_STICKY flags this used to set are ignored by the
           system when targeting SDK 36, so bar hiding goes through WindowInsetsControllerCompat.
           ImmersiveModeController sets BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE, which is what
           reproduces sticky-immersive semantics and avoids the bar-reappearance bug that
           motivated the old deprecated-API workaround. */
        if (ImmersiveModeController.isActive(activity)) {
            ImmersiveModeController.reapply(activity)
        } else {
            ImmersiveModeController.enter(activity)
        }
    }

    @UnstableApi
    fun exit() {
        if (hasExited) return
        hasExited = true
        activity.requestedOrientation = orientationBeforeGoingFullscreen;
        /* No-op when targeting SDK 35+, but kept for symmetry with makeActivityFullscreen so
           layout behaviour is unchanged on devices running API < 35. */
        WindowCompat.setDecorFitsSystemWindows(activity.window, true)
        // Restores whatever bar visibility was in effect before this overlay appeared, so a PiP
        // overlay opened from inside the Flutter fullscreen route no longer reveals the bars.
        ImmersiveModeController.exit(activity)
        onExitListener?.let { listener -> listener() }
        release();
    }

    override fun onWindowFocusChanged(hasWindowFocus: Boolean) {
        super.onWindowFocusChanged(hasWindowFocus)
        // The system reveals the bars again across focus changes (PiP transitions, dialogs, the
        // notification shade), so re-assert immersive mode whenever focus comes back.
        if (hasWindowFocus) {
            ImmersiveModeController.reapply(activity)
        }
    }

    @UnstableApi
    fun setLiveUIEnabled(enabled: Boolean) {
        val playerView = playerView ?: return
        if (enabled) {
            playerView.setShowFastForwardButton(false)
            playerView.setShowRewindButton(false)
            playerView.setShowMultiWindowTimeBar(false)
            playerView.findViewById<View?>(androidx.media3.ui.R.id.exo_progress)?.visibility = View.GONE
            playerView.findViewById<View?>(androidx.media3.ui.R.id.exo_time)?.visibility = View.GONE
            findViewById<View?>(R.id.live_indicator)?.visibility = View.VISIBLE
        } else {
            playerView.setShowFastForwardButton(true)
            playerView.setShowRewindButton(true)
            playerView.setShowMultiWindowTimeBar(true)
            playerView.findViewById<View?>(androidx.media3.ui.R.id.exo_progress)?.visibility = View.VISIBLE
            playerView.findViewById<View?>(androidx.media3.ui.R.id.exo_time)?.visibility = View.VISIBLE
            findViewById<View?>(R.id.live_indicator)?.visibility = View.GONE
        }
    }

    @UnstableApi
    @RequiresApi(Build.VERSION_CODES.O)
    override fun enterPictureInPicture() {
        Log.d("Bccm", "enterPictureInPicture fullscreenplayerView")

        val aspectRatio = playerController.player.let {
            if (it.videoSize.width == 0 || it.videoSize.height == 0) null
            else Rational(it.videoSize.width, it.videoSize.height)
        } ?: Rational(16, 9)

        try {
            activity.enterPictureInPictureMode(
                PictureInPictureParams.Builder()
                    .setAspectRatio(aspectRatio)
                    .build()
            )
            playerView?.hideController()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    @UnstableApi
    @RequiresApi(Build.VERSION_CODES.O)
    fun enterPictureInPicture(exitAfter: Boolean) {
        exitAfterPictureInPicture = exitAfter
        enterPictureInPicture()
    }

    @UnstableApi
    private fun release() {
        playerView?.let {
            playerController.releasePlayerView(it)
        }
        mainScope.cancel()
        playerView = null
    }
}