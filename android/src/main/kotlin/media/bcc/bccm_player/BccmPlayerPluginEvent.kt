package media.bcc.bccm_player

import android.app.Activity
import androidx.lifecycle.Lifecycle
import media.bcc.bccm_player.pigeon.playback.PictureInPictureModeChangedEvent

sealed class BccmPlayerPluginEvent {
    data class PictureInPictureModeChangedEvent(
        val isInPictureInPictureMode: Boolean,
        val lifecycleState: Lifecycle.State
    ) : BccmPlayerPluginEvent()

    data class AttachedToActivityEvent(val activity: Activity) : BccmPlayerPluginEvent()

}
