package media.bcc.bccm_player

import android.content.Context
import android.net.Uri
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
import androidx.media3.exoplayer.offline.DownloadRequest
import kotlinx.parcelize.Parcelize
import kotlinx.parcelize.parcelableCreator
import media.bcc.bccm_player.pigeon.DownloaderApi
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi
import java.io.File
import java.io.IOException
import java.util.LinkedList
import java.util.UUID
import java.util.concurrent.Executor


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

class Downloader(private val context: Context) {
    private val downloadManager: DownloadManager = createDownloadManager(context)

    fun startDownload(config: DownloaderApi.DownloadConfig): DownloaderApi.Download {
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

        downloadHelper.prepare(object : DownloadHelper.Callback {
            override fun onPrepared(helper: DownloadHelper) {
                val request = helper.getDownloadRequest(
                    key,
                    ParcelMarshall.pack(
                        DownloadInfo(title = config.title, additionalData = config.additionalData)
                    )
                )

                androidx.media3.exoplayer.offline.DownloadService.sendAddDownload(
                    context,
                    DownloadService::class.java,
                    request,
                    false
                )
            }

            override fun onPrepareError(helper: DownloadHelper, e: IOException) {
                TODO("Not yet implemented")
            }
        })

        return DownloaderApi.Download.Builder()
            .setKey(key)
            .setConfig(config)
            .setIsFinished(false)
            .build()
    }

    fun getDownloads(): List<DownloaderApi.Download> {
        val downloads: MutableList<DownloaderApi.Download> = LinkedList<DownloaderApi.Download>()

        val downloadCursor = downloadManager.downloadIndex.getDownloads()

        if (downloadCursor.moveToFirst()) {
            do {
                downloads.add(downloadCursor.download.toDownloaderApiModel())
            } while (downloadCursor.moveToNext())
        }

        downloadManager.resumeDownloads()

        return downloads
    }

    fun getDownloadStatus(downloadKey: String): Double {
        val download = downloadManager.currentDownloads
            .firstOrNull { it.request.id == downloadKey }
            ?: return 0.0
        downloadManager.resumeDownloads()
        val progress = download.percentDownloaded.toDouble() / 100
        return progress
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
                .setTracks(emptyList<DownloaderApi.DownloaderTrack?>().toMutableList())
                .setAdditionalData(emptyMap<String?, String?>().toMutableMap())
                .build()
        )
        .setIsFinished(state == Download.STATE_COMPLETED)
        .build()
}