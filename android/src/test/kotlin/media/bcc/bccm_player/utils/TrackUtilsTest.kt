package media.bcc.bccm_player.utils

import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.TrackGroup
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.TrackSelectionParameters
import androidx.media3.common.Tracks
import androidx.media3.test.utils.StubPlayer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Builds the track lists behind the audio/subtitle/quality pickers. Each item
 * needs a stable `id`, because that is what Dart sends back to select a track —
 * a track whose id changes shape becomes unselectable.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class TrackUtilsTest {

    // MARK: Audio

    @Test
    fun mapsAudioTracksAndMarksTheSelectedOne() {
        val norwegian = audioFormat(id = "audio-no", language = "no", label = "Norsk")
        val english = audioFormat(id = "audio-en", language = "en", label = "English")
        val player = playerWith(
            group(norwegian, type = C.TRACK_TYPE_AUDIO, selected = true),
            group(english, type = C.TRACK_TYPE_AUDIO, selected = false),
        )

        val tracks = TrackUtils.getAudioTracksForPlayer(player)

        assertEquals(2, tracks.size)
        assertEquals("audio-no", tracks[0].id)
        assertEquals("no", tracks[0].language)
        assertEquals("Norsk", tracks[0].label)
        assertEquals(128_000L, tracks[0].bitrate)
        assertEquals(true, tracks[0].isSelected)
        assertEquals(false, tracks[1].isSelected)
    }

    /** Not every stream labels its tracks, so the language stands in as the id. */
    @Test
    fun fallsBackToLanguageWhenTheFormatHasNoId() {
        val player = playerWith(
            group(audioFormat(id = null, language = "no"), type = C.TRACK_TYPE_AUDIO),
        )

        val tracks = TrackUtils.getAudioTracksForPlayer(player)

        assertEquals(1, tracks.size)
        assertEquals("no", tracks[0].id)
    }

    /** With neither an id nor a language there is nothing to select by, so it is dropped. */
    @Test
    fun dropsAudioTracksWithNeitherIdNorLanguage() {
        val player = playerWith(
            group(audioFormat(id = null, language = null), type = C.TRACK_TYPE_AUDIO),
            group(audioFormat(id = "audio-en", language = "en"), type = C.TRACK_TYPE_AUDIO),
        )

        val tracks = TrackUtils.getAudioTracksForPlayer(player)

        assertEquals(1, tracks.size)
        assertEquals("audio-en", tracks[0].id)
    }

    @Test
    fun eachListerIgnoresTheOtherTrackTypes() {
        val player = playerWith(
            group(audioFormat(id = "audio-no", language = "no"), type = C.TRACK_TYPE_AUDIO),
            group(textFormat(id = "text-en", language = "en"), type = C.TRACK_TYPE_TEXT),
            group(videoFormat(id = "video-720", height = 720), type = C.TRACK_TYPE_VIDEO),
        )

        assertEquals(1, TrackUtils.getAudioTracksForPlayer(player).size)
        assertEquals(1, TrackUtils.getTextTracksForPlayer(player).size)
        assertEquals(1, TrackUtils.getVideoTracksForPlayer(player).size)
    }

    // MARK: Text

    @Test
    fun mapsTextTracksAndMarksTheSelectedOne() {
        val player = playerWith(
            group(
                textFormat(id = "text-no", language = "no", label = "Norsk"),
                type = C.TRACK_TYPE_TEXT,
                selected = true,
            ),
            group(textFormat(id = "text-en", language = "en", label = "English"), type = C.TRACK_TYPE_TEXT),
        )

        val tracks = TrackUtils.getTextTracksForPlayer(player)

        assertEquals(2, tracks.size)
        assertEquals("text-no", tracks[0].id)
        assertEquals("Norsk", tracks[0].label)
        assertEquals(true, tracks[0].isSelected)
        assertEquals(false, tracks[1].isSelected)
    }

    @Test
    fun dropsTextTracksWithNeitherIdNorLanguage() {
        val player = playerWith(
            group(textFormat(id = null, language = null), type = C.TRACK_TYPE_TEXT),
        )

        assertTrue(TrackUtils.getTextTracksForPlayer(player).isEmpty())
    }

    // MARK: Video

    /** Quality pickers read top-down, so the list is sorted by descending height. */
    @Test
    fun sortsVideoTracksByDescendingHeight() {
        val player = playerWith(
            group(videoFormat(id = "v-360", height = 360, width = 640), type = C.TRACK_TYPE_VIDEO),
            group(videoFormat(id = "v-1080", height = 1080, width = 1920), type = C.TRACK_TYPE_VIDEO),
            group(videoFormat(id = "v-720", height = 720, width = 1280), type = C.TRACK_TYPE_VIDEO),
        )

        val heights = TrackUtils.getVideoTracksForPlayer(player).map { it.height }

        assertEquals(listOf(1080L, 720L, 360L), heights)
    }

    @Test
    fun labelsVideoTracksWithTheirResolution() {
        val player = playerWith(
            group(videoFormat(id = "v-720", height = 720, width = 1280), type = C.TRACK_TYPE_VIDEO),
        )

        val track = TrackUtils.getVideoTracksForPlayer(player).single()

        assertEquals("1280 x 720", track.label)
        assertEquals(1280L, track.width)
        assertEquals(720L, track.height)
        assertNull(track.language)
    }

    /**
     * Video selection is reported from the explicit override, not from whatever
     * the adaptive selector happens to be playing — otherwise "Auto" would show
     * up as a fixed quality.
     */
    @Test
    fun marksOnlyTheExplicitlyOverriddenVideoTrack() {
        val selectedGroup = group(
            videoFormat(id = "v-720", height = 720, width = 1280),
            type = C.TRACK_TYPE_VIDEO,
            selected = true,
        )
        val player = playerWith(
            tracks = Tracks(
                listOf(
                    selectedGroup,
                    group(videoFormat(id = "v-1080", height = 1080, width = 1920), type = C.TRACK_TYPE_VIDEO),
                ),
            ),
            parameters = TrackSelectionParameters.DEFAULT.buildUpon()
                .addOverride(TrackSelectionOverride(selectedGroup.mediaTrackGroup, 0))
                .build(),
        )

        val tracks = TrackUtils.getVideoTracksForPlayer(player).associateBy { it.id }

        assertEquals(true, tracks["v-720"]!!.isSelected)
        assertEquals(false, tracks["v-1080"]!!.isSelected)
    }

    @Test
    fun noOverrideMeansNoVideoTrackIsSelected() {
        val player = playerWith(
            group(
                videoFormat(id = "v-720", height = 720, width = 1280),
                type = C.TRACK_TYPE_VIDEO,
                selected = true,
            ),
        )

        assertEquals(false, TrackUtils.getVideoTracksForPlayer(player).single().isSelected)
    }

    /** An unsupported rendition cannot be played, so offering it would be a dead end. */
    @Test
    fun skipsUnsupportedVideoTracks() {
        val player = playerWith(
            group(
                videoFormat(id = "v-4k", height = 2160, width = 3840),
                type = C.TRACK_TYPE_VIDEO,
                supported = false,
            ),
            group(videoFormat(id = "v-720", height = 720, width = 1280), type = C.TRACK_TYPE_VIDEO),
        )

        val tracks = TrackUtils.getVideoTracksForPlayer(player)

        assertEquals(1, tracks.size)
        assertEquals("v-720", tracks.single().id)
    }

    @Test
    fun unsetFrameRateIsReportedAsNull() {
        val player = playerWith(
            group(videoFormat(id = "v-720", height = 720, width = 1280), type = C.TRACK_TYPE_VIDEO),
        )

        assertNull(TrackUtils.getVideoTracksForPlayer(player).single().frameRate)
    }

    // MARK: Fixtures

    private fun audioFormat(id: String?, language: String?, label: String? = null) =
        Format.Builder()
            .setId(id)
            .setLanguage(language)
            .setLabel(label)
            .setAverageBitrate(128_000)
            .setSampleMimeType("audio/mp4a-latm")
            .build()

    private fun textFormat(id: String?, language: String?, label: String? = null) =
        Format.Builder()
            .setId(id)
            .setLanguage(language)
            .setLabel(label)
            .setAverageBitrate(1_000)
            .setSampleMimeType("text/vtt")
            .build()

    private fun videoFormat(id: String?, height: Int, width: Int = 1280) =
        Format.Builder()
            .setId(id)
            .setWidth(width)
            .setHeight(height)
            .setAverageBitrate(2_000_000)
            .setSampleMimeType("video/avc")
            .build()

    private fun group(
        format: Format,
        type: Int,
        selected: Boolean = false,
        supported: Boolean = true,
    ): Tracks.Group = Tracks.Group(
        TrackGroup(format.id ?: "group-$type-${format.hashCode()}", format),
        false,
        intArrayOf(if (supported) C.FORMAT_HANDLED else C.FORMAT_UNSUPPORTED_TYPE),
        booleanArrayOf(selected),
    )

    private fun playerWith(vararg groups: Tracks.Group) =
        playerWith(Tracks(groups.toList()), TrackSelectionParameters.DEFAULT)

    private fun playerWith(tracks: Tracks, parameters: TrackSelectionParameters) =
        object : StubPlayer() {
            override fun getCurrentTracks(): Tracks = tracks
            override fun getTrackSelectionParameters(): TrackSelectionParameters = parameters
        }
}
