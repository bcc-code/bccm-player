package media.bcc.bccm_player.utils

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.os.Build
import android.view.SurfaceHolder
import android.view.SurfaceView
import androidx.annotation.RequiresApi

class EmptySurfaceView(context: Context?) : SurfaceView(context), SurfaceHolder.Callback {
    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {}

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    override fun surfaceCreated(holder: SurfaceHolder) {
        var canvas: Canvas? = null
        try {
            canvas = holder.lockCanvas(null)
            synchronized(holder) {
                canvas?.drawColor(Color.RED)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            if (canvas != null) {
                holder.unlockCanvasAndPost(canvas)
            }
        }
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        // TODO Auto-generated method stub
    }

    init {
        holder.addCallback(this)
    }
}