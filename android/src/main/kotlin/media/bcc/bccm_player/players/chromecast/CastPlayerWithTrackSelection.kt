package media.bcc.bccm_player.players.chromecast

import android.annotation.SuppressLint
import android.util.Log
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.ForwardingPlayer
import androidx.media3.common.Player
import androidx.media3.common.TrackGroup
import androidx.media3.common.TrackSelectionParameters
import androidx.media3.common.Tracks
import com.google.android.gms.cast.MediaTrack
import com.google.android.gms.cast.framework.CastContext


@SuppressLint("UnsafeOptInUsageError")
class CastPlayerWithTrackSelection(private val castContext: CastContext, player: Player) :
    ForwardingPlayer(player) {
    private var selectionBeingProcessed: LongArray? = null
    override fun setTrackSelectionParameters(parameters: TrackSelectionParameters) {
        // Call to the super method is not required because CastPlayer does not support track selection.

        val remoteMediaClient = castContext.sessionManager.currentCastSession?.remoteMediaClient
        remoteMediaClient?.let { client ->
            val trackSelections = mutableMapOf<Long, Boolean>()

            parameters.overrides.forEach { (type, override) ->
                override.trackIndices.forEach { trackIndex ->
                    // Assuming override.group is a type of TrackGroup and you can get the track ID.
                    val trackId = override.mediaTrackGroup.getFormat(trackIndex).id?.toLongOrNull()
                    trackId?.let { id ->
                        trackSelections[id] = true // Mark this track ID as selected.
                    }
                }
            }

            val currentActiveTrackIds = client.mediaStatus?.activeTrackIds?.toSet() ?: emptySet()
            val newActiveTrackIds = trackSelections.filter { it.value }.keys.toLongArray()

            if (!newActiveTrackIds.toSet().equals(currentActiveTrackIds)) {
                selectionBeingProcessed = newActiveTrackIds
                val request = client.setActiveMediaTracks(newActiveTrackIds)
                request.setResultCallback { result ->
                    if (!result.status.isSuccess) {
                        // Handle the error case where track selection failed.
                        Log.e(
                            "bccm",
                            "cast setTrackSelectionParameters failed, error: ${result.mediaError}"
                        )
                    }
                    selectionBeingProcessed = null
                }
            }
        }
    }

    override fun getCurrentTracks(): Tracks {
        val remoteMediaClient =
            castContext.sessionManager.currentCastSession?.remoteMediaClient ?: return Tracks.EMPTY;

        val mediaInfo = remoteMediaClient.mediaInfo
        val trackGroups = mutableListOf<Tracks.Group>()

        val activeTrackIds =
            selectionBeingProcessed ?: remoteMediaClient.mediaStatus?.activeTrackIds

        mediaInfo?.let { it ->
            // Get audio tracks
            val audioTracks =
                it.mediaTracks?.filter { track -> track.type == MediaTrack.TYPE_AUDIO }

            audioTracks?.groupBy { it.language }?.forEach { (language, tracks) ->
                val support = tracks.map { C.FORMAT_HANDLED }
                val selected = tracks.map { activeTrackIds?.contains(it.id) ?: false }
                val group = TrackGroup(
                    *tracks.map { track ->
                        Format.Builder().setId(track.id.toString())
                            .setSampleMimeType(track.contentType ?: "audio/aac")
                            .setContainerMimeType(track.contentType ?: "audio/aac")
                            .setLabel(track.languageLocale?.displayLanguage)
                            .setLanguage(track.language).build()
                    }.toTypedArray()
                )
                trackGroups.add(
                    Tracks.Group(
                        group,
                        true,
                        support.toIntArray(),
                        selected.toBooleanArray()
                    )
                )
            }

            // Get text tracks
            val textTracks =
                it.mediaTracks?.filter { track -> track.type == MediaTrack.TYPE_TEXT }

            textTracks?.groupBy { it.language }?.forEach { (language, tracks) ->
                val support = tracks.map { C.FORMAT_HANDLED }
                val selected = tracks.map { activeTrackIds?.contains(it.id) ?: false }
                val group = TrackGroup(
                    *tracks.map { track ->
                        Format.Builder().setId(track.id.toString())
                            .setSampleMimeType(track.contentType ?: "text/vtt")
                            .setContainerMimeType(track.contentType ?: "text/vtt")
                            .setLabel(track.languageLocale?.displayLanguage)
                            .setLanguage(track.language).build()
                    }.toTypedArray()
                )
                trackGroups.add(
                    Tracks.Group(
                        group,
                        true,
                        support.toIntArray(),
                        selected.toBooleanArray()
                    )
                )
            }
        }

        return Tracks(trackGroups)
    }
}