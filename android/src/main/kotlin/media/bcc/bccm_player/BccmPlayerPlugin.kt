package media.bcc.bccm_player

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.res.Configuration
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.google.android.gms.cast.framework.CastContext
import com.google.common.util.concurrent.ListenableFuture
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import media.bcc.bccm_player.pigeon.ChromecastControllerPigeon
import media.bcc.bccm_player.pigeon.DownloaderApi
import media.bcc.bccm_player.pigeon.DownloaderApi.DownloaderPigeon
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.PlaybackPlatformPigeon
import media.bcc.bccm_player.views.FlutterCastButton
import media.bcc.bccm_player.views.FlutterCastPlayerView
import media.bcc.bccm_player.views.FlutterExoPlayerView
import media.bcc.bccm_player.views.FullscreenPlayerView

class BccmPlayerPlugin : FlutterPlugin, ActivityAware, PluginRegistry.UserLeaveHintListener {
    companion object {
        private var mBound = false
        private var playbackServiceCompleter = CompletableDeferred<PlaybackService>()
        private val playbackServiceConnection = object : ServiceConnection {
            override fun onServiceConnected(className: ComponentName, binder: IBinder) {
                val boundPlaybackService = (binder as PlaybackService.LocalBinder).getService()
                playbackService = boundPlaybackService;
                playbackServiceCompleter.complete(boundPlaybackService)
            }

            override fun onServiceDisconnected(arg0: ComponentName) {
                playbackService = null
            }
        }
        private var playbackService: PlaybackService? = null

        /***
         * Call this from your activity's onBackPressed.
         * This makes the back button work correctly in the native fullscreen player.
         * Returns true if the event was handled.
         */
        fun handleOnBackPressed(activity: Activity): Boolean {
            val rootLayout: FrameLayout =
                activity.window.decorView.findViewById(android.R.id.content)
            val view: View? = rootLayout.getChildAt(rootLayout.childCount - 1)
            return if (view is FullscreenPlayerView) {
                view.exit()
                true
            } else {
                false
            }
        }
    }

    private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private lateinit var controllerFuture: ListenableFuture<MediaController>
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val mainScope = CoroutineScope(Dispatchers.Main)
    var playbackPigeon: PlaybackPlatformApi.PlaybackListenerPigeon? = null
        private set
    var chromecastPigeon: ChromecastControllerPigeon.ChromecastPigeon? = null
        private set
    var downloaderPigeon: DownloaderApi.DownloaderListenerPigeon? = null
        private set

