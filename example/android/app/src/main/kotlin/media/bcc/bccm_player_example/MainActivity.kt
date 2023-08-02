package media.bcc.bccm_player_example

import android.annotation.SuppressLint
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterFragmentActivity
import media.bcc.bccm_player.BccmPlayerPlugin

class MainActivity : FlutterFragmentActivity() {
    @SuppressLint("MissingSuperCall")
    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        val bccmPlayer =
            flutterEngine?.plugins?.get(BccmPlayerPlugin::class.javaObjectType) as BccmPlayerPlugin?
        bccmPlayer?.handleOnPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
    }

    override fun onBackPressed() {
        if (!BccmPlayerPlugin.handleOnBackPressed(this)) {
            super.onBackPressed()
        }
    }
}