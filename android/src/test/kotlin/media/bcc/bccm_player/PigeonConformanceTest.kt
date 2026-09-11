package media.bcc.bccm_player

import media.bcc.bccm_player.pigeon.DownloaderApi
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Guards on the shape of the Pigeon-generated Kotlin/Java APIs.
 *
 * Pigeon has silently reshaped these before: v22 -> v28 moved the *Swift*
 * `@async` host APIs from completion handlers to `async throws`, which broke
 * every hand-written iOS implementation without a single Dart test noticing.
 * Android happened to be spared that one, but nothing in `flutter analyze` or
 * `flutter test` compiles Kotlin either, so the same class of break would reach
 * consumers unchallenged.
 *
 * Most of the value is in whether this file *compiles* alongside the main
 * sources — a `DownloaderApiImpl` that no longer satisfies `DownloaderPigeon`
 * fails the Gradle test task before any assertion runs. The reflective checks
 * additionally pin the callback style, which a compile would not notice if
 * codegen swapped `Result<T>` for something else and the impl were regenerated
 * with it.
 */
class PigeonConformanceTest {

    @Test
    fun downloaderApiImplImplementsGeneratedInterface() {
        assertTrue(
            DownloaderApi.DownloaderPigeon::class.java
                .isAssignableFrom(DownloaderApiImpl::class.java),
        )
    }

    @Test
    fun playbackApiImplImplementsGeneratedInterface() {
        assertTrue(
            PlaybackPlatformApi.PlaybackPlatformPigeon::class.java
                .isAssignableFrom(PlaybackApiImpl::class.java),
        )
    }

    /**
     * The downloader host API stays callback-based on Android, with the
     * result type varying by nullability. `getMethod` throws if any signature
     * drifts.
     */
    @Test
    fun downloaderHostApiUsesResultCallbacks() {
        val api = DownloaderApi.DownloaderPigeon::class.java

        assertEquals(
            Void.TYPE,
            api.getMethod(
                "startDownload",
                DownloaderApi.DownloadConfig::class.java,
                DownloaderApi.Result::class.java,
            ).returnType,
        )
        api.getMethod("getDownloadStatus", String::class.java, DownloaderApi.Result::class.java)
        api.getMethod("getDownloads", DownloaderApi.Result::class.java)
        // Nullable return -> NullableResult, void return -> VoidResult. These
        // three interfaces are easy to conflate and a swap compiles fine on the
        // Dart side.
        api.getMethod("getDownload", String::class.java, DownloaderApi.NullableResult::class.java)
        api.getMethod("removeDownload", String::class.java, DownloaderApi.VoidResult::class.java)
        api.getMethod("getFreeDiskSpace", DownloaderApi.Result::class.java)
    }
}
