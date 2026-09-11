package media.bcc.bccm_player.pigeon

import media.bcc.bccm_player.pigeon.DownloaderApi.Download
import media.bcc.bccm_player.pigeon.DownloaderApi.DownloadConfig
import media.bcc.bccm_player.pigeon.DownloaderApi.DownloadFailedEvent
import media.bcc.bccm_player.pigeon.DownloaderApi.DownloadRemovedEvent
import media.bcc.bccm_player.pigeon.DownloaderApi.DownloadStatus
import media.bcc.bccm_player.pigeon.DownloaderApi.DownloaderPigeon
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.MediaItem
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.MediaMetadata
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.PlaybackPlatformPigeon
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.PlaybackState
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.PlayerStateSnapshot
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.Track
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.VideoSize
import org.junit.Assert.assertEquals
import org.junit.Test
import java.nio.ByteBuffer

/**
 * Round-trips every shape we care about through the generated codecs.
 *
 * This pins two things a compile cannot: the **type identifier** each class is
 * written with (drift here corrupts data between a Dart side and a native side
 * that were regenerated at different times), and the **field order** inside
 * `toList`/`fromList` — a reordered field survives encode/decode as a value of
 * the wrong property, which no type checker will notice.
 *
 * The type identifiers asserted here must match
 * `example/ios/RunnerTests/PigeonCodecTests.swift`; that pairing is the whole
 * point, since a mismatch between platforms is the failure being guarded
 * against.
 */
class PigeonCodecTest {

    private val playbackCodec = PlaybackPlatformPigeon.getCodec()
    private val downloaderCodec = DownloaderPigeon.getCodec()

    /**
     * A full encode/decode through the generated codec. Only valid for shapes
     * with no enum fields — see [playerStateSnapshotFieldOrder] for why.
     */
    private fun roundTrip(codec: io.flutter.plugin.common.MessageCodec<Any>, value: Any): Any? {
        val encoded = codec.encodeMessage(value)!!
        encoded.rewind()
        return codec.decodeMessage(encoded)
    }

    private fun typeIdentifier(
        codec: io.flutter.plugin.common.MessageCodec<Any>,
        value: Any,
    ): Int {
        val encoded: ByteBuffer = codec.encodeMessage(value)!!
        encoded.rewind()
        return encoded.get().toInt() and 0xFF
    }

    @Test
    fun mediaItemRoundTrip() {
        val item = sampleMediaItem()
        val decoded = roundTrip(playbackCodec, item) as MediaItem

        assertEquals(item, decoded)
        // Spot-check individual fields too: `equals` is itself generated, so a
        // codegen bug could in principle break both symmetrically.
        assertEquals("item-id", decoded.id)
        assertEquals("https://example.com/stream.m3u8", decoded.url)
        assertEquals("Sample title", decoded.metadata?.title)
        assertEquals("value", decoded.metadata?.extras?.get("key"))
        assertEquals("no", decoded.lastKnownAudioLanguage)
        assertEquals("en", decoded.lastKnownSubtitleLanguage)
    }

    @Test
    fun trackRoundTrip() {
        val track = Track.Builder()
            .setId("track-1")
            .setLabel("Norsk")
            .setLanguage("no")
            .setFrameRate(null)
            .setBitrate(128_000L)
            .setWidth(null)
            .setHeight(null)
            .setDownloaded(false)
            .setIsSelected(true)
            .build()

        val decoded = roundTrip(playbackCodec, track) as Track

        assertEquals(track, decoded)
        assertEquals(true, decoded.isSelected)
        assertEquals(false, decoded.downloaded)
        assertEquals(128_000L, decoded.bitrate)
    }

