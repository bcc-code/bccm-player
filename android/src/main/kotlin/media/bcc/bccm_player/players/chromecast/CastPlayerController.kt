package media.bcc.bccm_player.players.chromecast

import android.annotation.SuppressLint
import android.os.Bundle
import android.util.Log
import androidx.media3.cast.CastPlayer
import androidx.media3.cast.SessionAvailabilityListener
import androidx.media3.common.C
import androidx.media3.common.ForwardingPlayer
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.Session
import com.google.android.gms.cast.framework.SessionManagerListener
import media.bcc.bccm_player.PlaybackService
import media.bcc.bccm_player.pigeon.ChromecastControllerPigeon
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi
import media.bcc.bccm_player.players.PlayerController
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.PLAYER_DATA_LAST_KNOWN_AUDIO_LANGUAGE
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.PLAYER_DATA_LAST_KNOWN_SUBTITLE_LANGUAGE
import media.bcc.bccm_player.players.exoplayer.BccmPlayerViewController
import media.bcc.bccm_player.utils.ChromecastNoOpVoidResult

@SuppressLint("UnsafeOptInUsageError")
class CastPlayerController(
    private val castContext: CastContext,
    private val playbackService: PlaybackService
) : PlayerController(), SessionManagerListener<Session>, SessionAvailabilityListener {
    val castPlayer = CastPlayer(castContext, CastMediaItemConverter())
    override val player: ForwardingPlayer = CastPlayerWithTrackSelection(castContext, castPlayer)
    override var currentPlayerViewController: BccmPlayerViewController? = null

    override val id: String = "chromecast"

    init {
        castPlayer.playWhenReady = true
        castPlayer.setSessionAvailabilityListener(this)
        castContext.sessionManager.addSessionManagerListener(this)
    }

    override fun release() {
        castPlayer.setSessionAvailabilityListener(null)
        castContext.sessionManager.removeSessionManagerListener(this)
        //player.release() - this causes the player to stop
        super.release()
    }

    override fun stop(reset: Boolean) {
        if (reset) {
            castPlayer.clearMediaItems()
        } else {
            castPlayer.pause()
        }
    }

    override fun setMixWithOthers(mixWithOthers: Boolean) {
        // no-op for chromecast
    }

    fun getState(): PlaybackPlatformApi.ChromecastState {
        val builder = PlaybackPlatformApi.ChromecastState.Builder()
        Log.d("bccm", "getState, player currentMediaItem: " + castPlayer.currentMediaItem)
        castPlayer.currentMediaItem?.let {
            builder.setMediaItem(mapMediaItem(it))
        }
        builder.setConnectionState(PlaybackPlatformApi.CastConnectionState.values()[castContext.castState])
        return builder.build()
    }


    // SessionManagerListener

    override fun onSessionEnded(p0: Session, p1: Int) {
        Log.d("bccm", "CastPlayerController::onSessionEnded")
        plugin?.chromecastPigeon?.onSessionEnded(ChromecastNoOpVoidResult())
    }

    override fun onSessionEnding(p0: Session) {
        Log.d("bccm", "CastPlayerController::onSessionEnding")
        plugin?.chromecastPigeon?.onSessionEnding(ChromecastNoOpVoidResult())
    }

    override fun onSessionResumeFailed(p0: Session, p1: Int) {
        Log.d("bccm", "CastPlayerController::onSessionResumeFailed")
        plugin?.chromecastPigeon?.onSessionResumeFailed(ChromecastNoOpVoidResult())
    }

    override fun onSessionResumed(p0: Session, p1: Boolean) {
        Log.d("bccm", "CastPlayerController::onSessionResumed, setting as primary")
        plugin?.chromecastPigeon?.onSessionResumed(ChromecastNoOpVoidResult())
        playbackService.setPrimary(this.id);
    }

    override fun onSessionResuming(p0: Session, p1: String) {
        Log.d("bccm", "CastPlayerController::onSessionResuming")
        plugin?.chromecastPigeon?.onSessionResuming(ChromecastNoOpVoidResult())
    }

    override fun onSessionStartFailed(p0: Session, p1: Int) {
        Log.d("bccm", "CastPlayerController::onSessionStartFailed")
        plugin?.chromecastPigeon?.onSessionStartFailed(ChromecastNoOpVoidResult())
    }

    override fun onSessionStarted(p0: Session, p1: String) {
        Log.d("bccm", "CastPlayerController::onSessionStarted")
        plugin?.chromecastPigeon?.onSessionStarted(ChromecastNoOpVoidResult())
    }

    override fun onSessionStarting(p0: Session) {
        Log.d("bccm", "CastPlayerController::onSessionStarting")
        plugin?.chromecastPigeon?.onSessionStarting(ChromecastNoOpVoidResult())
    }

    override fun onSessionSuspended(p0: Session, p1: Int) {
        Log.d("bccm", "CastPlayerController::onSessionSuspended")
        plugin?.chromecastPigeon?.onSessionSuspended(ChromecastNoOpVoidResult())
    }

    // SessionAvailabilityListener

    override fun onCastSessionAvailable() {
        plugin?.chromecastPigeon?.onCastSessionAvailable(ChromecastNoOpVoidResult())
        Log.d("bccm", "Session available. Transferring state from primaryPlayer to castPlayer")
        val primaryController = playbackService.getPrimaryController()
        val primaryPlayer =
            primaryController?.player ?: return

        Log.d(
            "bccm",
            "oncastsessionavailable + " + castPlayer.mediaMetadata.extras?.getString("id")
        )
        manuallySelectedAudioLanguage = primaryController.manuallySelectedAudioLanguage
        if (primaryPlayer.isPlaying) {
            transferMediaItems(primaryPlayer, castPlayer)
        } else {
            primaryPlayer.pause()
        }
        playbackService.setPrimary(this.id);
    }

    override fun onCastSessionUnavailable() {
        val event = ChromecastControllerPigeon.CastSessionUnavailableEvent.Builder()
        val currentPosition = castPlayer.currentPosition
        if (currentPosition > 0) {
            event.setPlaybackPositionMs(currentPosition)
        }
        playbackService.unclaimIfPrimary(this)
        plugin?.chromecastPigeon?.onCastSessionUnavailable(event.build(), ChromecastNoOpVoidResult())
    };
}

