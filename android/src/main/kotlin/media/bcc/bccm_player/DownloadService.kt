package media.bcc.bccm_player

import android.app.Notification
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadManager
import androidx.media3.exoplayer.offline.DownloadNotificationHelper
import androidx.media3.exoplayer.offline.DownloadService
import androidx.media3.exoplayer.scheduler.Scheduler


private const val JOB_ID = 1
private const val FOREGROUND_NOTIFICATION_ID = 1
const val DOWNLOAD_NOTIFICATION_CHANNEL_ID = "download_channel"

class DownloadService : DownloadService(
    FOREGROUND_NOTIFICATION_ID,
    DEFAULT_FOREGROUND_NOTIFICATION_UPDATE_INTERVAL,
    DOWNLOAD_NOTIFICATION_CHANNEL_ID,
    R.string.exo_download_notification_channel_name,
    0
) {
    override fun getDownloadManager(): DownloadManager {
        return Downloader.getOrCreateDownloadManager(applicationContext)
    }

    override fun getScheduler(): Scheduler? {
        return null
    }

    override fun getForegroundNotification(
        downloads: MutableList<Download>,
        notMetRequirements: Int
    ): Notification {
        return DownloadNotificationHelper(
            this,
            DOWNLOAD_NOTIFICATION_CHANNEL_ID
        ).buildProgressNotification(
            this,
            android.R.drawable.stat_sys_download_done,
            null,  //                TODO: accept custom message?
            null,
            downloads
        )
    }
}