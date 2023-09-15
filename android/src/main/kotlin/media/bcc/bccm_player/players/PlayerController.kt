package media.bcc.bccm_player.players

import android.net.Uri
import android.os.Bundle
import androidx.annotation.CallSuper
import androidx.core.math.MathUtils.clamp
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.exoplayer.ExoPlayer
import media.bcc.bccm_player.BccmPlayerPlugin
import media.bcc.bccm_player.Downloader
import media.bcc.bccm_player.cache
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.VideoSize
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.BCCM_META_EXTRAS
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.PLAYER_DATA_IS_LIVE
import media.bcc.bccm_player.players.chromecast.CastMediaItemConverter.Companion.PLAYER_DATA_MIME_TYPE
import media.bcc.bccm_player.players.exoplayer.BccmPlayerViewController
import media.bcc.bccm_player.utils.TrackUtils


abstract class PlayerController : Player.Listener {
    abstract val id: String
    abstract val player: Player
    abstract var currentPlayerViewController: BccmPlayerViewController?
    open var plugin: BccmPlayerPlugin? = null
    var pluginPlayerListener: PlayerListener? = null
    var isLive: Boolean = false

    fun attachPlugin(newPlugin: BccmPlayerPlugin) {
        if (this.plugin != null) detachPlugin()
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
        detachPlugin();
    }

    fun play() {
        player.play()
    }

    fun pause() {
        player.pause()
    }

    fun setVolume(volume: Double) {
        val safeVolume = clamp(volume, 0.0, 1.0)
        player.volume = safeVolume.toFloat();
        pluginPlayerListener?.onManualPlayerStateUpdate()
    }

    abstract fun stop(reset: Boolean)

    fun replaceCurrentMediaItem(mediaItem: PlaybackPlatformApi.MediaItem, autoplay: Boolean?) {
        this.isLive = mediaItem.isLive ?: false
        var androidMi = mapMediaItem(mediaItem)
        var playbackStartPositionMs: Double? = null
        if (!this.isLive && mediaItem.playbackStartPositionMs != null) {
            playbackStartPositionMs = mediaItem.playbackStartPositionMs
        }

        if (mediaItem.url?.startsWith("downloaded://") == true) {
            // Create a read-only cache data source factory using the download cache.

            val id = mediaItem.url!!.substring("downloaded://".length);
            val download = Downloader.downloadManager?.downloadIndex?.getDownload(id);
            val downloadRequest = download?.request;
            if (downloadRequest != null) {
                val cacheDataSourceFactory: DataSource.Factory = CacheDataSource.Factory()
                    .setCache(cache!!)
                    .setUpstreamDataSourceFactory(DefaultHttpDataSource.Factory())
                    .setCacheWriteDataSinkFactory(null) // Disable writing.

                androidMi = androidMi.buildUpon()
                    .setMediaId(id)
                    .setUri(downloadRequest.uri)
                    .setCustomCacheKey(downloadRequest.customCacheKey)
                    .setMimeType(downloadRequest.mimeType)
                    .setStreamKeys(downloadRequest.streamKeys)
                    .build()
            } else {
                throw Error("Tried to play non-existent download")
            }
        }
        player.setMediaItem(androidMi, playbackStartPositionMs?.toLong() ?: 0)
        player.playWhenReady = autoplay == true
        player.prepare()
    }

