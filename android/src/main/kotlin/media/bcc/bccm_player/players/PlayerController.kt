package media.bcc.bccm_player.players

import android.annotation.SuppressLint
import android.net.Uri
import android.os.Bundle
import android.view.Surface
import androidx.annotation.CallSuper
import androidx.core.math.MathUtils.clamp
import androidx.media3.common.C
import androidx.media3.common.C.TRACK_TYPE_AUDIO
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaItem.DrmConfiguration
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import io.flutter.view.TextureRegistry.SurfaceTextureEntry
import media.bcc.bccm_player.BccmPlayerPlugin
import media.bcc.bccm_player.BccmPlayerPluginSingleton
import media.bcc.bccm_player.DOWNLOADED_URL_SCHEME
import media.bcc.bccm_player.Downloader
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.RepeatMode
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.VideoSize
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.BCCM_META_EXTRAS
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.PLAYER_DATA_DURATION
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.PLAYER_DATA_IS_LIVE
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.PLAYER_DATA_IS_OFFLINE
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.PLAYER_DATA_LAST_KNOWN_AUDIO_LANGUAGE
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.PLAYER_DATA_MIME_TYPE
import media.bcc.bccm_player.players.exoplayer.BccmPlayerViewController
import media.bcc.bccm_player.utils.NoOpVoidResult
import media.bcc.bccm_player.utils.TrackUtils
import java.util.UUID

import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.PLAYER_DATA_DRM_LICENSE_SERVER_URL
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.PLAYER_DATA_CAST_URL
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.PLAYER_DATA_CAST_CUSTOM_DATA
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.PLAYER_DATA_DRM_LICENSE_REQUEST_HEADERS


abstract class PlayerController : Player.Listener {
    abstract val id: String
    abstract val player: Player
    abstract var currentPlayerViewController: BccmPlayerViewController?
    open var plugin: BccmPlayerPlugin? = null
    var pluginPlayerListener: PlayerListener? = null
    var isLive: Boolean = false
    var texture: SurfaceTextureEntry? = null
    var surface: Surface? = null
    var manuallySelectedAudioLanguage: String? = null

    fun attachPlugin(newPlugin: BccmPlayerPlugin) {
        detachPlugin()
        this.plugin = newPlugin;
        PlayerListener(this, newPlugin).also {
            pluginPlayerListener = it
            player.addListener(it)
        }
    }

    @Suppress("MemberVisibilityCanBePrivate")
    fun detachPlugin() {
        // We can end up here, e.g. when doing hot reload with flutter
        pluginPlayerListener?.also {
            it.stop()
            player.removeListener(it)
        }
        this.plugin = null;
    }

    @CallSuper
    open fun release() {
        surface?.release()
        surface = null
        pluginPlayerListener?.stop()
        detachPlugin();
    }

    fun play() {
        player.play()
    }

    fun pause() {
        player.pause()
    }

    fun setRepeatMode(repeatMode: RepeatMode) {
        player.repeatMode = when (repeatMode) {
            RepeatMode.OFF -> Player.REPEAT_MODE_OFF
            RepeatMode.ONE -> Player.REPEAT_MODE_ONE
        }
    }

    open fun setVideoTexture(texture: SurfaceTextureEntry?) {
        if (texture == null) {
            this.texture = null
            this.surface = null
            player.setVideoSurface(null)
            pluginPlayerListener?.onManualPlayerStateUpdate()
            return
        }
        this.texture = texture
        this.surface = Surface(texture.surfaceTexture())
        player.setVideoSurface(surface)
        pluginPlayerListener?.onManualPlayerStateUpdate()
    }

    fun setVolume(volume: Double) {
        val safeVolume = clamp(volume, 0.0, 1.0)
        player.volume = safeVolume.toFloat();
        pluginPlayerListener?.onManualPlayerStateUpdate()
    }

    abstract fun stop(reset: Boolean)

