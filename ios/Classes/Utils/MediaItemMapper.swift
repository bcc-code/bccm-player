import AVFoundation
import AVKit
import Foundation
import MediaPlayer

class MediaItemMapper {
    static func mapPlayerItem(_ playerItem: AVPlayerItem?) -> MediaItem? {
        guard let playerItem = playerItem else {
            return nil
        }
        guard let asset = (playerItem.asset as? AVURLAsset) else {
            return nil
        }

        var metadata: MediaMetadata?
        var playerData: [String: String]?
        if #available(iOS 12.2, *) {
            let extras = MetadataUtils.getNamespacedMetadata(playerItem.externalMetadata, namespace: .BccmExtras)
            playerData = MetadataUtils.getNamespacedMetadata(playerItem.externalMetadata, namespace: .BccmPlayer)
            let artworkUri: String? = playerData?[PlayerMetadataConstants.ArtworkUri]
            metadata = MediaMetadata.make(
                withArtworkUri: artworkUri,
                title: playerItem.externalMetadata.first(where: { $0.identifier == AVMetadataIdentifier.commonIdentifierTitle })?.stringValue,
                artist: playerItem.externalMetadata.first(where: { $0.identifier == AVMetadataIdentifier.commonIdentifierArtist })?.stringValue,
                durationMs: !playerItem.duration.seconds.isFinite ? nil : NSNumber(floatLiteral: playerItem.duration.seconds * 1000),
                extras: extras
            )
        }
        let mimeType: String? = playerData?[PlayerMetadataConstants.MimeType]

        var isLive = CMTIME_IS_INDEFINITE(playerItem.duration)
        if let isLiveMeta = playerData?[PlayerMetadataConstants.IsLive] {
            isLive = isLiveMeta == "true"
        }

        var isOffline: Bool? = playerData?[PlayerMetadataConstants.IsOffline] == "true"

        let id = playerData?[PlayerMetadataConstants.Id] ?? UUID().uuidString

        let mediaItem = MediaItem.make(
            withId: id,
            url: asset.url.absoluteString,
            mimeType: mimeType,
            metadata: metadata,
            isLive: isLive as NSNumber,
            isOffline: isOffline as NSNumber?,
            playbackStartPositionMs: nil,
            lastKnownAudioLanguage: playerItem.getSelectedAudioLanguage(),
            lastKnownSubtitleLanguage: playerItem.getSelectedSubtitleLanguage()
        )
        return mediaItem
    }
}
