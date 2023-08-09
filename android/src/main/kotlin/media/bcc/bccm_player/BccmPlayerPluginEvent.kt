package media.bcc.bccm_player

import android.app.Activity
import androidx.lifecycle.Lifecycle

interface BccmPlayerPluginEvent

class AttachedToActivityEvent(val activity: Activity) : BccmPlayerPluginEvent
class DetachedFromActivityEvent : BccmPlayerPluginEvent
class SetPlayerViewVisibilityEvent(val viewId: Long, val visible: Boolean) :
    BccmPlayerPluginEvent

class PictureInPictureModeChangedEvent(
    val isInPictureInPictureMode: Boolean,
    val lifecycleState: Lifecycle.State
) :
    BccmPlayerPluginEvent