    @SuppressLint("UnsafeOptInUsageError")
    fun replaceCurrentMediaItem(mediaItem: PlaybackPlatformApi.MediaItem, autoplay: Boolean?) {
        try {
            this.isLive = mediaItem.isLive ?: false
            var androidMi = mapMediaItem(mediaItem)
            var playbackStartPositionMs: Double? = null
            if (!this.isLive && mediaItem.playbackStartPositionMs != null) {
                playbackStartPositionMs = mediaItem.playbackStartPositionMs
            }

            player.setMediaItem(androidMi, playbackStartPositionMs?.toLong() ?: 0)
            if (playbackStartPositionMs != null) {
                player.seekTo(playbackStartPositionMs.toLong())
            }
            manualUpdateEvent()
            player.playWhenReady = autoplay == true
            player.prepare()
        } catch (e: Exception) {
            Log.e(
                "bccm-@PlayerController-replaceCurrentMediaItem",
                "Something went wrong: $e"
            );
            throw e;
        }
    }

    fun manualUpdateEvent() {
        val event = PlaybackPlatformApi.PlayerStateUpdateEvent.Builder()
            .setPlayerId(id)
            .setSnapshot(getPlayerStateSnapshot())
        plugin?.playbackPigeon?.onPlayerStateUpdate(event.build(), NoOpVoidResult())
    }

    fun extractExtrasFromAndroid(source: Bundle): Map<String, String> {
        val extraMeta = mutableMapOf<String, String>()
        for (sourceKey in source.keySet()) {
            val value = source[sourceKey]
            if (!sourceKey.contains("media.bcc.extras.") || value !is String) continue
            val newKey =
                sourceKey.substring(sourceKey.indexOf("media.bcc.extras.") + "media.bcc.extras.".length)
            source[sourceKey]?.toString()?.let {
                extraMeta[newKey] = it
            }
        }
        return extraMeta
    }

    // map for android
    @SuppressLint("UnsafeOptInUsageError")
    private fun mapMediaItem(mediaItem: PlaybackPlatformApi.MediaItem): MediaItem {
        val metaBuilder = MediaMetadata.Builder()
        val exoExtras = Bundle()

        if (mediaItem.metadata?.artworkUri != null) {
            metaBuilder.setArtworkUri(Uri.parse(mediaItem.metadata?.artworkUri))
        }

        var mimeType = mediaItem.mimeType;
        if (mimeType == null && mediaItem.url?.contains(".m3u8") == true) {
            mimeType = "application/x-mpegURL"
        }
        exoExtras.putString(PLAYER_DATA_MIME_TYPE, mimeType)

        if (mediaItem.isLive == true) {
            exoExtras.putString(PLAYER_DATA_IS_LIVE, "true")
        }
        if (mediaItem.isOffline == true) {
            exoExtras.putString(PLAYER_DATA_IS_OFFLINE, "true")
        }
        val duration = mediaItem.metadata?.durationMs;
        if (duration != null) {
            exoExtras.putString(PLAYER_DATA_DURATION, duration.toString())
        }

        if (mediaItem.lastKnownAudioLanguage != null) {
            exoExtras.putString(PLAYER_DATA_LAST_KNOWN_AUDIO_LANGUAGE, mediaItem.lastKnownAudioLanguage)
        }
        manuallySelectedAudioLanguage?.let {
            exoExtras.putString(PLAYER_DATA_LAST_KNOWN_AUDIO_LANGUAGE, it)
        }

        val sourceExtra = mediaItem.metadata?.extras
        if (sourceExtra != null) {
            for (extra in sourceExtra) {
                (extra.value as? String?).let {
                    exoExtras.putString(BCCM_META_EXTRAS + "." + extra.key, it)
                }
            }
        }

        var drmConfiguration: DrmConfiguration? = null
        if (mediaItem.drmConfiguration != null && mediaItem.drmConfiguration?.drmType != null && mediaItem.drmConfiguration?.drmType == PlaybackPlatformApi.DrmType.WIDEVINE && mediaItem.drmConfiguration?.licenseServerUrl != null && mediaItem.drmConfiguration?.licenseServerUrl?.isNotEmpty() == true) {
            exoExtras.putString(PLAYER_DATA_DRM_LICENSE_SERVER_URL, mediaItem.drmConfiguration?.licenseServerUrl)
            if (!mediaItem.drmConfiguration?.licenseRequestHeaders.isNullOrEmpty()) {
                exoExtras.putString(
                    PLAYER_DATA_DRM_LICENSE_REQUEST_HEADERS,
                    if (mediaItem.drmConfiguration?.licenseRequestHeaders != null) JSONObject(
                        mediaItem.drmConfiguration?.licenseRequestHeaders as Map<String, String>
                    ).toString() else null
                )
            }

            drmConfiguration = DrmConfiguration.Builder(C.WIDEVINE_UUID)
                .setLicenseUri(mediaItem.drmConfiguration?.licenseServerUrl)
                .setLicenseRequestHeaders(mediaItem.drmConfiguration?.licenseRequestHeaders as Map<String, String>)
                .build()
        }

        metaBuilder
            .setTitle(mediaItem.metadata?.title)
            .setArtist(mediaItem.metadata?.artist)
            .setExtras(exoExtras).build()

        if (mediaItem.url?.startsWith(DOWNLOADED_URL_SCHEME) == true) {
            val id = mediaItem.url!!.substring(DOWNLOADED_URL_SCHEME.length);
            val downloadManager = Downloader.getDownloadManager();
            val download = downloadManager.downloadIndex.getDownload(id);
            val downloadRequest = download?.request;
            downloadManager.resumeDownloads()
            if (downloadRequest != null) {
                return MediaItem.Builder()
                    .setMediaId(id)
                    .setUri(downloadRequest.uri)
                    .setMediaMetadata(metaBuilder.build())
                    .setCustomCacheKey(downloadRequest.customCacheKey)
                    .setMimeType(downloadRequest.mimeType)
                    .setStreamKeys(downloadRequest.streamKeys)
                    .build()
            } else {
                throw Error("Tried to play non-existent download")
            }
        }

        return MediaItem.Builder()
            .setUri(mediaItem.url)
            .setMimeType(mimeType)
            .setMediaId(mediaItem.id ?: UUID.randomUUID().toString())
            .setMediaMetadata(metaBuilder.build())
            .setDrmConfiguration(drmConfiguration)
            .build()
    }

