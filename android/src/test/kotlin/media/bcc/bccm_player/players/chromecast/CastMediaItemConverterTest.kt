package media.bcc.bccm_player.players.chromecast

import android.os.Bundle
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaQueueItem
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import com.google.android.gms.cast.MediaMetadata as CastMetadata

/**
 * Mapping between media3 [MediaItem] and the Cast SDK's [MediaQueueItem].
 *
 * This is the sender/receiver contract, so a mis-mapped field shows up as wrong
 * text on someone's TV rather than as a crash. The class is adapted from media3's
 * `DefaultMediaItemConverter`; these tests pin our deviations from it and guard
 * the fields we actually rely on.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CastMediaItemConverterTest {

    private val converter = CastMediaItemConverter()

    // MARK: toMediaItem

    /**
     * Regression test: `KEY_ALBUM_TITLE` used to be written into `setArtist`,
     * which silently clobbered the artist whenever an item carried both. Upstream
     * media3 maps it to `setAlbumTitle`.
     */
    @Test
    fun albumTitleDoesNotOverwriteArtist() {
        val castMetadata = CastMetadata(CastMetadata.MEDIA_TYPE_MOVIE).apply {
            putString(CastMetadata.KEY_ARTIST, "The Artist")
            putString(CastMetadata.KEY_ALBUM_TITLE, "The Album")
        }

        val mediaItem = converter.toMediaItem(queueItem(metadata = castMetadata))

        assertEquals("The Artist", mediaItem.mediaMetadata.artist)
        assertEquals("The Album", mediaItem.mediaMetadata.albumTitle)
    }

    @Test
    fun mapsStandardMetadataFields() {
        val castMetadata = CastMetadata(CastMetadata.MEDIA_TYPE_MOVIE).apply {
            putString(CastMetadata.KEY_TITLE, "Title")
            putString(CastMetadata.KEY_SUBTITLE, "Subtitle")
            putString(CastMetadata.KEY_ALBUM_ARTIST, "Album Artist")
            putString(CastMetadata.KEY_COMPOSER, "Composer")
            putInt(CastMetadata.KEY_DISC_NUMBER, 2)
            putInt(CastMetadata.KEY_TRACK_NUMBER, 7)
        }

        val metadata = converter.toMediaItem(queueItem(metadata = castMetadata)).mediaMetadata

        assertEquals("Title", metadata.title)
        assertEquals("Subtitle", metadata.subtitle)
        assertEquals("Album Artist", metadata.albumArtist)
        assertEquals("Composer", metadata.composer)
        assertEquals(2, metadata.discNumber)
        assertEquals(7, metadata.trackNumber)
    }

    /** Only our own namespaced keys survive into extras; everything else is dropped. */
    @Test
    fun carriesNamespacedExtrasOnly() {
        val castMetadata = CastMetadata(CastMetadata.MEDIA_TYPE_MOVIE).apply {
            putString(CastMediaItemConverter.PLAYER_DATA_IS_LIVE, "true")
            putString("${CastMediaItemConverter.BCCM_META_EXTRAS}.episode_id", "abc")
            putString(CastMetadata.KEY_TITLE, "Title")
        }

        val extras = converter.toMediaItem(queueItem(metadata = castMetadata)).mediaMetadata.extras!!

        assertEquals("true", extras.getString(CastMediaItemConverter.PLAYER_DATA_IS_LIVE))
        assertEquals("abc", extras.getString("${CastMediaItemConverter.BCCM_META_EXTRAS}.episode_id"))
        assertNull(extras.getString(CastMetadata.KEY_TITLE))
    }

    /** The mime type travels in our player data, not in the Cast content type. */
    @Test
    fun takesMimeTypeFromPlayerData() {
        val castMetadata = CastMetadata(CastMetadata.MEDIA_TYPE_MOVIE).apply {
            putString(CastMediaItemConverter.PLAYER_DATA_MIME_TYPE, "application/x-mpegURL")
        }

        val mediaItem = converter.toMediaItem(queueItem(metadata = castMetadata))

        assertEquals("application/x-mpegURL", mediaItem.localConfiguration!!.mimeType)
    }

    // MARK: toMediaQueueItem

    @Test
    fun roundTripPreservesMetadata() {
        val original = mediaItem(
            MediaMetadata.Builder()
                .setTitle("Title")
                .setSubtitle("Subtitle")
                .setArtist("The Artist")
                .setAlbumTitle("The Album")
                .setAlbumArtist("Album Artist")
                .build(),
        )

        val roundTripped = converter.toMediaItem(converter.toMediaQueueItem(original))

        assertEquals("Title", roundTripped.mediaMetadata.title)
        assertEquals("Subtitle", roundTripped.mediaMetadata.subtitle)
        assertEquals("The Artist", roundTripped.mediaMetadata.artist)
        assertEquals("The Album", roundTripped.mediaMetadata.albumTitle)
        assertEquals("Album Artist", roundTripped.mediaMetadata.albumArtist)
    }

    @Test
    fun liveContentUsesLiveStreamType() {
        val live = converter.toMediaQueueItem(
            mediaItem(metadataWithExtras(CastMediaItemConverter.PLAYER_DATA_IS_LIVE to "true")),
        )
        val vod = converter.toMediaQueueItem(
            mediaItem(metadataWithExtras(CastMediaItemConverter.PLAYER_DATA_IS_LIVE to "false")),
        )

        assertEquals(MediaInfo.STREAM_TYPE_LIVE, live.media!!.streamType)
        assertEquals(MediaInfo.STREAM_TYPE_BUFFERED, vod.media!!.streamType)
    }

    /**
     * The receiver picks its initial audio/subtitle track from these lists, with
     * the item's last-known language taking precedence over the app defaults.
     */
    @Test
    fun sendsLastKnownLanguagesAheadOfAppDefaults() {
        val queueItem = converter.toMediaQueueItem(
            mediaItem(
                metadataWithExtras(
                    CastMediaItemConverter.PLAYER_DATA_LAST_KNOWN_AUDIO_LANGUAGE to "no",
                    CastMediaItemConverter.PLAYER_DATA_LAST_KNOWN_SUBTITLE_LANGUAGE to "en",
                ),
            ),
        )

        val customData = queueItem.media!!.customData!!
        assertEquals("no", customData.getJSONArray("audioTracks").getString(0))
        assertEquals("en", customData.getJSONArray("subtitlesTracks").getString(0))
    }

    @Test
    fun customDataCarriesTheSerializedMediaItem() {
        val queueItem = converter.toMediaQueueItem(
            mediaItem(MediaMetadata.Builder().setTitle("Title").build(), mediaId = "item-1"),
        )

        val mediaItemJson = queueItem.media!!.customData!!.getJSONObject("mediaItem")
        assertEquals("item-1", mediaItemJson.getString("mediaId"))
        assertEquals("Title", mediaItemJson.getString("title"))
        assertEquals(CONTENT_URL, mediaItemJson.getString("uri"))
    }

    /** A non-default mediaId becomes the contentId; otherwise the URL stands in. */
    @Test
    fun contentIdFallsBackToTheUrl() {
        val withId = converter.toMediaQueueItem(
            mediaItem(MediaMetadata.EMPTY, mediaId = "item-1"),
        )
        val withoutId = converter.toMediaQueueItem(mediaItem(MediaMetadata.EMPTY))

        assertEquals("item-1", withId.media!!.contentId)
        assertEquals(CONTENT_URL, withoutId.media!!.contentId)
    }

    /** The Cast SDK cannot play an item without one, so failing early is correct. */
    @Test(expected = IllegalArgumentException::class)
    fun rejectsAnItemWithoutAMimeType() {
        converter.toMediaQueueItem(
            MediaItem.Builder().setUri(CONTENT_URL).build(),
        )
    }

    // MARK: Fixtures

    private fun queueItem(metadata: CastMetadata): MediaQueueItem {
        val mediaInfo = MediaInfo.Builder(CONTENT_URL)
            .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
            .setContentType("video/mp4")
            .setContentUrl(CONTENT_URL)
            .setMetadata(metadata)
            .build()
        return MediaQueueItem.Builder(mediaInfo).build()
    }

    private fun mediaItem(
        metadata: MediaMetadata,
        mediaId: String? = null,
    ): MediaItem = MediaItem.Builder()
        .setUri(CONTENT_URL)
        .setMimeType("video/mp4")
        .setMediaMetadata(metadata)
        .apply { mediaId?.let { setMediaId(it) } }
        .build()

    private fun metadataWithExtras(vararg pairs: Pair<String, String>): MediaMetadata {
        val bundle = Bundle().apply { pairs.forEach { putString(it.first, it.second) } }
        return MediaMetadata.Builder().setExtras(bundle).build()
    }

    companion object {
        private const val CONTENT_URL = "https://example.com/stream.m3u8"
    }
}
