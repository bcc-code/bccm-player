package media.bcc.bccm_player

import android.content.Intent
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import com.google.android.gms.cast.framework.CastButtonFactory
import io.flutter.embedding.android.FlutterFragmentActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import media.bcc.bccm_player.pigeon.playback.AppConfig
import media.bcc.bccm_player.pigeon.playback.BufferMode
import media.bcc.bccm_player.pigeon.playback.ChromecastState
import media.bcc.bccm_player.pigeon.playback.MediaInfo
import media.bcc.bccm_player.pigeon.playback.MediaItem
import media.bcc.bccm_player.pigeon.playback.NpawConfig
import media.bcc.bccm_player.pigeon.playback.PlaybackPlatformPigeon
import media.bcc.bccm_player.pigeon.playback.PlayerStateSnapshot
import media.bcc.bccm_player.pigeon.playback.PlayerTracksSnapshot
import media.bcc.bccm_player.pigeon.playback.RepeatMode
import media.bcc.bccm_player.pigeon.playback.TrackType
import media.bcc.bccm_player.players.chromecast.CastExpandedControlsActivity
import media.bcc.bccm_player.players.chromecast.CastPlayerController
import media.bcc.bccm_player.utils.toMedia3Type


@OptIn(UnstableApi::class)
class PlaybackApiImpl(private val plugin: BccmPlayerPlugin) : PlaybackPlatformPigeon {
    private val mainScope = CoroutineScope(Dispatchers.Main + Job())

    override fun attach(callback: (Result<Unit>) -> Unit) {
        Log.d("bccm", "attaching plugin")
        // Extremely important to call result.success or result.fail
        plugin.attach(onComplete = {
            callback(Result.success(Unit))
        })
    }

    override fun setNpawConfig(config: NpawConfig?) {
        Log.d("bccm", "PlaybackPigeon: Setting npawConfig")
        mainScope.launch {
            BccmPlayerPluginSingleton.npawConfigState.update { config }
        }
    }

    override fun setAppConfig(config: AppConfig?) {
        Log.d("bccm", "PlaybackPigeon: Setting appConfig")
        mainScope.launch {
            BccmPlayerPluginSingleton.appConfigState.update { config }
        }
    }

    override fun getTracks(playerId: String?, callback: (Result<PlayerTracksSnapshot?>) -> Unit) {
        val playbackService = plugin.getPlaybackService()
        if (playbackService == null) {
            callback(Result.failure(Error()))
            return
        }
        val playerController =
            if (playerId != null) playbackService.getController(playerId) else playbackService.getPrimaryController()
        if (playerController == null) {
            callback(Result.failure(Error("Player with id $playerId does not exist.")))
            return
        }
        callback(Result.success(playerController.getTracksSnapshot()))
    }

    override fun getPlayerState(
        playerId: String?,
        callback: (Result<PlayerStateSnapshot?>) -> Unit
    ) {
        val playbackService = plugin.getPlaybackService()
        if (playbackService == null) {
            callback(Result.failure(Error()))
            return
        }
        val playerController =
            if (playerId != null) playbackService.getController(playerId) else playbackService.getPrimaryController()
        if (playerController == null) {
            callback(Result.failure(Error("Player with id $playerId does not exist.")))
            return
        }
        callback(Result.success(playerController.getPlayerStateSnapshot()))
    }

    override fun setSelectedTrack(
        playerId: String,
        type: TrackType,
        trackId: String?,
        callback: (Result<Unit>) -> Unit
    ) {
        val playbackService = plugin.getPlaybackService()
        if (playbackService == null) {
            callback(Result.failure(Error()))
            return
        }
        val playerController = playbackService.getController(playerId)
        if (playerController == null) {
            callback(Result.failure(Error("Player with id $playerId does not exist.")))
            return
        }
        playerController.setSelectedTrack(type.toMedia3Type(), trackId)
        callback(Result.success(Unit))
    }

    override fun setPlaybackSpeed(
        playerId: String,
        speed: Double,
        callback: (Result<Unit>) -> Unit
    ) {
        val playbackService = plugin.getPlaybackService()
        if (playbackService == null) {
            callback(Result.failure(Error()))
            return
        }
        val playerController = playbackService.getController(playerId)
        if (playerController == null) {
            callback(Result.failure(Error("Player with id $playerId does not exist.")))
            return
        }
        playerController.setPlaybackSpeed(speed.toFloat())
        callback(Result.success(Unit))
    }

