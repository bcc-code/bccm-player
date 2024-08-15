package media.bcc.bccm_player.utils

import media.bcc.bccm_player.pigeon.ChromecastControllerPigeon
import media.bcc.bccm_player.pigeon.DownloaderApi
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi

/**
 * Response handler for calls to Dart that don't require any error handling, such as event
 * notifications where if the Dart side has been torn down, silently dropping the message is the
 * desired behavior.
 *
 *
 * Longer term, any call using this is likely a good candidate to migrate to event channels.
 */
class NoOpVoidResult : PlaybackPlatformApi.VoidResult {
    override fun success() {}
    override fun error(error: Throwable) {}
}

class DownloaderApiNoOpVoidResult : DownloaderApi.VoidResult {
    override fun success() {}
    override fun error(error: Throwable) {}
}

class ChromecastNoOpVoidResult : ChromecastControllerPigeon.VoidResult {
    override fun success() {}
    override fun error(error: Throwable) {}
}