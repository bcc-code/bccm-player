import Flutter
import XCTest

@testable import bccm_player

/// Round-trips every shape we care about through the generated codecs.
///
/// This pins two things a compile cannot: the **type identifier** each class
/// is written with (drift here corrupts data between a Dart side and a native
/// side that were regenerated at different times), and the **field order**
/// inside `toList`/`fromList` — a reordered field survives encode/decode as a
/// value of the wrong property, which no type checker will notice.
///
/// These assertions only became possible with Pigeon v28, which added value
/// equality to the generated classes. Under v22 they compared by identity and
/// would have passed vacuously.
final class PigeonCodecTests: XCTestCase {

    // MARK: - Objective-C generated types (playback API)

    private var playbackCodec: any FlutterMessageCodec { nullGetPlaybackPlatformApiCodec() }

    func testMediaItemRoundTrip() throws {
        let item = Self.sampleMediaItem
        let data = try XCTUnwrap(playbackCodec.encode(item))
        let decoded = try XCTUnwrap(playbackCodec.decode(data) as? MediaItem)

        XCTAssertEqual(decoded, item)
        // Spot-check individual fields too: `isEqual:` is itself generated, so
        // a codegen bug could in principle break both symmetrically.
        XCTAssertEqual(decoded.id, "item-id")
        XCTAssertEqual(decoded.url, "https://example.com/stream.m3u8")
        XCTAssertEqual(decoded.metadata?.title, "Sample title")
        XCTAssertEqual(decoded.metadata?.extras?["key"], "value")
        XCTAssertEqual(decoded.lastKnownAudioLanguage, "no")
        XCTAssertEqual(decoded.lastKnownSubtitleLanguage, "en")
    }

    func testTrackRoundTrip() throws {
        let track = Track.make(
            withId: "track-1",
            label: "Norsk",
            language: "no",
            frameRate: nil,
            bitrate: NSNumber(value: 128_000),
            width: nil,
            height: nil,
            downloaded: NSNumber(value: false),
            isSelected: true)

        let data = try XCTUnwrap(playbackCodec.encode(track))
        let decoded = try XCTUnwrap(playbackCodec.decode(data) as? Track)

        XCTAssertEqual(decoded, track)
        XCTAssertTrue(decoded.isSelected)
        XCTAssertEqual(decoded.downloaded, NSNumber(value: false))
    }

    func testPlayerStateSnapshotRoundTrip() throws {
        let snapshot = PlayerStateSnapshot.make(
            withPlayerId: "player-1",
            playbackState: .playing,
            isBuffering: false,
            isFullscreen: false,
            playbackSpeed: 1.0,
            videoSize: VideoSize.make(withWidth: 1920, height: 1080),
            currentMediaItem: Self.sampleMediaItem,
            playbackPositionMs: NSNumber(value: 12_345.0),
            textureId: nil,
            volume: NSNumber(value: 0.8),
            error: nil,
            seekableRangeStartMs: NSNumber(value: 1000.0),
            seekableRangeEndMs: NSNumber(value: 99_000.0))

        let data = try XCTUnwrap(playbackCodec.encode(snapshot))
        let decoded = try XCTUnwrap(playbackCodec.decode(data) as? PlayerStateSnapshot)

        XCTAssertEqual(decoded, snapshot)
        // The seekable range is the pair the live-edge UI depends on, and the
        // two fields sit next to each other — exactly the shape a field
        // reorder would swap unnoticed.
        XCTAssertEqual(decoded.seekableRangeStartMs, NSNumber(value: 1000.0))
        XCTAssertEqual(decoded.seekableRangeEndMs, NSNumber(value: 99_000.0))
    }

    /// The first byte of an encoded value is the Pigeon type identifier.
    /// These are assigned by declaration order in the `.dart` pigeon file, so
    /// inserting a class in the middle renumbers everything after it.
    func testTypeIdentifiersAreStable() throws {
        func typeIdentifier(of value: Any) throws -> UInt8 {
            let data = try XCTUnwrap(playbackCodec.encode(value))
            return try XCTUnwrap(data.first)
        }

        XCTAssertEqual(try typeIdentifier(of: Self.sampleMediaItem), 138)
        XCTAssertEqual(
            try typeIdentifier(of: MediaMetadata.make(
                withArtworkUri: nil, title: nil, artist: nil, durationMs: nil, extras: nil)),
            139)
        XCTAssertEqual(
            try typeIdentifier(of: VideoSize.make(withWidth: 1, height: 1)),
            142)
    }

    // MARK: - Swift generated types (downloader API)

    func testDownloadRoundTrip() throws {
        let codec = DownloaderApiPigeonCodec.shared
        let download = Download(
            key: "download-key",
            config: DownloadConfig(
                url: "https://example.com/stream.m3u8",
                mimeType: "application/x-mpegURL",
                title: "Sample",
                audioTrackIds: ["no", "en"],
                videoTrackIds: ["720"],
                additionalData: ["key": "value"]),
            offlineUrl: "file:///offline/stream",
            fractionDownloaded: 0.42,
            status: .downloading,
            error: nil)

        let data = try XCTUnwrap(codec.encode(download))
        let decoded = try XCTUnwrap(codec.decode(data) as? Download)

        XCTAssertEqual(decoded, download)
        XCTAssertEqual(decoded.status, .downloading)
        XCTAssertEqual(decoded.fractionDownloaded, 0.42, accuracy: 0.0001)
        XCTAssertEqual(decoded.config.audioTrackIds.count, 2)
    }

    func testDownloadEventsRoundTrip() throws {
        let codec = DownloaderApiPigeonCodec.shared

        let removed = DownloadRemovedEvent(key: "gone")
        let removedData = try XCTUnwrap(codec.encode(removed))
        XCTAssertEqual(try XCTUnwrap(codec.decode(removedData) as? DownloadRemovedEvent), removed)

        let failed = DownloadFailedEvent(key: "bad", error: "network")
        let failedData = try XCTUnwrap(codec.encode(failed))
        XCTAssertEqual(try XCTUnwrap(codec.decode(failedData) as? DownloadFailedEvent), failed)
    }

    // MARK: - Fixtures

    static let sampleMediaItem = MediaItem.make(
        withId: "item-id",
        url: "https://example.com/stream.m3u8",
        mimeType: "application/x-mpegURL",
        metadata: MediaMetadata.make(
            withArtworkUri: "https://example.com/art.jpg",
            title: "Sample title",
            artist: "Sample artist",
            durationMs: NSNumber(value: 60_000.0),
            extras: ["key": "value"]),
        isLive: NSNumber(value: true),
        isOffline: NSNumber(value: false),
        playbackStartPositionMs: NSNumber(value: 42.0),
        lastKnownAudioLanguage: "no",
        lastKnownSubtitleLanguage: "en")
}
