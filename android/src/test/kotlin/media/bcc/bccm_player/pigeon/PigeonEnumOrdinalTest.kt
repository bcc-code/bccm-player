package media.bcc.bccm_player.pigeon

import media.bcc.bccm_player.pigeon.DownloaderApi.DownloadStatus
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.BufferMode
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.CastConnectionState
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.PlaybackState
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.RepeatMode
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.TrackType
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Pigeon encodes enums **by index**, not by name. Reordering a case in
 * the `pigeons` directory therefore changes the wire value on every platform while
 * everything still compiles and every regenerated side still agrees with
 * itself — so a consumer running a stale native build silently gets
 * `PLAYING` where `PAUSED` was meant.
 *
 * These are tripwires, not descriptions: if one fails, either the change was a
 * mistake, or it is deliberate and the matching Dart and Swift assertions
 * (`example/ios/RunnerTests/PigeonEnumOrdinalTests.swift`) must be updated in
 * the same commit.
 */
class PigeonEnumOrdinalTest {
    @Test
    fun bufferModeOrdinals() {
        assertEquals(0, BufferMode.STANDARD.ordinal)
        assertEquals(1, BufferMode.FAST_START_SHORT_FORM.ordinal)
        assertEquals(2, BufferMode.entries.size)
    }

    @Test
    fun repeatModeOrdinals() {
        assertEquals(0, RepeatMode.OFF.ordinal)
        assertEquals(1, RepeatMode.ONE.ordinal)
        assertEquals(2, RepeatMode.entries.size)
    }

    @Test
    fun playbackStateOrdinals() {
        assertEquals(0, PlaybackState.STOPPED.ordinal)
        assertEquals(1, PlaybackState.PAUSED.ordinal)
        assertEquals(2, PlaybackState.PLAYING.ordinal)
        assertEquals(3, PlaybackState.entries.size)
    }

    @Test
    fun castConnectionStateOrdinals() {
        assertEquals(0, CastConnectionState.NONE.ordinal)
        assertEquals(1, CastConnectionState.NO_DEVICES_AVAILABLE.ordinal)
        assertEquals(2, CastConnectionState.NOT_CONNECTED.ordinal)
        assertEquals(3, CastConnectionState.CONNECTING.ordinal)
        assertEquals(4, CastConnectionState.CONNECTED.ordinal)
        assertEquals(5, CastConnectionState.entries.size)
    }

    @Test
    fun trackTypeOrdinals() {
        assertEquals(0, TrackType.AUDIO.ordinal)
        assertEquals(1, TrackType.TEXT.ordinal)
        assertEquals(2, TrackType.VIDEO.ordinal)
        assertEquals(3, TrackType.entries.size)
    }

    @Test
    fun downloadStatusOrdinals() {
        assertEquals(0, DownloadStatus.DOWNLOADING.ordinal)
        assertEquals(1, DownloadStatus.PAUSED.ordinal)
        assertEquals(2, DownloadStatus.FINISHED.ordinal)
        assertEquals(3, DownloadStatus.FAILED.ordinal)
        assertEquals(4, DownloadStatus.QUEUED.ordinal)
        assertEquals(5, DownloadStatus.REMOVING.ordinal)
        assertEquals(6, DownloadStatus.entries.size)
    }

    /**
     * Pigeon's generated `index` field is what actually goes on the wire. It is
     * assigned from declaration order, so it should always track `ordinal` — but
     * they are two independent pieces of codegen, so pin them to each other.
     */
    @Test
    fun wireIndexMatchesOrdinal() {
        PlaybackState.entries.forEach { assertEquals(it.ordinal, it.index) }
        TrackType.entries.forEach { assertEquals(it.ordinal, it.index) }
        CastConnectionState.entries.forEach { assertEquals(it.ordinal, it.index) }
        BufferMode.entries.forEach { assertEquals(it.ordinal, it.index) }
        RepeatMode.entries.forEach { assertEquals(it.ordinal, it.index) }
        DownloadStatus.entries.forEach { assertEquals(it.ordinal, it.index) }
    }
}
