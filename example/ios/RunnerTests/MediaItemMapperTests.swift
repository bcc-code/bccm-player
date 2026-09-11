import AVFoundation
import XCTest

@testable import bccm_player

/**
 Turns the `AVPlayerItem` the native side is holding back into the pigeon
 `MediaItem` that Dart sees — the iOS counterpart of Android's
 `CastMediaItemConverter`.

 All of the item's identity (its id, mime type, live/offline flags, artwork)
 survives only as namespaced metadata strings, so this mapping is where a
 mis-typed key turns into a media item that Dart can no longer recognise.
 */
final class MediaItemMapperTests: XCTestCase {

    func testReturnsNilWithoutAPlayerItem() {
        XCTAssertNil(MediaItemMapper.mapPlayerItem(nil))
    }

    func testMapsPlayerDataOntoTheMediaItem() throws {
        let playerItem = Self.playerItem(playerData: [
            PlayerMetadataConstants.Id: "item-1",
            PlayerMetadataConstants.MimeType: "application/x-mpegURL",
            PlayerMetadataConstants.IsLive: "false",
            PlayerMetadataConstants.IsOffline: "true",
        ])

        let mediaItem = try XCTUnwrap(MediaItemMapper.mapPlayerItem(playerItem))

        XCTAssertEqual(mediaItem.id, "item-1")
        XCTAssertEqual(mediaItem.url, Self.contentUrl)
        XCTAssertEqual(mediaItem.mimeType, "application/x-mpegURL")
        XCTAssertEqual(mediaItem.isLive, NSNumber(value: false))
        XCTAssertEqual(mediaItem.isOffline, NSNumber(value: true))
    }

    /// Without an id in the metadata one is invented, so callers always get
    /// something — but it is not stable across calls, which is worth knowing
    /// before relying on it.
    func testFallsBackToAGeneratedId() throws {
        let first = try XCTUnwrap(MediaItemMapper.mapPlayerItem(Self.playerItem(playerData: [:])))
        let second = try XCTUnwrap(MediaItemMapper.mapPlayerItem(Self.playerItem(playerData: [:])))

        let firstId = try XCTUnwrap(first.id)
        XCTAssertFalse(firstId.isEmpty)
        XCTAssertNotNil(UUID(uuidString: firstId))
        XCTAssertNotEqual(firstId, second.id)
    }

    /// An asset that has not loaded has an indefinite duration, which is the same
    /// signal used for a live stream — so explicit player data has to win.
    func testExplicitIsLiveOverridesTheDurationHeuristic() throws {
        let unspecified = try XCTUnwrap(MediaItemMapper.mapPlayerItem(Self.playerItem(playerData: [:])))
        XCTAssertEqual(unspecified.isLive, NSNumber(value: true), "indefinite duration reads as live")

        let explicit = try XCTUnwrap(MediaItemMapper.mapPlayerItem(
            Self.playerItem(playerData: [PlayerMetadataConstants.IsLive: "false"])))
        XCTAssertEqual(explicit.isLive, NSNumber(value: false))
    }

    /// Anything other than the literal "true" is false — these are strings on the
    /// wire, not booleans.
    func testFlagsAreComparedAgainstTheLiteralTrue() throws {
        let mediaItem = try XCTUnwrap(MediaItemMapper.mapPlayerItem(Self.playerItem(playerData: [
            PlayerMetadataConstants.IsLive: "TRUE",
            PlayerMetadataConstants.IsOffline: "yes",
        ])))

        XCTAssertEqual(mediaItem.isLive, NSNumber(value: false))
        XCTAssertEqual(mediaItem.isOffline, NSNumber(value: false))
    }

    func testMapsStandardMetadataAndExtras() throws {
        let playerItem = Self.playerItem(
            playerData: [PlayerMetadataConstants.ArtworkUri: "https://example.com/art.jpg"],
            extras: ["episodeId": "abc", "showId": "def"],
            title: "Episode 1",
            artist: "The Artist")

        let mediaItem = try XCTUnwrap(MediaItemMapper.mapPlayerItem(playerItem))
        let metadata = try XCTUnwrap(mediaItem.metadata)

        XCTAssertEqual(metadata.title, "Episode 1")
        XCTAssertEqual(metadata.artist, "The Artist")
        XCTAssertEqual(metadata.artworkUri, "https://example.com/art.jpg")
        XCTAssertEqual(metadata.extras?["episodeId"], "abc")
        XCTAssertEqual(metadata.extras?["showId"], "def")
        // Player data is not extras, even though both travel as metadata.
        XCTAssertNil(metadata.extras?[PlayerMetadataConstants.ArtworkUri])
    }

    /// An unloaded asset has a non-finite duration, which must map to nil rather
    /// than to NaN crossing the channel.
    func testIndefiniteDurationIsReportedAsNil() throws {
        let mediaItem = try XCTUnwrap(MediaItemMapper.mapPlayerItem(Self.playerItem(playerData: [:])))

        XCTAssertNil(mediaItem.metadata?.durationMs)
    }

    // MARK: isOffline()

    func testIsOfflineReadsThePlayerDataFlag() {
        XCTAssertTrue(Self.playerItem(playerData: [PlayerMetadataConstants.IsOffline: "true"]).isOffline())
        XCTAssertFalse(Self.playerItem(playerData: [PlayerMetadataConstants.IsOffline: "false"]).isOffline())
        XCTAssertFalse(Self.playerItem(playerData: [:]).isOffline())
    }

    // MARK: Fixtures

    private static let contentUrl = "https://example.com/stream.m3u8"

    private static func playerItem(
        playerData: [String: String],
        extras: [String: String] = [:],
        title: String? = nil,
        artist: String? = nil
    ) -> AVPlayerItem {
        let item = AVPlayerItem(url: URL(string: contentUrl)!)

        var metadata: [AVMetadataItem] = []
        for (key, value) in playerData {
            if let entry = MetadataUtils.metadataItem(
                identifier: key, value: value as NSString, namespace: .BccmPlayer) {
                metadata.append(entry)
            }
        }
        for (key, value) in extras {
            if let entry = MetadataUtils.metadataItem(
                identifier: key, value: value as NSString, namespace: .BccmExtras) {
                metadata.append(entry)
            }
        }
        if let title = title {
            metadata.append(commonItem(identifier: .commonIdentifierTitle, value: title))
        }
        if let artist = artist {
            metadata.append(commonItem(identifier: .commonIdentifierArtist, value: artist))
        }

        item.externalMetadata = metadata
        return item
    }

    private static func commonItem(identifier: AVMetadataIdentifier, value: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as NSString
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }
}