// Extra

private fun transferMediaItems(previous: Player, next: Player) {
    val currentTracks = previous.currentTracks
    Log.d("bccm", currentTracks.toString())
    val audioTrack =
        currentTracks.groups.firstOrNull { it.isSelected && it.type == C.TRACK_TYPE_AUDIO }
            ?.getTrackFormat(0)?.language
    val subtitleTrack =
        currentTracks.groups.firstOrNull { it.isSelected && it.type == C.TRACK_TYPE_TEXT }
            ?.getTrackFormat(0)?.language
    Log.d("bccm", "audioTrack when transferring to cast: $audioTrack")
    Log.d("bccm", "subtitleTrack when transferring to cast: $subtitleTrack")

    // Copy state from primary player
    var playbackPositionMs = C.TIME_UNSET
    var currentItemIndex = C.INDEX_UNSET

    val queue = mutableListOf<MediaItem>()
    for (x in 0 until previous.mediaItemCount) {
        val mediaItem = previous.getMediaItemAt(x)
        val metaBuilder = mediaItem.mediaMetadata.buildUpon()
        val extras = mediaItem.mediaMetadata.extras ?: Bundle()
        extras.putString(PLAYER_DATA_LAST_KNOWN_AUDIO_LANGUAGE, audioTrack)
        extras.putString(PLAYER_DATA_LAST_KNOWN_SUBTITLE_LANGUAGE, subtitleTrack)
        metaBuilder.setExtras(extras)
        val newMediaItem = mediaItem
            .buildUpon()
            .setMediaMetadata(metaBuilder.build())
            .build()
        queue.add(newMediaItem)
    }

    if (previous.playbackState != Player.STATE_ENDED) {
        if (!previous.isCurrentMediaItemDynamic)
            playbackPositionMs = previous.currentPosition
        currentItemIndex = previous.currentMediaItemIndex
    }
    previous.stop()
    previous.clearMediaItems()
    next.setMediaItems(queue, currentItemIndex, playbackPositionMs)
    next.playWhenReady = true
    next.prepare()
    next.play()
}