package media.bcc.bccm_player.players.chromecast

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * [CastPlayerData.from] parses the `media.bcc.player.*` entries a cast receiver
 * carries alongside the standard metadata. Pure map parsing, so it needs no
 * Android runtime.
 */
class CastPlayerDataTest {

    @Test
    fun parsesEveryPlayerDataKey() {
        val data = CastPlayerData.from(
            mapOf(
                CastMediaItemConverter.PLAYER_DATA_IS_LIVE to "true",
                CastMediaItemConverter.PLAYER_DATA_IS_OFFLINE to "false",
                CastMediaItemConverter.PLAYER_DATA_MIME_TYPE to "application/x-mpegURL",
                CastMediaItemConverter.PLAYER_DATA_LAST_KNOWN_AUDIO_LANGUAGE to "no",
                CastMediaItemConverter.PLAYER_DATA_LAST_KNOWN_SUBTITLE_LANGUAGE to "en",
            ),
        )!!

        assertEquals(true, data.isLive)
        assertEquals(false, data.isOffline)
        assertEquals("application/x-mpegURL", data.mimeType)
        assertEquals("no", data.lastKnownAudioLanguage)
        assertEquals("en", data.lastKnownSubtitleLanguage)
    }

    /**
     * Booleans arrive as strings over the cast protocol and are compared against
     * the literal `"true"`, so anything else is false rather than an error.
     */
    @Test
    fun booleansAreParsedFromStrings() {
        fun isLive(value: String) =
            CastPlayerData.from(mapOf(CastMediaItemConverter.PLAYER_DATA_IS_LIVE to value))?.isLive

        assertEquals(true, isLive("true"))
        assertEquals(false, isLive("false"))
        assertEquals(false, isLive("TRUE"))
        assertEquals(false, isLive(""))
    }

    @Test
    fun returnsNullForNullExtras() {
        assertNull(CastPlayerData.from(null))
    }

    /**
     * No `media.bcc.player.*` key at all means the receiver sent nothing of ours,
     * which is different from "sent ours, all empty".
     */
    @Test
    fun returnsNullWhenNoPlayerDataKeysArePresent() {
        assertNull(CastPlayerData.from(emptyMap()))
        assertNull(
            CastPlayerData.from(
                mapOf(
                    "com.example.other" to "x",
                    "${CastMediaItemConverter.BCCM_META_EXTRAS}.something" to "y",
                ),
            ),
        )
    }

    /** Unrelated keys alongside ours are ignored, not mistaken for player data. */
    @Test
    fun ignoresUnrelatedKeys() {
        val data = CastPlayerData.from(
            mapOf(
                "com.example.other" to "x",
                CastMediaItemConverter.PLAYER_DATA_MIME_TYPE to "video/mp4",
            ),
        )!!

        assertEquals("video/mp4", data.mimeType)
        assertNull(data.isLive)
        assertNull(data.lastKnownAudioLanguage)
    }

    @Test
    fun playerDataKeysAreNamespaced() {
        // The receiver side depends on these exact strings.
        assertEquals("media.bcc.player", CastMediaItemConverter.BCCM_PLAYER_DATA)
        assertEquals("media.bcc.extras", CastMediaItemConverter.BCCM_META_EXTRAS)
        assertEquals("media.bcc.player.is_live", CastMediaItemConverter.PLAYER_DATA_IS_LIVE)
        assertTrue(
            CastMediaItemConverter.PLAYER_DATA_LAST_KNOWN_AUDIO_LANGUAGE
                .startsWith(CastMediaItemConverter.BCCM_PLAYER_DATA),
        )
    }
}
