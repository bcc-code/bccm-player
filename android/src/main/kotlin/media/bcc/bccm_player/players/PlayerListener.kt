package media.bcc.bccm_player.players

import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import media.bcc.bccm_player.BccmPlayerPlugin
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi
import media.bcc.bccm_player.utils.NoOpVoidResult

class PlayerListener(private val playerController: PlayerController, val plugin: BccmPlayerPlugin) :
    Player.Listener {

    private val refreshInterval: Long = 15000
    private val mainHandler = Handler(Looper.getMainLooper())
    private var refreshRunnable: Runnable? = null

    private fun startRefreshTimer() {
        stopRefreshTimer()

        refreshRunnable = object : Runnable {
            override fun run() {
                onManualPlayerStateUpdate()
                mainHandler.postDelayed(this, refreshInterval)
            }
        }
        mainHandler.post(refreshRunnable!!)
    }

    private fun stopRefreshTimer() {
        refreshRunnable?.let { runnable ->
            mainHandler.removeCallbacks(runnable)
            refreshRunnable = null
        }
    }

    init {
        Log.d(
            "bccm",
            "startRefreshTimer(), ${playerController}, hashCode:" + this@PlayerListener.hashCode()
        )
        startRefreshTimer()
    }

    fun stop() {
        Log.d(
            "bccm",
            "stopRefreshTimer(), ${playerController}, hashCode:" + this@PlayerListener.hashCode()
        )
        stopRefreshTimer()
    }

    override fun onVideoSizeChanged(videoSize: VideoSize) {
        onManualPlayerStateUpdate()
    }

    fun onManualPlayerStateUpdate() {
        playerController.manualUpdateEvent();
    }

    override fun onPlayerErrorChanged(error: PlaybackException?) {
        onManualPlayerStateUpdate()
    }

    override fun onPlaybackStateChanged(playbackState: Int) {
        if (playbackState == Player.STATE_ENDED) {
            val event =
                PlaybackPlatformApi.PlaybackEndedEvent.Builder()
                    .setPlayerId(playerController.id)
            val mediaItem = playerController.getCurrentMediaItem();
            if (mediaItem != null) {
                event.setMediaItem(mediaItem)
            } else {
                event.setMediaItem(null)
            }
            plugin.playbackPigeon?.onPlaybackEnded(event.build(), NoOpVoidResult())
            playerController.playNext()
        }
        onIsPlayingChanged(playerController.player.isPlaying)
        Log.d("bccm", "playbackState: " + playerController.player.playbackState.toString())
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        val event =
            PlaybackPlatformApi.PlaybackStateChangedEvent.Builder()
                .setPlayerId(playerController.id)
                .setPlaybackState(playerController.getPlaybackState())
                .setIsBuffering(playerController.player.playbackState == Player.STATE_BUFFERING)
        plugin.playbackPigeon?.onPlaybackStateChanged(event.build(), NoOpVoidResult())
    }

    override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
        val event =
            PlaybackPlatformApi.MediaItemTransitionEvent.Builder().setPlayerId(playerController.id)
        if (mediaItem != null) {
            val bccmMediaItem = playerController.mapMediaItem(mediaItem)
            event.setMediaItem(bccmMediaItem)
        } else {
            event.setMediaItem(null)
        }
        plugin.playbackPigeon?.onMediaItemTransition(event.build(), NoOpVoidResult())
    }

    override fun onPositionDiscontinuity(
        oldPosition: Player.PositionInfo, newPosition: Player.PositionInfo, reason: Int
    ) {
        val event = PlaybackPlatformApi.PositionDiscontinuityEvent.Builder()
            .setPlayerId(playerController.id)
        plugin.playbackPigeon?.onPositionDiscontinuity(
            event.setPlaybackPositionMs(newPosition.positionMs.toDouble()).build(), NoOpVoidResult()
        )
    }

}