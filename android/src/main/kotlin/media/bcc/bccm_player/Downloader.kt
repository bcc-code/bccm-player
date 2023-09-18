package media.bcc.bccm_player

import android.content.Context
import androidx.media3.common.C.TRACK_TYPE_TEXT
import androidx.media3.common.MediaItem
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.TrackSelectionParameters
import androidx.media3.database.StandaloneDatabaseProvider
import androidx.media3.datasource.DefaultDataSourceFactory
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.cache.NoOpCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadHelper
import androidx.media3.exoplayer.offline.DownloadManager
import androidx.media3.exoplayer.scheduler.Requirements
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import media.bcc.bccm_player.pigeon.DownloaderApi
import media.bcc.bccm_player.pigeon.DownloaderApi.DownloadFailedEvent
import media.bcc.bccm_player.pigeon.DownloaderApi.DownloadRemovedEvent
import media.bcc.bccm_player.pigeon.DownloaderApi.DownloadStatus
import media.bcc.bccm_player.pigeon.DownloaderApi.DownloadChangedEvent
import java.io.File
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executor
import kotlin.coroutines.suspendCoroutine

const val DOWNLOADED_URL_SCHEME = "downloaded://";

@Serializable
data class DownloadInfo(
    val title: String,
    val audioTrackIds: List<String>,
    val videoTrackIds: List<String>,
    val additionalData: Map<String, String>
)

suspend fun DownloadHelper.prepare() {
    suspendCoroutine { cont ->
        prepare(object : DownloadHelper.Callback {
            override fun onPrepared(helper: DownloadHelper) {
                cont.resumeWith(Result.success(Unit))
            }

            override fun onPrepareError(helper: DownloadHelper, e: IOException) {
                cont.resumeWith(Result.failure(e))
            }
        })
    }
}