    override fun newPlayer(
        bufferMode: BufferMode?,
        disableNpaw: Boolean?,
        callback: (Result<String>) -> Unit
    ) {
        Log.d("bccm", "PlaybackPigeon: newPlayer()")
        val playbackService = plugin.getPlaybackService()
        if (playbackService == null) {
            callback(Result.failure(Error()))
            return
        }
        val playerController = playbackService.newPlayer(
            bufferMode ?: BufferMode.STANDARD,
            disableNpaw ?: false
        )
        callback(Result.success(playerController.id))
    }

    override fun createVideoTexture(callback: (Result<Long>) -> Unit) {
        Log.d("bccm", "PlaybackPigeon: createVideoTexture()")
        val texture = plugin.createTexture()
        if (texture == null) {
            callback(Result.failure(Error("Could not create texture")))
            return
        }
        callback(Result.success(texture.id()))
    }

    override fun switchToVideoTexture(
        playerId: String,
        textureId: Long,
        callback: (Result<Long>) -> Unit
    ) {
        Log.d("bccm", "PlaybackPigeon: switchToVideoTexture()")
        val playbackService = plugin.getPlaybackService()
        if (playbackService == null) {
            callback(Result.failure(Error()))
            return
        }
        val playerController = playbackService.getController(playerId)
        if (playerController == null) {
            callback(Result.failure(Error("Player with id $playerId does not exist.")))
            return
        }
        val texture = plugin.getTexture(textureId)
        if (texture == null) {
            callback(Result.failure(Error("Texture with id $textureId does not exist.")))
            return
        }
        playerController.setVideoTexture(texture)
        callback(Result.success(texture.id()))
    }

    override fun disposeVideoTexture(
        textureId: Long,
        callback: (Result<Boolean>) -> Unit
    ) {
        Log.d("bccm", "PlaybackPigeon: disposeVideoTexture()")
        callback(Result.success(plugin.releaseTexture(textureId)))
    }

    override fun disposePlayer(playerId: String, callback: (Result<Boolean>) -> Unit) {
        val playbackService = plugin.getPlaybackService()
        if (playbackService == null) {
            callback(Result.failure(Error("Playback service doesn't exist")))
            return
        }
        val didDispose = playbackService.disposePlayer(playerId)
        callback(Result.success(didDispose))
    }

    override fun replaceCurrentMediaItem(
        playerId: String,
        mediaItem: MediaItem,
        playbackPositionFromPrimary: Boolean?,
        autoplay: Boolean?,
        callback: (Result<Unit>) -> Unit
    ) {
        var mediaItemResult = mediaItem
        val playbackService = plugin.getPlaybackService()
        if (playbackService == null) {
            callback(Result.failure(Error()))
            return
        }
        if (playbackPositionFromPrimary == true) {
            mediaItemResult =
                mediaItemResult.copy(
                    playbackStartPositionMs = playbackService.getPrimaryController()?.player?.currentPosition?.toDouble()
                )
        }

        val playerController = playbackService.getController(playerId)
        if (playerController == null) {
            callback(Result.failure(Error("Player with id $playerId does not exist.")))
            return
        }

        playerController.replaceCurrentMediaItem(mediaItemResult, autoplay)
        callback(Result.success(Unit))
    }

    override fun setPlayerViewVisibility(viewId: Long, visible: Boolean) {
        mainScope.launch {
            BccmPlayerPluginSingleton.eventBus.emit(SetPlayerViewVisibilityEvent(viewId, visible))
        }
    }

    override fun queueMediaItem(
        playerId: String,
        mediaItem: MediaItem,
        callback: (Result<Unit>) -> Unit
    ) {
        val playbackService = plugin.getPlaybackService()
        if (playbackService == null) {
            callback(Result.failure(Error()))
            return
        }
        val playerController = playbackService.getController(playerId)
            ?: throw Error("Player with id $playerId does not exist.")
        playerController.queueMediaItem(mediaItem)
        callback(Result.success(Unit))
    }

    override fun setPrimary(id: String, callback: (Result<Unit>) -> Unit) {
        val playbackService = plugin.getPlaybackService()
        if (playbackService == null) {
            callback(Result.failure(Error()))
            return
        }

        playbackService.setPrimary(id)
        callback(Result.success(Unit))
    }

    override fun play(playerId: String) {
        val playbackService = plugin.getPlaybackService() ?: return
        val playerController = playbackService.getController(playerId)
            ?: throw Error("Player with id $playerId does not exist.")

        playerController.play()
    }

