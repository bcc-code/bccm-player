package media.bcc.bccm_player.utils

import androidx.media3.common.C
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi

fun PlaybackPlatformApi.TrackType.toMedia3Type(): Int {
    if (this == PlaybackPlatformApi.TrackType.TEXT) {
        return C.TRACK_TYPE_TEXT;
    } else if (this == PlaybackPlatformApi.TrackType.AUDIO) {
        return C.TRACK_TYPE_AUDIO;
    } else if (this == PlaybackPlatformApi.TrackType.VIDEO) {
        return C.TRACK_TYPE_VIDEO;
    }
    return C.TRACK_TYPE_UNKNOWN;
}