    /***
     * Should be called only by the main flutter isolate. Complete quickly, because this is awaited.
     */
    fun attach(onComplete: () -> Unit) {
        if (playbackService != null) {
            playbackService!!.attachPlugin(this@BccmPlayerPlugin);
            onComplete()
        } else {
            Log.d("bccm", "playbackService was null when attach() was run. That's ok.")
            mainScope.launch {
                try {
                    val result = withTimeoutOrNull(1000) {
                        playbackServiceCompleter.await().attachPlugin(this@BccmPlayerPlugin);
                        true
                    }
                    if (result == null) {
                        Log.d(
                            "bccm",
                            "playbackService did not initialize within 1000ms. Continuing with crossed fingers."
                        )
                    }
                } catch (e: Error) {
                    throw e;
                } finally {
                    onComplete()
                }
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // Warning: There can be multiple engines, one per dart isolate, e.g. for background isolates.
        // So we are also doing some steps via PlaybackApiImpl.attach -> attach()
        // which we should only call via the primary flutter dart engine.

        try {
            CastContext.getSharedInstance(flutterPluginBinding.applicationContext)
        } catch (e: Exception) {
            Log.d(
                "bccm",
                "CastContext.getSharedInstance() failed in onAttachedToEngine. Stack trace:"
            );
            e.printStackTrace()
        }

        pluginBinding = flutterPluginBinding
        playbackPigeon =
            PlaybackPlatformApi.PlaybackListenerPigeon(flutterPluginBinding.binaryMessenger)
        chromecastPigeon =
            ChromecastControllerPigeon.ChromecastPigeon(flutterPluginBinding.binaryMessenger)
        downloaderPigeon =
            DownloaderApi.DownloaderListenerPigeon(flutterPluginBinding.binaryMessenger)

        if (!mBound) {
            Intent(pluginBinding?.applicationContext, PlaybackService::class.java).also { intent ->
                mBound = pluginBinding?.applicationContext?.bindService(
                    intent, playbackServiceConnection, Context.BIND_AUTO_CREATE
                ) ?: false
            }
        }

        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "bccm-player",
            FlutterExoPlayerView.Factory(this)
        )
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "bccm-cast-player",
            FlutterCastPlayerView.Factory(this)
        )
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "bccm_player/cast_button",
            FlutterCastButton.Factory()
        )

    }

    private val textures: MutableMap<Long, TextureRegistry.SurfaceTextureEntry> = mutableMapOf()

    fun createTexture(): TextureRegistry.SurfaceTextureEntry? {
        val t = pluginBinding?.textureRegistry?.createSurfaceTexture()
        if (t != null) {
            textures[t.id()] = t
        }
        return t
    }

    fun releaseTexture(id: Long): Boolean {
        val t = textures[id]
        if (t == null) {
            Log.d("bccm", "Tried to release texture with id $id, but it was not found.")
            return false
        }
        t.release()
        textures.remove(id)
        return true
    }

    fun getTexture(id: Long): TextureRegistry.SurfaceTextureEntry? {
        return textures[id]
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d("bccm", "detaching. mBound: $mBound")
        if (mBound && playbackService?.isAttached(this) == true) {
            pluginBinding!!.applicationContext.unbindService(playbackServiceConnection)
            mBound = false
        }

        playbackService?.stopIfAttached(this)
        pluginBinding = null
        for (texture in textures.values) {
            texture.release()
        }
        textures.clear()
        mainScope.cancel()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        activityBinding?.addOnUserLeaveHintListener(this)

        val downloader = Downloader(
            binding.activity,
            downloaderPigeon!!
        ) // onAttachedToActivity always runs after onAttachedToEngine
        PlaybackPlatformPigeon.setup(pluginBinding!!.binaryMessenger, PlaybackApiImpl(this))
        DownloaderPigeon.setup(pluginBinding!!.binaryMessenger, DownloaderApiImpl(downloader))

        val sessionToken = SessionToken(
            binding.activity, ComponentName(binding.activity, PlaybackService::class.java)
        )
        controllerFuture = MediaController.Builder(binding.activity, sessionToken).buildAsync()
        mainScope.launch {
            Log.d("bccm", "OnAttachedToActivity")
            BccmPlayerPluginSingleton.activityState.update { binding.activity }
            BccmPlayerPluginSingleton.eventBus.emit(AttachedToActivityEvent(binding.activity))
        }
        mainScope.launch {
            BccmPlayerPluginSingleton.eventBus.filter { event -> event is PictureInPictureModeChangedEvent }
                .collect { event ->
                    val pipEvent = event as PictureInPictureModeChangedEvent
                    val builder = PlaybackPlatformApi.PictureInPictureModeChangedEvent.Builder()
                    val primaryId = playbackService?.getPrimaryController()?.id
                    if (primaryId != null) {
                        builder.setPlayerId(primaryId)
                        builder.setIsInPipMode(pipEvent.isInPictureInPictureMode)
                        playbackPigeon?.onPictureInPictureModeChanged(builder.build()) {}
                    }
                }
        }
        mainScope.launch {
            downloader.statusChanged.collect {
                downloaderPigeon?.onDownloadStatusChanged(it) {}
            }
        }
    }


    /***
     * Call this from your activity's onPictureInPictureModeChanged.
     * This is important for PiP to behave correctly (e.g. pause video when exiting PiP).
     */
    fun handleOnPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        val activityBinding = activityBinding ?: return
        val lifecycleState =
            FlutterLifecycleAdapter.getActivityLifecycle(activityBinding).currentState

        mainScope.launch {
            BccmPlayerPluginSingleton.eventBus.emit(
                PictureInPictureModeChangedEvent(isInPictureInPictureMode, lifecycleState)
            )
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnUserLeaveHintListener(this)
        mainScope.launch {
            Log.d("bccm", "OnDetachedFromActivity")
            BccmPlayerPluginSingleton.eventBus.emit(DetachedFromActivityEvent())
        }
        MediaController.releaseFuture(controllerFuture)
    }

    fun getPlaybackService(): PlaybackService? {
        return playbackService
    }

    override fun onUserLeaveHint() {
        val primaryPlayer = playbackService?.getPrimaryController();
        if (primaryPlayer == null) {
            Log.d("bccm", "onUserLeaveHint: primaryPlayer was null")
            return
        }
        val currentPlayerViewController =
            primaryPlayer.currentPlayerViewController
        if (currentPlayerViewController?.shouldPipAutomatically == true && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            currentPlayerViewController.enterPictureInPicture()
        } else if (primaryPlayer.player.volume == 0f && primaryPlayer.player.isPlaying) {
            primaryPlayer.player.stop()
            primaryPlayer.player.clearMediaItems()
        }
    }
}