    // map for dart
    fun mapMediaItem(mediaItem: MediaItem): PlaybackPlatformApi.MediaItem {
        val metaBuilder = PlaybackPlatformApi.MediaMetadata.Builder()
        if (mediaItem.mediaMetadata.artworkUri != null) {
            metaBuilder.setArtworkUri(mediaItem.mediaMetadata.artworkUri?.toString())
        }
        metaBuilder.setTitle(mediaItem.mediaMetadata.title?.toString())
        metaBuilder.setArtist(mediaItem.mediaMetadata.artist?.toString())
        var extraMeta: Map<String, String> = mutableMapOf()
        val sourceExtras = mediaItem.mediaMetadata.extras
        if (sourceExtras != null) {
            extraMeta = extractExtrasFromAndroid(sourceExtras)
        }
        if (player.currentMediaItem == mediaItem) {
            var duration: Double? = player.duration.toDouble()
            if (duration == null || duration <= 0) {
                val durationStr = sourceExtras?.getString(PLAYER_DATA_DURATION)
                duration = durationStr?.toDouble()
            }
            metaBuilder.setDurationMs(duration)
        }
        metaBuilder.setExtras(extraMeta)
        val miBuilder = PlaybackPlatformApi.MediaItem.Builder()
            .setUrl(mediaItem.localConfiguration?.uri?.toString())
            .setIsLive(sourceExtras?.getString(PLAYER_DATA_IS_LIVE) == "true")
            .setIsOffline(sourceExtras?.getString(PLAYER_DATA_IS_OFFLINE) == "true")
            .setMetadata(metaBuilder.build())
        val mimeType = sourceExtras?.getString(PLAYER_DATA_MIME_TYPE);
        if (mimeType != null) {
            miBuilder.setMimeType(mimeType)
        } else if (mediaItem.localConfiguration?.mimeType != null) {
            miBuilder.setMimeType(mediaItem.localConfiguration?.mimeType)
        }

        if (extraMeta.containsKey(PLAYER_DATA_DRM_LICENSE_SERVER_URL)) {
            var drmLicenseRequestHeaders: Map<String, String>? = null

            if (extraMeta.containsKey(PLAYER_DATA_DRM_LICENSE_REQUEST_HEADERS) && !extraMeta[PLAYER_DATA_DRM_LICENSE_REQUEST_HEADERS].isNullOrEmpty()) {
                drmLicenseRequestHeaders = JSONObject(extraMeta[PLAYER_DATA_DRM_LICENSE_REQUEST_HEADERS]!!).toMap() as Map<String, String>
            }

            val drmConfiguration = PlaybackPlatformApi.DrmConfiguration.Builder()
                .setDrmType(PlaybackPlatformApi.DrmType.WIDEVINE)
                .setFpsCertificateUrl(null)
                .setLicenseServerUrl(extraMeta[PLAYER_DATA_DRM_LICENSE_SERVER_URL]!!)
                .setLicenseRequestHeaders(drmLicenseRequestHeaders)
                .build()
            miBuilder.setDrmConfiguration(drmConfiguration)
        }
        if (extraMeta.containsKey(PLAYER_DATA_CAST_URL)) {
            var customData: Map<String, String>? = null

            if (extraMeta.containsKey(PLAYER_DATA_CAST_CUSTOM_DATA) && !extraMeta[PLAYER_DATA_CAST_CUSTOM_DATA].isNullOrEmpty()) {
                customData = JSONObject(extraMeta[PLAYER_DATA_CAST_CUSTOM_DATA]!!).toMap() as Map<String, String>
            }

            val castMedia = PlaybackPlatformApi.CastMedia.Builder()
                .setUrl(extraMeta[PLAYER_DATA_CAST_URL]!!)
                .setCustomData(customData)
                .build()
            miBuilder.setCastMedia(castMedia)
        }

        miBuilder.setId(mediaItem.mediaId)

        return miBuilder.build()
    }