    /**
     * Pins field order via `toList`/`fromList` rather than a full codec
     * round-trip, because a **Java-to-Java** codec round-trip is not
     * representative for enum-bearing shapes and fails spuriously.
     *
     * Pigeon's Dart codec overrides `writeValue` to emit every `int` as int64,
     * and the generated Java decoder relies on that — it reads an enum index
     * with `((Long) value).intValue()`. But Java's own `StandardMessageCodec`
     * writes a boxed `Integer` as int32, so encoding here and decoding here
     * throws `ClassCastException: Integer cannot be cast to Long`. That
     * asymmetry is harmless in production: this codec only ever decodes bytes
     * Dart wrote, and only ever encodes bytes Dart will read. It is an artifact
     * of the test direction, not a defect — and it predates Pigeon v28.
     *
     * `fromList` receives already-decoded values, so this still pins the thing
     * that matters: which list slot maps to which property.
     */
    @Test
    fun playerStateSnapshotFieldOrder() {
        val snapshot = PlayerStateSnapshot.Builder()
            .setPlayerId("player-1")
            .setPlaybackState(PlaybackState.PLAYING)
            .setIsBuffering(false)
            .setIsFullscreen(false)
            .setPlaybackSpeed(1.0)
            .setVideoSize(VideoSize.Builder().setWidth(1920L).setHeight(1080L).build())
            .setCurrentMediaItem(sampleMediaItem())
            .setPlaybackPositionMs(12_345.0)
            .setTextureId(null)
            .setVolume(0.8)
            .setError(null)
            .setSeekableRangeStartMs(1_000.0)
            .setSeekableRangeEndMs(99_000.0)
            .build()

        val decoded = PlayerStateSnapshot.fromList(snapshot.toList())

        assertEquals(snapshot, decoded)
        assertEquals(PlaybackState.PLAYING, decoded.playbackState)
        // Encoding is symmetric even for enum-bearing shapes, so the type
        // identifier is still worth pinning here.
        assertEquals(140, typeIdentifier(playbackCodec, snapshot))
        // The seekable range is the pair the live-edge UI depends on, and the
        // two fields sit next to each other — exactly the shape a field reorder
        // would swap unnoticed.
        assertEquals(1_000.0, decoded.seekableRangeStartMs!!, 0.0001)
        assertEquals(99_000.0, decoded.seekableRangeEndMs!!, 0.0001)
    }

    /**
     * The first byte of an encoded value is the Pigeon type identifier. These
     * are assigned by declaration order in the `.dart` pigeon file, so
     * inserting a class in the middle renumbers everything after it.
     */
    @Test
    fun typeIdentifiersAreStable() {
        assertEquals(138, typeIdentifier(playbackCodec, sampleMediaItem()))
        assertEquals(139, typeIdentifier(playbackCodec, MediaMetadata.Builder().build()))
        assertEquals(
            142,
            typeIdentifier(playbackCodec, VideoSize.Builder().setWidth(1L).setHeight(1L).build()),
        )
    }

    /** Field order via `toList`/`fromList` — see [playerStateSnapshotFieldOrder]. */
    @Test
    fun downloadFieldOrder() {
        val download = Download.Builder()
            .setKey("download-key")
            .setConfig(
                DownloadConfig.Builder()
                    .setUrl("https://example.com/stream.m3u8")
                    .setMimeType("application/x-mpegURL")
                    .setTitle("Sample")
                    .setAudioTrackIds(listOf("no", "en"))
                    .setVideoTrackIds(listOf("720"))
                    .setAdditionalData(mapOf("key" to "value"))
                    .build(),
            )
            .setOfflineUrl("file:///offline/stream")
            .setFractionDownloaded(0.42)
            .setStatus(DownloadStatus.DOWNLOADING)
            .setError(null)
            .build()

        val decoded = Download.fromList(download.toList())

        assertEquals(download, decoded)
        assertEquals(DownloadStatus.DOWNLOADING, decoded.status)
        assertEquals(0.42, decoded.fractionDownloaded, 0.0001)
        assertEquals(2, decoded.config.audioTrackIds.size)
    }

    @Test
    fun downloadEventsRoundTrip() {
        val removed = DownloadRemovedEvent.Builder().setKey("gone").build()
        assertEquals(removed, roundTrip(downloaderCodec, removed))

        val failed = DownloadFailedEvent.Builder().setKey("bad").setError("network").build()
        assertEquals(failed, roundTrip(downloaderCodec, failed))
    }

    private fun sampleMediaItem(): MediaItem = MediaItem.Builder()
        .setId("item-id")
        .setUrl("https://example.com/stream.m3u8")
        .setMimeType("application/x-mpegURL")
        .setMetadata(
            MediaMetadata.Builder()
                .setArtworkUri("https://example.com/art.jpg")
                .setTitle("Sample title")
                .setArtist("Sample artist")
                .setDurationMs(60_000.0)
                .setExtras(mapOf("key" to "value"))
                .build(),
        )
        .setIsLive(true)
        .setIsOffline(false)
        .setPlaybackStartPositionMs(42.0)
        .setLastKnownAudioLanguage("no")
        .setLastKnownSubtitleLanguage("en")
        .build()
}
