package media.bcc.bccm_player.utils

import android.content.Context
import android.graphics.Paint
import android.graphics.Rect
import android.os.Build
import android.util.AttributeSet
import android.widget.LinearLayout


class SystemGestureExcludedLinearLayout : LinearLayout {
    private var exclusionRect: Rect = Rect()
    private var exclusionRects: ArrayList<Rect> = ArrayList()
    private var excludeEnabled: Boolean = true

    constructor(context: Context?) : super(context)

    constructor(context: Context?, attrs: AttributeSet?) : super(context, attrs)

    constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int) : super(
        context,
        attrs,
        defStyleAttr
    )

    fun setExclusionEnabled(enabled: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (!enabled) {
                excludeEnabled = false
                exclusionRects.clear()
                systemGestureExclusionRects = exclusionRects
            } else {
                excludeEnabled = true
                forceLayout()
            }
        }
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        super.onLayout(changed, left, top, right, bottom)

        if (!excludeEnabled) {
            return
        }

        // Set the system gesture exclusion rects for the LinearLayout
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            exclusionRect.set(left, top, right, bottom);
            exclusionRects.clear();
            exclusionRects.add(exclusionRect);
            systemGestureExclusionRects = exclusionRects
        }
    }
}