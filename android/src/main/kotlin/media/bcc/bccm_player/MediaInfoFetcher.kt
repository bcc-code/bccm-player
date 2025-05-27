package media.bcc.bccm_player

import android.content.Context
import androidx.media3.common.C.TRACK_TYPE_AUDIO
import androidx.media3.common.C.TRACK_TYPE_TEXT
import androidx.media3.common.C.TRACK_TYPE_VIDEO
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeout
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.MediaInfo
import media.bcc.bccm_player.utils.TrackUtils

object MediaInfoFetcher {
    @UnstableApi
    suspend fun fetchMediaInfo(context: Context, url: String, mimeType: String?): MediaInfo {
        val trackSelector = DefaultTrackSelector(context);
        trackSelector.setParameters(
            trackSelector.buildUponParameters().setMaxVideoBitrate(1).setMaxAudioBitrate(1)
                .setTrackTypeDisabled(TRACK_TYPE_AUDIO, true)
                .setTrackTypeDisabled(TRACK_TYPE_VIDEO, true)
                .setTrackTypeDisabled(TRACK_TYPE_TEXT, true)
        )
        val player = ExoPlayer.Builder(context)
            .setTrackSelector(trackSelector).build()

        player.setMediaItem(MediaItem.Builder().setMimeType(mimeType).setUri(url).build())
        player.prepare()

        withTimeout(10000) {
            suspendCancellableCoroutine { cont ->
                player.addListener(object : Player.Listener {
                    override fun onTracksChanged(tracks: Tracks) {
                        cont.resumeWith(Result.success(Unit))
                    }

                    override fun onPlayerError(error: PlaybackException) {
                        cont.resumeWith(Result.failure(error))
                    }
                })
            }
        }

        val audioTracks = TrackUtils.getAudioTracksForPlayer(player)
        val videoTracks = TrackUtils.getVideoTracksForPlayer(player)
        val textTracks = TrackUtils.getTextTracksForPlayer(player)

        return MediaInfo.Builder()
            .setAudioTracks(audioTracks)
            .setVideoTracks(videoTracks)
            .setTextTracks(textTracks)
            .build()
    }
}