    fun getPlaybackState(): PlaybackPlatformApi.PlaybackState {
        if (player.playbackState == Player.STATE_ENDED) {
            return PlaybackPlatformApi.PlaybackState.STOPPED
        }
        return if (player.isPlaying || player.playWhenReady && !arrayOf(
                Player.STATE_ENDED,
                Player.STATE_IDLE
            ).contains(player.playbackState)
        ) PlaybackPlatformApi.PlaybackState.PLAYING else PlaybackPlatformApi.PlaybackState.PAUSED;
    }

    fun getPlayerStateSnapshot(): PlaybackPlatformApi.PlayerStateSnapshot {
        val error =
            player.playerError?.let {
                PlaybackPlatformApi.PlayerError.Builder()
                    .setCode(it.errorCodeName)
                    .setMessage(it.message)
                    .build()
            }
        return PlaybackPlatformApi.PlayerStateSnapshot.Builder()
            .setPlayerId(id)
            .setCurrentMediaItem(getCurrentMediaItem())
            .setPlaybackPositionMs(player.currentPosition.toDouble())
            .setPlaybackState(getPlaybackState())
            .setPlaybackSpeed(player.playbackParameters.speed.toDouble())
            .setIsBuffering(player.playbackState == Player.STATE_BUFFERING)
            .setIsFullscreen(currentPlayerViewController?.isFullscreen == true)
            .setTextureId(texture?.id())
            .setError(error)
            .setVideoSize(
                if (player.videoSize.height <= 0) null
                else VideoSize.Builder()
                    .setWidth(player.videoSize.width.toLong())
                    .setHeight(player.videoSize.height.toLong())
                    .build()
            )
            .setVolume(player.volume.toDouble())
            .build()
    }

    fun getTracksSnapshot(): PlaybackPlatformApi.PlayerTracksSnapshot {
        // get tracks from player
        val audioTracks = TrackUtils.getAudioTracksForPlayer(player)
        val videoTracks = TrackUtils.getVideoTracksForPlayer(player)
        val textTracks = TrackUtils.getTextTracksForPlayer(player)

        return PlaybackPlatformApi.PlayerTracksSnapshot.Builder()
            .setPlayerId(id)
            .setAudioTracks(audioTracks)
            .setTextTracks(textTracks)
            .setVideoTracks(videoTracks)
            .build()
    }

    internal fun setTrackTypeDisabled(type: @C.TrackType Int, state: Boolean) {
        player.trackSelectionParameters = player.trackSelectionParameters
            .buildUpon()
            .setTrackTypeDisabled(type, state)
            .build()
    }