    override fun seekTo(
        playerId: String,
        positionMs: Double,
        callback: (Result<Unit>) -> Unit
    ) {
        val playbackService = plugin.getPlaybackService() ?: return
        val playerController = playbackService.getController(playerId)
            ?: throw Error("Player with id $playerId does not exist.")
        try {
            playerController.player.seekTo(positionMs.toLong())
            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun pause(playerId: String) {
        val playbackService = plugin.getPlaybackService() ?: return
        val playerController = playbackService.getController(playerId)
            ?: throw Error("Player with id $playerId does not exist.")

        playerController.pause()
    }

    override fun setRepeatMode(
        playerId: String,
        repeatMode: RepeatMode,
        callback: (Result<Unit>) -> Unit
    ) {
        val playbackService = plugin.getPlaybackService() ?: return
        val playerController = playbackService.getController(playerId)
            ?: throw Error("Player with id $playerId does not exist.")

        playerController.setRepeatMode(repeatMode)
        callback(Result.success(Unit))
    }

    override fun setVolume(
        playerId: String,
        volume: Double,
        callback: (Result<Unit>) -> Unit
    ) {
        val playbackService = plugin.getPlaybackService() ?: return
        val playerController = playbackService.getController(playerId)
            ?: return callback(Result.failure(Error("Player with id $playerId does not exist.")))

        playerController.setVolume(volume)
        callback(Result.success(Unit))
    }

    override fun stop(playerId: String, reset: Boolean) {
        val playbackService = plugin.getPlaybackService() ?: return
        val playerController = playbackService.getController(playerId)
            ?: throw Error("Player with id $playerId does not exist.")

        playerController.stop(reset)
    }

    override fun exitFullscreen(playerId: String) {
        val playbackService = plugin.getPlaybackService() ?: return
        val playerController = playbackService.getController(playerId)
            ?: throw Error("Player with id $playerId does not exist.")

        playerController.currentPlayerViewController?.exitFullscreen()
    }

    override fun enterFullscreen(playerId: String) {
        val playbackService = plugin.getPlaybackService() ?: return
        val playerController = playbackService.getController(playerId)
            ?: throw Error("Player with id $playerId does not exist.")

        playerController.currentPlayerViewController?.enterFullscreen()
    }

    override fun setMixWithOthers(
        playerId: String,
        mixWithOthers: Boolean,
        callback: (Result<Unit>) -> Unit
    ) {
        val playbackService = plugin.getPlaybackService() ?: return
        val playerController = playbackService.getController(playerId)
            ?: throw Error("Player with id $playerId does not exist.")
        playerController.setMixWithOthers(mixWithOthers)
        callback(Result.success(Unit))
    }

    override fun getChromecastState(callback: (Result<ChromecastState?>) -> Unit) {
        val playbackService = plugin.getPlaybackService()
        if (playbackService == null) {
            callback(Result.failure(Error()))
            return
        }
        val cc = playbackService.getController("chromecast")
        if (cc == null || cc !is CastPlayerController) {
            return
        }
        callback(Result.success(cc.getState()))
    }

    override fun openExpandedCastController() {
        val intent = Intent(
            BccmPlayerPluginSingleton.activityState.value,
            CastExpandedControlsActivity::class.java
        )
        BccmPlayerPluginSingleton.activityState.value?.startActivity(intent)
    }

    override fun openCastDialog() {
        val activity =
            (BccmPlayerPluginSingleton.activityState.value as? FlutterFragmentActivity) ?: return
        val fm =
            activity.supportFragmentManager
                ?: return
        val btn = androidx.mediarouter.app.MediaRouteButton(activity)
        CastButtonFactory.setUpMediaRouteButton(activity, btn)
        btn.onAttachedToWindow()
        btn.showDialog()
    }

    override fun fetchMediaInfo(
        url: String,
        mimeType: String?,
        callback: (Result<MediaInfo>) -> Unit
    ) {
        val context = BccmPlayerPluginSingleton.activityState.value
        if (context != null) {
            mainScope.launch {
                try {
                    val mediaInfo = MediaInfoFetcher.fetchMediaInfo(context, url, mimeType)
                    callback(Result.success(mediaInfo))
                } catch (e: Exception) {
                    callback(Result.failure(e))
                }
            }
        } else {
            callback(Result.failure(Error("Not attached to activity")))
        }
    }

    override fun getAndroidPerformanceClass(callback: (Result<Long>) -> Unit) {
        var performanceClass = BccmPlayerPlugin.devicePerformance?.mediaPerformanceClass?.toLong()
        if (performanceClass == 0L) {
            performanceClass = null
        }
        if (performanceClass != null) {
            callback(Result.success(performanceClass))
        } else {
            callback(Result.failure(Error("Could not get performance class")))
        }
    }

}