class Downloader(
    private val context: Context,
    private val pigeon: DownloaderApi.DownloaderListenerPigeon
) : DownloadManager.Listener {

    companion object {
        private const val DOWNLOAD_FOLDER_NAME = "downloads"
        private var cache: SimpleCache? = null
        private var downloadManager: DownloadManager? = null

        fun getOrCreateDownloadManager(context: Context): DownloadManager {
            downloadManager = downloadManager ?: createDownloadManager(context)
            return downloadManager!!
        }

        fun getDownloadManager(): DownloadManager {
            return downloadManager!!;
        }

        fun getCache(): SimpleCache {
            return cache!!;
        }

        private fun createDownloadManager(context: Context): DownloadManager {
            val databaseProvider = StandaloneDatabaseProvider(context)
            val cacheDir = File(context.filesDir, DOWNLOAD_FOLDER_NAME)
            if (cache == null) {
                cache = SimpleCache(cacheDir, NoOpCacheEvictor(), databaseProvider)
            }
            val dataSourceFactory = DefaultHttpDataSource.Factory()
            val downloadExecutor = Executor(Runnable::run)
            return DownloadManager(
                context,
                databaseProvider,
                cache!!,
                dataSourceFactory,
                downloadExecutor
            )
        }
    }

    private val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    init {
        getOrCreateDownloadManager(context).addListener(this)

        mainScope.launch {
            statusChanged.collect {
                pigeon.onDownloadStatusChanged(it) {}
            }
        }
    }

    override fun onDownloadRemoved(downloadManager: DownloadManager, download: Download) {
        pigeon.onDownloadRemoved(
            DownloadRemovedEvent.Builder()
                .setKey(download.request.id)
                .build()
        ) {}
    }

    override fun onDownloadChanged(
        downloadManager: DownloadManager,
        download: Download,
        finalException: java.lang.Exception?
    ) {
        if (finalException != null) {
            pigeon.onDownloadFailed(
                DownloadFailedEvent.Builder()
                    .setKey(download.request.id)
                    .setError(finalException.message + ", " + finalException.stackTraceToString())
                    .build()
            ) {}
            return
        }
        pigeon.onDownloadStatusChanged(
            DownloadChangedEvent.Builder()
                .setDownload(download.toDownloaderApiModel())
                .build()
        ) {}
    }

    val statusChanged: Flow<DownloadChangedEvent>
        get() = flow {
            while (currentCoroutineContext().isActive) {
                val downloads = getDownloadManager().currentDownloads.map {
                    DownloadChangedEvent.Builder()
                        .setDownload(it.toDownloaderApiModel())
                        .build()
                }
                getDownloadManager().resumeDownloads()
                downloads.forEach { emit(it) }
                delay(1000)
            }
        }

    suspend fun startDownload(config: DownloaderApi.DownloadConfig): DownloaderApi.Download {
        val key = UUID.randomUUID().toString()

        val mediaItem = MediaItem.Builder()
            .setUri(config.url)
            .setMimeType(config.mimeType)
            .build()

        val downloadHelper = DownloadHelper.forMediaItem(
            context,
            mediaItem,
            DefaultRenderersFactory(context),
            DefaultDataSourceFactory(context)
        )

        downloadHelper.prepare()
        downloadHelper.clearTrackSelections(0)

        val tracks = downloadHelper.getTracks(0)
        for (group in tracks.groups.filter { it.length > 0 }) {
            for (i in 0 until group.length) {
                val format = group.getTrackFormat(i);
                if (group.type == TRACK_TYPE_TEXT
                    || config.audioTrackIds.contains(format.id)
                    || config.videoTrackIds.contains(format.id)
                ) {
                    downloadHelper.addTrackSelection(
                        0,
                        TrackSelectionParameters.Builder(context)
                            .addOverride(TrackSelectionOverride(group.mediaTrackGroup, i))
                            .build()
                    )
                }
            }
        }


        val request = downloadHelper.getDownloadRequest(
            key,
            Json.encodeToString(
                DownloadInfo(
                    title = config.title,
                    audioTrackIds = config.audioTrackIds,
                    videoTrackIds = config.videoTrackIds,
                    additionalData = config.additionalData
                )
            ).toByteArray()
        )
        androidx.media3.exoplayer.offline.DownloadService.sendAddDownload(
            context,
            DownloadService::class.java,
            request,
            false
        )

        return DownloaderApi.Download.Builder()
            .setKey(key)
            .setConfig(config)
            .setFractionDownloaded(0.0)
            .setOfflineUrl(DOWNLOADED_URL_SCHEME + request.id)
            .setStatus(DownloadStatus.QUEUED)
            .build()
    }

    private fun downloads(): List<Download> {
        val result = emptyList<Download>().toMutableList()

        val downloadCursor =
            getDownloadManager().downloadIndex.getDownloads()

        if (downloadCursor.moveToFirst()) {
            do {
                result.add(downloadCursor.download)
            } while (downloadCursor.moveToNext())
        }

        getDownloadManager().resumeDownloads()

        return result
    }

    fun getDownloads() = downloads().map { it.toDownloaderApiModel() }


    fun getDownloadStatus(downloadKey: String): Double {
        var download =
            getDownloadManager().currentDownloads.firstOrNull { it.request.id == downloadKey }
        if (download == null) {
            download = getDownloadManager().downloadIndex.getDownload(downloadKey)
        }
        getDownloadManager().resumeDownloads()

        if (download != null) {
            return download.percentDownloaded.toDouble() / 100
        } else {
            return 0.0
        }
    }

    override fun onRequirementsStateChanged(
        downloadManager: DownloadManager,
        requirements: Requirements,
        notMetRequirements: Int
    ) {
        super.onRequirementsStateChanged(downloadManager, requirements, notMetRequirements)
    }

    fun removeDownload(key: String) {
        androidx.media3.exoplayer.offline.DownloadService.sendRemoveDownload(
            context,
            DownloadService::class.java,
            key,
            true
        )
    }
}

fun Download.toDownloaderApiModel(): DownloaderApi.Download {
    val downloadInfo = try {
        Json.decodeFromString<DownloadInfo>(String(request.data))
    } catch (e: Exception) {
        null
    }

    return DownloaderApi.Download.Builder()
        .setKey(request.id)
        .setConfig(
            DownloaderApi.DownloadConfig.Builder()
                .setUrl(request.uri.toString())
                .setMimeType(request.mimeType!!)
                .setTitle(downloadInfo?.title ?: "-")
                .setAudioTrackIds(downloadInfo?.audioTrackIds ?: emptyList<String>())
                .setVideoTrackIds(downloadInfo?.videoTrackIds ?: emptyList<String>())
                .setAdditionalData(
                    downloadInfo?.additionalData ?: emptyMap<String?, String?>().toMutableMap()
                )
                .build()
        )
        .setFractionDownloaded(percentDownloaded.toDouble() / 100)
        .setOfflineUrl(DOWNLOADED_URL_SCHEME + request.id)
        .setStatus(toApiDownloadStatus(state))
        .build()
}

// map between DownloadStatus and Download.STATE_*
fun toApiDownloadStatus(state: Int): DownloadStatus {
    return when (state) {
        Download.STATE_DOWNLOADING -> DownloadStatus.DOWNLOADING
        Download.STATE_STOPPED -> DownloadStatus.PAUSED
        Download.STATE_REMOVING -> DownloadStatus.REMOVING
        Download.STATE_COMPLETED -> DownloadStatus.FINISHED
        Download.STATE_FAILED -> DownloadStatus.FAILED
        else -> DownloadStatus.PAUSED
    }
}