    fun setSelectedTrack(type: @C.TrackType Int, trackId: String?, tracksOverride: Tracks? = null) {
        if (trackId == null) {
            setTrackTypeDisabled(type, true);
            return;
        }
        setTrackTypeDisabled(type, false);

        if (trackId == "auto") {
            player.trackSelectionParameters = player.trackSelectionParameters
                .buildUpon()
                .clearOverridesOfType(type)
                .build()
            return
        }

        val tracks = tracksOverride ?: player.currentTracks
        var trackGroup: Tracks.Group? = null
        var trackIndex: Int? = null
        l@ for (group in tracks.groups.filter { it.type == type && it.length > 0 }) {
            for (i in 0 until group.length) {
                val format = group.getTrackFormat(i);
                if (format.id == trackId) {
                    trackGroup = group
                    trackIndex = i
                    if (type == TRACK_TYPE_AUDIO) {
                        manuallySelectedAudioLanguage = format.language
                    }
                    break@l
                }
            }
        }
        if (trackGroup != null && trackIndex != null) {
            val appConfig = BccmPlayerPluginSingleton.appConfigState.value
            val audioLanguages = getExpectedAudioLanguages(appConfig)

            player.trackSelectionParameters = player.trackSelectionParameters
                .buildUpon()
                .clearOverridesOfType(type)
                .setPreferredAudioLanguages(*audioLanguages.toTypedArray())
                .setOverrideForType(TrackSelectionOverride(trackGroup.mediaTrackGroup, trackIndex))
                .build()
        }
    }

    fun getExpectedAudioLanguages(appConfig: PlaybackPlatformApi.AppConfig?): MutableList<String> {
        val audioLanguages: MutableList<String> = mutableListOf()

        manuallySelectedAudioLanguage?.let {
            audioLanguages.add(it)
        }
        if (appConfig?.audioLanguages?.isEmpty() == false) {
            audioLanguages.addAll(appConfig.audioLanguages)
        }

        return audioLanguages
    }

    /**
     * Sets the language of the subtitles. Returns false if none of the languages
     * are available for the current media item.
     */
    fun setSelectedTrackByLanguages(
        type: @C.TrackType Int,
        languages: Array<String>,
        tracksOverride: Tracks? = null
    ): Boolean {
        for (language in languages) {
            if (setSelectedTrackByLanguage(type, language, tracksOverride)) {
                return true
            }
        }
        return false
    }

    /**
     * Sets the language of the subtitles. Returns false if there is the language
     * is not available for the current media item.
     */
    @SuppressLint("UnsafeOptInUsageError")
    fun setSelectedTrackByLanguage(
        type: @C.TrackType Int,
        language: String,
        tracksOverride: Tracks? = null,
    ): Boolean {
        val tracks = tracksOverride ?: player.currentTracks
        val trackGroup = tracks.groups.firstOrNull {
            it.type == type
                    && it.mediaTrackGroup.length > 0
                    && it.mediaTrackGroup.getFormat(0).language == language
        }

        return if (trackGroup != null) {
            player.trackSelectionParameters = player.trackSelectionParameters
                .buildUpon()
                .clearOverridesOfType(type)
                .setTrackTypeDisabled(type, false)
                .setOverrideForType(TrackSelectionOverride(trackGroup.mediaTrackGroup, 0))
                .build()
            true
        } else {
            false
        }
    }

    fun getCurrentMediaItem(): PlaybackPlatformApi.MediaItem? {
        val current = player.currentMediaItem;
        if (current != null) {
            return mapMediaItem(current)
        }
        return null
    }

    override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
        mediaItem?.let {
            val bccmMediaItem = mapMediaItem(mediaItem)
            isLive = bccmMediaItem.isLive ?: false
        }
    }

    fun setPlaybackSpeed(speed: Float) {
        player.setPlaybackSpeed(speed)
        pluginPlayerListener?.onManualPlayerStateUpdate()
    }

    fun playNext() {
        plugin?.queueManagerPigeon?.skipToNext(this.id, NoOpVoidResult())
    }

    fun playPrevious() {
        plugin?.queueManagerPigeon?.skipToPrevious(this.id, NoOpVoidResult())
    }

    override fun onPlaybackStateChanged(playbackState: Int) {
        if (playbackState == Player.STATE_ENDED) {
            plugin?.queueManagerPigeon?.handlePlaybackEnded(this.id, getCurrentMediaItem(), NoOpVoidResult());
        }
    }

    abstract fun setMixWithOthers(mixWithOthers: Boolean);

    private fun JSONObject.toMap(): Map<String, *> = keys().asSequence().associateWith {
        when (val value = this[it])
        {
            is JSONArray ->
            {
                val map = (0 until value.length()).associate { Pair(it.toString(), value[it]) }
                JSONObject(map).toMap().values.toList()
            }
            is JSONObject -> value.toMap()
            JSONObject.NULL -> null
            else            -> value
        }
    }
}