package media.bcc.bccm_player.utils

import android.content.Context
import androidx.core.performance.DevicePerformance
import androidx.core.performance.play.services.PlayServicesDevicePerformance

object DevicePerformanceManager {
    @Volatile
    private var instance: DevicePerformance? = null

    fun getInstance(context: Context): DevicePerformance? {
        return instance ?: synchronized(this) {
            instance ?: run {
                try {
                    PlayServicesDevicePerformance(context).also { instance = it }
                } catch (e: Exception) {
                    null
                }
            }
        }
    }
}
