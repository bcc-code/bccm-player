package media.bcc.bccm_player

import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadProgress
import androidx.media3.exoplayer.offline.DownloadRequest
import androidx.media3.common.C
import android.net.Uri
import media.bcc.bccm_player.pigeon.DownloaderApi.DownloadStatus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Maps media3's [Download] onto the pigeon model the Dart side consumes.
 *
 * Everything here is a silent-degradation path: the `DownloadInfo` payload is
 * decoded inside a `try/catch` that falls back to placeholder values, and the
 * status/progress conversions have no error case at all. Nothing crashes when
 * one of them is wrong — a download just shows up with the wrong title, the
 * wrong state, or impossible progress.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class DownloadMappingTest {

    // MARK: Status

    @Test
    fun mapsEveryMedia3State() {
        assertEquals(DownloadStatus.DOWNLOADING, toApiDownloadStatus(Download.STATE_DOWNLOADING))
        assertEquals(DownloadStatus.PAUSED, toApiDownloadStatus(Download.STATE_STOPPED))
        assertEquals(DownloadStatus.REMOVING, toApiDownloadStatus(Download.STATE_REMOVING))
        assertEquals(DownloadStatus.FINISHED, toApiDownloadStatus(Download.STATE_COMPLETED))
        assertEquals(DownloadStatus.FAILED, toApiDownloadStatus(Download.STATE_FAILED))
    }

    /**
     * Documents current behaviour, which is worth a second look: media3's
     * `STATE_QUEUED` falls through to `PAUSED`, even though [DownloadStatus.QUEUED]
     * exists and `Downloader.startDownload` reports exactly that for the same
     * conceptual state. A download therefore reads QUEUED when created and PAUSED
     * once DownloadManager reports back on it.
     */
    @Test
    fun queuedIsReportedAsPaused() {
        assertEquals(DownloadStatus.PAUSED, toApiDownloadStatus(Download.STATE_QUEUED))
        assertEquals(DownloadStatus.PAUSED, toApiDownloadStatus(Download.STATE_RESTARTING))
    }

    @Test
    fun unknownStateFallsBackToPaused() {
        assertEquals(DownloadStatus.PAUSED, toApiDownloadStatus(9999))
    }

    // MARK: Model

    @Test
    fun mapsRequestAndProgress() {
        val model = download(
            state = Download.STATE_DOWNLOADING,
            percentDownloaded = 42f,
            data = """{"title":"Episode 1","audioTrackIds":["no"],"videoTrackIds":["720"],"additionalData":{"k":"v"}}""",
        ).toDownloaderApiModel()

        assertEquals("download-1", model.key)
        assertEquals(CONTENT_URL, model.config.url)
        assertEquals("application/x-mpegURL", model.config.mimeType)
        assertEquals("Episode 1", model.config.title)
        assertEquals(listOf("no"), model.config.audioTrackIds)
        assertEquals(listOf("720"), model.config.videoTrackIds)
        assertEquals(mapOf("k" to "v"), model.config.additionalData)
        assertEquals("downloaded://download-1", model.offlineUrl)
        assertEquals(0.42, model.fractionDownloaded, 0.0001)
        assertEquals(DownloadStatus.DOWNLOADING, model.status)
        assertNull(model.error)
    }

    /**
     * The `DownloadInfo` payload is our own JSON inside media3's opaque
     * `request.data`. A decode failure is swallowed, so a schema change silently
     * degrades every existing download to a "-" title with no tracks rather than
     * failing loudly. Pinning it means a change to [DownloadInfo] has to be a
     * deliberate one.
     */
    @Test
    fun undecodableDownloadInfoDegradesToPlaceholders() {
        val model = download(data = "not json at all").toDownloaderApiModel()

        assertEquals("-", model.config.title)
        assertEquals(emptyList<String>(), model.config.audioTrackIds)
        assertEquals(emptyList<String>(), model.config.videoTrackIds)
        assertEquals(emptyMap<String, String>(), model.config.additionalData)
        // The parts that come from the request itself still survive.
        assertEquals("download-1", model.key)
        assertEquals(CONTENT_URL, model.config.url)
    }

    /**
     * media3 reports `C.PERCENTAGE_UNSET` (-1) while no estimate is available —
     * `SegmentDownloader` does exactly this for HLS until the content length is
     * known. Dividing by 100 turns that into -0.01, so `fractionDownloaded` is
     * briefly negative rather than 0. Nothing in the plugin clamps it.
     */
    @Test
    fun unknownProgressBecomesNegativeFraction() {
        val model = download(percentDownloaded = C.PERCENTAGE_UNSET.toFloat()).toDownloaderApiModel()

        assertEquals(-0.01, model.fractionDownloaded, 0.0001)
    }

    @Test
    fun completedDownloadIsFullyDownloaded() {
        val model = download(state = Download.STATE_COMPLETED, percentDownloaded = 100f)
            .toDownloaderApiModel()

        assertEquals(1.0, model.fractionDownloaded, 0.0001)
        assertEquals(DownloadStatus.FINISHED, model.status)
        assertNull(model.error)
    }

    /** The real failure reason is dropped; only failed downloads carry any error. */
    @Test
    fun onlyFailedDownloadsCarryAnError() {
        val failed = download(
            state = Download.STATE_FAILED,
            failureReason = Download.FAILURE_REASON_UNKNOWN,
        ).toDownloaderApiModel()

        assertEquals(DownloadStatus.FAILED, failed.status)
        assertEquals("Unknown error", failed.error)
    }

    // MARK: Fixtures

    private fun download(
        state: Int = Download.STATE_DOWNLOADING,
        percentDownloaded: Float = 0f,
        data: String = """{"title":"Episode 1","audioTrackIds":[],"videoTrackIds":[],"additionalData":{}}""",
        failureReason: Int = Download.FAILURE_REASON_NONE,
    ): Download {
        val request = DownloadRequest.Builder("download-1", Uri.parse(CONTENT_URL))
            .setMimeType("application/x-mpegURL")
            .setData(data.toByteArray())
            .build()
        val progress = DownloadProgress().apply { this.percentDownloaded = percentDownloaded }
        return Download(request, state, 0L, 0L, C.LENGTH_UNSET.toLong(), 0, failureReason, progress)
    }

    companion object {
        private const val CONTENT_URL = "https://example.com/stream.m3u8"
    }
}
