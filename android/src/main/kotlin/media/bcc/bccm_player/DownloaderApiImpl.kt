package media.bcc.bccm_player

import android.os.Environment
import android.os.StatFs
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import media.bcc.bccm_player.pigeon.DownloaderApi
import media.bcc.bccm_player.pigeon.downloader.DownloaderPigeon

class DownloaderApiImpl(private val downloader: Downloader) : DownloaderPigeon {
    private val scope = CoroutineScope(Dispatchers.Main)

    override fun startDownload(
        downloadConfig: DownloaderApi.DownloadConfig,
        result: DownloaderApi.Result<DownloaderApi.Download>
    ) {
        scope.launch {
            try {
                result.success(downloader.startDownload(downloadConfig))
            } catch (e: Exception) {
                result.error(e)
            }
        }
    }

    override fun getDownloadStatus(downloadKey: String, result: DownloaderApi.Result<Double>) {
        result.success(downloader.getDownloadStatus(downloadKey))
    }

    override fun getDownloads(result: DownloaderApi.Result<MutableList<DownloaderApi.Download>>) {
        result.success(downloader.getDownloads().toMutableList())
    }

    override fun getDownload(
        downloadKey: String,
        result: DownloaderApi.Result<DownloaderApi.Download>
    ) {
    }

    override fun removeDownload(downloadKey: String, result: DownloaderApi.Result<Void>) {
        downloader.removeDownload(downloadKey)
        result.success(null)
    }

    override fun getFreeDiskSpace(result: DownloaderApi.Result<Double>) {
        try {
            val stat = StatFs(Environment.getExternalStorageDirectory().path)
            result.success((stat.blockSizeLong * stat.availableBlocksLong).toDouble());
        } catch (err: Error) {
            result.error(err);
        }
    }
}