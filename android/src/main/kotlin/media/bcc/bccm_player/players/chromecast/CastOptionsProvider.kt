package media.bcc.bccm_player.players.chromecast

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider
import com.google.android.gms.cast.framework.media.CastMediaOptions


@Suppress("unused")
class CastOptionsProvider : OptionsProvider {
    override fun getCastOptions(context: Context): CastOptions {
        val mediaOptions = CastMediaOptions.Builder()
            .setExpandedControllerActivityClassName(CastExpandedControlsActivity::class.java.name)
            .build()
        val metaData = context.packageManager.getApplicationInfo(
            context.packageName,
            PackageManager.GET_META_DATA
        ).metaData
        val appId = metaData?.getString("cast_app_id")

        val builder = CastOptions.Builder();
        if (appId != null) {
            builder.setReceiverApplicationId(appId);
        }
        builder.setCastMediaOptions(mediaOptions)
        return builder.build()
    }

    override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? {
        return null
    }
}