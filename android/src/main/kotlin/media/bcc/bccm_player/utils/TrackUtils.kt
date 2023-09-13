package media.bcc.bccm_player.utils

import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.Player
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi

object TrackUtils {
    fun getAudioTracksForPlayer(player: Player): MutableList<PlaybackPlatformApi.Track> {
        // get tracks from player
        val currentTracks = player.currentTracks;
        val currentAudioTrack =
            currentTracks.groups.firstOrNull { it.isSelected && it.type == C.TRACK_TYPE_AUDIO }
                ?.getTrackFormat(0)

        val audioTracks = mutableListOf<PlaybackPlatformApi.Track>()
        for (trackGroup in currentTracks.groups.filter { it.type == C.TRACK_TYPE_AUDIO }) {
            val track = trackGroup.getTrackFormat(0)
            val id = track.id ?: track.language ?: continue;
            audioTracks.add(
                PlaybackPlatformApi.Track.Builder()
                    .setId(id)
                    .setLanguage(track.language)
                    .setLabel(track.label)
                    .setBitrate(track.averageBitrate.toLong())
                    .setIsSelected(track == currentAudioTrack)
                    .build()
            )
        }

        return audioTracks
    }

    fun getVideoTracksForPlayer(player: Player): MutableList<PlaybackPlatformApi.Track> {
        // get tracks from player
        val currentTracks = player.currentTracks;

        val videoOverride =
            player.trackSelectionParameters.overrides.filter { i -> i.value.type == C.TRACK_TYPE_VIDEO }.values.firstOrNull()
        val currentExplicitlySelectedVideoTrackFormat =
            videoOverride?.mediaTrackGroup?.getFormat(videoOverride.trackIndices.first())

        val videoTracks = mutableListOf<PlaybackPlatformApi.Track>()
        for (trackGroup in currentTracks.groups.filter { it.type == C.TRACK_TYPE_VIDEO }) {
            for (trackIndex in 0 until trackGroup.length) {
                val trackFormat = trackGroup.getTrackFormat(trackIndex)
                if (trackGroup.isTrackSupported(trackIndex)) {
                    val trackId = trackFormat.id ?: continue;
                    videoTracks.add(
                        PlaybackPlatformApi.Track.Builder()
                            .setId(trackId)
                            .setLanguage(null)
                            .setLabel("${trackFormat.width} x ${trackFormat.height}")
                            .setWidth(trackFormat.width.toLong())
                            .setHeight(trackFormat.height.toLong())
                            .setFrameRate(if (trackFormat.frameRate.toInt() == Format.NO_VALUE) null else trackFormat.frameRate.toDouble())
                            .setBitrate(trackFormat.averageBitrate.toLong())
                            .setIsSelected(trackFormat == currentExplicitlySelectedVideoTrackFormat)
                            .build()
                    )

                }
            }
        }

        return videoTracks.apply { this.sortByDescending { t -> t.height } }
    }

    fun getTextTracksForPlayer(player: Player): MutableList<PlaybackPlatformApi.Track> {
        // get tracks from player
        val currentTracks = player.currentTracks;


        val currentTextTrack =
            currentTracks.groups.firstOrNull { it.isSelected && it.type == C.TRACK_TYPE_TEXT }
                ?.getTrackFormat(0)

        val textTracks = mutableListOf<PlaybackPlatformApi.Track>()
        for (trackGroup in currentTracks.groups.filter { it.type == C.TRACK_TYPE_TEXT }) {

            val track = trackGroup.getTrackFormat(0)
            val id = track.id ?: track.language ?: continue;
            textTracks.add(
                PlaybackPlatformApi.Track.Builder()
                    .setId(id)
                    .setLanguage(track.language)
                    .setLabel(track.label)
                    .setBitrate(track.averageBitrate.toLong())
                    .setIsSelected(track == currentTextTrack)
                    .build()
            )
        }

        return textTracks
    }
}