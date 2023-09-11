package media.bcc.bccm_player

import android.content.Context
import android.os.Parcel
import android.os.Parcelable
import androidx.media3.common.MediaItem
import androidx.media3.database.StandaloneDatabaseProvider
import androidx.media3.datasource.DefaultDataSourceFactory
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.cache.NoOpCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadHelper
import androidx.media3.exoplayer.offline.DownloadManager
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.isActive
import kotlinx.parcelize.Parcelize
import kotlinx.parcelize.parcelableCreator
import media.bcc.bccm_player.pigeon.DownloaderApi
import media.bcc.bccm_player.pigeon.DownloaderApi.DownloadStatusChangedEvent
import java.io.File
import java.io.IOException
import java.util.LinkedList
import java.util.UUID
import java.util.concurrent.Executor
import kotlin.coroutines.suspendCoroutine


private const val DOWNLOAD_FOLDER_NAME = "downloads"

var cache: SimpleCache? = null

fun createDownloadManager(context: Context): DownloadManager {
    val databaseProvider = StandaloneDatabaseProvider(context)
    val cacheDir = File(context.filesDir, DOWNLOAD_FOLDER_NAME)
    if (cache == null) {
        cache = SimpleCache(cacheDir, NoOpCacheEvictor(), databaseProvider)
    }
    val dataSourceFactory = DefaultHttpDataSource.Factory()
    val downloadExecutor = Executor(Runnable::run)
    return DownloadManager(context, databaseProvider, cache!!, dataSourceFactory, downloadExecutor)
}

@Parcelize
data class DownloadInfo(
    val title: String,
    val audioTrackIds: List<String>,
    val videoTrackIds: List<String>,
    val additionalData: Map<String, String>
) : Parcelable

object ParcelMarshall {
    fun <T> pack(input: T): ByteArray where T : Parcelable {
        val dataParcel = Parcel.obtain()
        input.writeToParcel(dataParcel, 0)
        val data = dataParcel.marshall()
        dataParcel.recycle()
        return data
    }

    fun <T> unpack(byteArray: ByteArray, creator: Parcelable.Creator<T>): T where T : Parcelable {
        val dataParcel = Parcel.obtain()
        dataParcel.unmarshall(byteArray, 0, byteArray.size)
        dataParcel.setDataPosition(0)
        val result = creator.createFromParcel(dataParcel)
        dataParcel.recycle()
        return result
    }
}

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

class DownloadProgress(
    private val downloads: MutableMap<String, DownloaderApi.Download> = mutableMapOf(),
    private val progress: MutableMap<String, Double> = mutableMapOf()
) {
    fun add(download: DownloaderApi.Download, initialProgress: Double) {
        downloads[download.key] = download
        progress[download.key] = initialProgress
    }

    fun set(id: String, newProgress: Double): DownloadStatusChangedEvent? {
        val download = downloads[id] ?: throw Exception("Unknown download key $id") // TODO: Better exception
        val currentProgress = progress[id] ?: throw Exception("Unknown download key $id") // TODO: Better exception

        if (newProgress >= 1.0) {
            download.isFinished = true
        }

        if (currentProgress != newProgress) {
            return null
        }

        progress[id] = newProgress

        return DownloadStatusChangedEvent.Builder()
            .setDownload(download)
            .setProgress(newProgress)
            .build()
    }
}

class Downloader(private val context: Context) {
    private val downloadManager: DownloadManager = createDownloadManager(context)
    private val progress = DownloadProgress()

    init {
        downloads().forEach {
            progress.add(it.toDownloaderApiModel(), it.percentDownloaded.toDouble() / 100)
        }
    }

    val statusChanged: Flow<DownloadStatusChangedEvent>
        get() = flow {
            while (currentCoroutineContext().isActive) {
                val downloads = downloadManager.currentDownloads.mapNotNull {
                    progress.set(it.request.id, it.percentDownloaded.toDouble() / 100)
                }
                downloadManager.resumeDownloads()
                downloads.forEach { emit(it) }
                delay(300)
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

        val request = downloadHelper.getDownloadRequest(
            key,
            ParcelMarshall.pack(
                DownloadInfo(
                    title = config.title,
                    audioTrackIds = config.audioTrackIds,
                    videoTrackIds = config.videoTrackIds,
                    additionalData = config.additionalData
                )
            )
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
            .setIsFinished(false)
            .build()
    }

    private fun downloads(): List<Download> {
        val result = emptyList<Download>().toMutableList()

        val downloadCursor = downloadManager.downloadIndex.getDownloads()

        if (downloadCursor.moveToFirst()) {
            do {
                result.add(downloadCursor.download)
            } while (downloadCursor.moveToNext())
        }

        downloadManager.resumeDownloads()

        return result
    }

    fun getDownloads() = downloads().map { it.toDownloaderApiModel() }

    fun getDownloadStatus(downloadKey: String): Double {
        val download = downloadManager.currentDownloads.firstOrNull { it.request.id == downloadKey }
        downloadManager.resumeDownloads()
        if (download != null) {
            val progress = download.percentDownloaded.toDouble() / 100
            return progress
        } else {
            return 0.0
        }
    }

    fun removeDownload(key: String) {
        androidx.media3.exoplayer.offline.DownloadService.sendRemoveDownload(
            context,
            DownloadService::class.java,
            key,
            false
        )
    }
}

fun Download.toDownloaderApiModel(): DownloaderApi.Download {
    val downloadInfo = try {
        ParcelMarshall.unpack<DownloadInfo>(request.data, parcelableCreator())
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
        .setIsFinished(state == Download.STATE_COMPLETED)
        .build()
}