    fun queueMediaItem(mediaItem: PlaybackPlatformApi.MediaItem) {
        val androidMi = mapMediaItem(mediaItem)
        player.addMediaItem(androidMi)
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

    fun mapMediaItem(mediaItem: PlaybackPlatformApi.MediaItem): MediaItem {
        val metaBuilder = MediaMetadata.Builder()
        val exoExtras = Bundle()

        if (mediaItem.metadata?.artworkUri != null) {
            metaBuilder.setArtworkUri(Uri.parse(mediaItem.metadata?.artworkUri))
        }

        val mimeType = mediaItem.mimeType ?: "application/x-mpegURL"
        exoExtras.putString(PLAYER_DATA_MIME_TYPE, mimeType)

        if (mediaItem.isLive == true) {
            exoExtras.putString(PLAYER_DATA_IS_LIVE, "true")
        }

        val sourceExtra = mediaItem.metadata?.extras
        if (sourceExtra != null) {
            for (extra in sourceExtra) {
                (extra.value as? String?).let {
                    exoExtras.putString(BCCM_META_EXTRAS + "." + extra.key, it)
                }
            }
        }

        metaBuilder
            .setTitle(mediaItem.metadata?.title)
            .setArtist(mediaItem.metadata?.artist)
            .setExtras(exoExtras).build()
        return MediaItem.Builder()
            .setUri(mediaItem.url)
            .setMimeType(mimeType)
            .setMediaMetadata(metaBuilder.build()).build()
    }

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
            metaBuilder.setDurationMs(player.duration.toDouble());
        }
        metaBuilder.setExtras(extraMeta)
        val miBuilder = PlaybackPlatformApi.MediaItem.Builder()
            .setUrl(mediaItem.localConfiguration?.uri?.toString())
            .setIsLive(sourceExtras?.getString(PLAYER_DATA_IS_LIVE) == "true")
            .setMetadata(metaBuilder.build())
        val mimeType = sourceExtras?.getString(PLAYER_DATA_MIME_TYPE);
        if (mimeType != null) {
            miBuilder.setMimeType(mimeType)
        } else if (mediaItem.localConfiguration?.mimeType != null) {
            miBuilder.setMimeType(mediaItem.localConfiguration?.mimeType)
        }

        return miBuilder.build()
    }

    fun getPlaybackState(): PlaybackPlatformApi.PlaybackState {
        return if (player.isPlaying || player.playWhenReady && !arrayOf(
                Player.STATE_ENDED,
                Player.STATE_IDLE
            ).contains(player.playbackState)
        ) PlaybackPlatformApi.PlaybackState.PLAYING else PlaybackPlatformApi.PlaybackState.PAUSED;
    }

    fun getPlayerStateSnapshot(): PlaybackPlatformApi.PlayerStateSnapshot {
        return PlaybackPlatformApi.PlayerStateSnapshot.Builder()
            .setPlayerId(id)
            .setCurrentMediaItem(getCurrentMediaItem())
            .setPlaybackPositionMs(player.currentPosition.toDouble())
            .setPlaybackState(getPlaybackState())
            .setPlaybackSpeed(player.playbackParameters.speed.toDouble())
            .setIsBuffering(player.playbackState == Player.STATE_BUFFERING)
            .setIsFullscreen(currentPlayerViewController?.isFullscreen == true)
            .setVideoSize(
                if (player.videoSize.height <= 0) null
                else VideoSize.Builder()
                    .setWidth(player.videoSize.width.toLong())
                    .setHeight(player.videoSize.height.toLong())
                    .build()
            )
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

    private fun setTrackTypeDisabled(type: @C.TrackType Int, state: Boolean) {
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
        for (group in tracks.groups.filter { it.type == type && it.length > 0 }) {
            for (i in 0 until group.length) {
                val format = group.getTrackFormat(i);
                if (format.id == trackId) {
                    trackGroup = group
                    trackIndex = i
                }
            }
        }
        if (trackGroup != null && trackIndex != null) {
            player.trackSelectionParameters = player.trackSelectionParameters
                .buildUpon()
                .clearOverridesOfType(type)
                .setOverrideForType(TrackSelectionOverride(trackGroup.mediaTrackGroup, trackIndex))
                .build()
        }
    }

    /**
     * Sets the language of the subtitles. Returns false if there is the language
     * is not available for the current media item.
     */
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
                .setOverrideForType(TrackSelectionOverride(trackGroup.mediaTrackGroup, 0))
                .build()
            true
        } else {
            false
        }
    }

    private fun getCurrentMediaItem(): PlaybackPlatformApi.MediaItem? {
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

    abstract fun setMixWithOthers(mixWithOthers: Boolean);
}