package media.bcc.bccm_player.players.exoplayer

import android.app.Activity
import android.os.Looper
import android.view.WindowManager
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.PlayerView
import media.bcc.bccm_player.BccmPlayerPluginSingleton
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.BufferMode
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.time.Duration

/** The screen stays on for the player that is rendering, and for that player only. */
@UnstableApi
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ExoPlayerControllerScreenOnTest {
    private val activity: Activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    private val controllers = mutableListOf<ExoPlayerController>()

    @Before
    fun setUp() {
        BccmPlayerPluginSingleton.activityState.value = activity
    }

    @After
    fun tearDown() {
        controllers.forEach { it.release() }
        BccmPlayerPluginSingleton.activityState.value = null
    }

    @Test
    fun `attached player view holds the screen on`() {
        val controller = newController()
        val view = newPlayerView()

        controller.takeOwnership(view, FakeViewController())

        assertTrue(view.keepScreenOn)
    }

    @Test
    fun `released player view stops holding the screen on`() {
        val controller = newController()
        val view = newPlayerView()
        controller.takeOwnership(view, FakeViewController())

        controller.releasePlayerView(view)

        assertFalse(view.keepScreenOn)
    }

    @Test
    fun `handing over to a new view moves the hold`() {
        val controller = newController()
        val inline = newPlayerView()
        val fullscreen = newPlayerView()
        controller.takeOwnership(inline, FakeViewController())

        controller.takeOwnership(fullscreen, FakeViewController())

        assertFalse(inline.keepScreenOn)
        assertTrue(fullscreen.keepScreenOn)
    }

    @Test
    fun `releasing a view that already lost ownership leaves the current one holding`() {
        val controller = newController()
        val inline = newPlayerView()
        val fullscreen = newPlayerView()
        controller.takeOwnership(inline, FakeViewController())
        controller.takeOwnership(fullscreen, FakeViewController())

        controller.releasePlayerView(inline)
        advancePastDetachGracePeriod()

        assertTrue(fullscreen.keepScreenOn)
    }

    @Test
    fun `one player detaching leaves another player holding`() {
        val detaching = newController()
        val playing = newController()
        val detachingView = newPlayerView()
        val playingView = newPlayerView()
        detaching.takeOwnership(detachingView, FakeViewController())
        playing.takeOwnership(playingView, FakeViewController())

        detaching.releasePlayerView(detachingView)
        advancePastDetachGracePeriod()

        assertFalse(detachingView.keepScreenOn)
        assertTrue(playingView.keepScreenOn)
    }

    @Test
    fun `detaching does not clear a keep screen on flag set by someone else`() {
        activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        val controller = newController()
        val view = newPlayerView()
        controller.takeOwnership(view, FakeViewController())

        controller.releasePlayerView(view)
        advancePastDetachGracePeriod()

        val flags = activity.window.attributes.flags
        assertTrue(flags and WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON != 0)
    }

    private fun newController() =
        ExoPlayerController(activity, BufferMode.STANDARD, disableNpaw = true)
            .also { controllers.add(it) }

    private fun newPlayerView() = PlayerView(activity)

    private fun advancePastDetachGracePeriod() {
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(7))
    }

    private class FakeViewController : BccmPlayerViewController {
        override val isFullscreen = false
        override val shouldPipAutomatically = false
        override fun enterPictureInPicture() {}
    }
}
