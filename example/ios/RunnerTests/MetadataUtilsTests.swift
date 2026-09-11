import AVFoundation
import XCTest

@testable import bccm_player

/**
 Player data and caller-supplied extras both ride along on `AVPlayerItem` as
 QuickTime metadata, separated only by a reverse-DNS namespace prefix
 (`media.bcc.player.*` vs `media.bcc.extras.*`).

 Nothing type-checks that separation — it is string prefix matching at both
 ends — so a change to how keys are written or parsed shows up as metadata
 quietly going missing rather than as a build error.
 */
final class MetadataUtilsTests: XCTestCase {

    func testRoundTripsNamespacedValues() throws {
        let items = [
            try XCTUnwrap(MetadataUtils.metadataItem(
                identifier: PlayerMetadataConstants.IsLive,
                value: "true" as NSString,
                namespace: .BccmPlayer)),
            try XCTUnwrap(MetadataUtils.metadataItem(
                identifier: PlayerMetadataConstants.MimeType,
                value: "application/x-mpegURL" as NSString,
                namespace: .BccmPlayer)),
        ]

        let parsed = MetadataUtils.getNamespacedMetadata(items, namespace: .BccmPlayer)

        XCTAssertEqual(parsed[PlayerMetadataConstants.IsLive], "true")
        XCTAssertEqual(parsed[PlayerMetadataConstants.MimeType], "application/x-mpegURL")
    }

    /// The two namespaces share one flat metadata array, so each must only ever
    /// see its own keys.
    func testNamespacesDoNotLeakIntoEachOther() throws {
        let items = [
            try XCTUnwrap(MetadataUtils.metadataItem(
                identifier: PlayerMetadataConstants.Id,
                value: "player-id" as NSString,
                namespace: .BccmPlayer)),
            try XCTUnwrap(MetadataUtils.metadataItem(
                identifier: "episode_id",
                value: "extras-id" as NSString,
                namespace: .BccmExtras)),
        ]

        let playerData = MetadataUtils.getNamespacedMetadata(items, namespace: .BccmPlayer)
        let extras = MetadataUtils.getNamespacedMetadata(items, namespace: .BccmExtras)

        XCTAssertEqual(playerData, [PlayerMetadataConstants.Id: "player-id"])
        XCTAssertEqual(extras, ["episode_id": "extras-id"])
    }

    /// Standard metadata (title, artist, artwork) lives in the same array and
    /// must not be mistaken for ours.
    func testIgnoresItemsOutsideTheNamespace() throws {
        let title = AVMutableMetadataItem()
        title.identifier = .commonIdentifierTitle
        title.value = "Episode 1" as NSString
        title.extendedLanguageTag = "und"

        let items = [
            try XCTUnwrap(title.copy() as? AVMetadataItem),
            try XCTUnwrap(MetadataUtils.metadataItem(
                identifier: PlayerMetadataConstants.IsOffline,
                value: "true" as NSString,
                namespace: .BccmPlayer)),
        ]

        let parsed = MetadataUtils.getNamespacedMetadata(items, namespace: .BccmPlayer)

        XCTAssertEqual(parsed, [PlayerMetadataConstants.IsOffline: "true"])
    }

    /// Values are read as strings; anything else is skipped rather than crashing
    /// on a force-cast.
    func testSkipsNonStringValues() throws {
        let items = [
            try XCTUnwrap(MetadataUtils.metadataItem(
                identifier: "numeric",
                value: NSNumber(value: 42),
                namespace: .BccmPlayer)),
            try XCTUnwrap(MetadataUtils.metadataItem(
                identifier: PlayerMetadataConstants.IsLive,
                value: "true" as NSString,
                namespace: .BccmPlayer)),
        ]

        let parsed = MetadataUtils.getNamespacedMetadata(items, namespace: .BccmPlayer)

        XCTAssertNil(parsed["numeric"])
        XCTAssertEqual(parsed[PlayerMetadataConstants.IsLive], "true")
    }

    func testNilValueProducesNoItem() {
        XCTAssertNil(MetadataUtils.metadataItem(
            identifier: PlayerMetadataConstants.IsLive,
            value: nil,
            namespace: .BccmPlayer))
    }

    func testEmptyInputProducesEmptyOutput() {
        XCTAssertTrue(MetadataUtils.getNamespacedMetadata([], namespace: .BccmPlayer).isEmpty)
    }

    /// The namespace strings are a wire contract with anything else reading this
    /// metadata, so they are pinned rather than derived.
    func testNamespaceValues() {
        XCTAssertEqual(MetadataNamespace.BccmPlayer.rawValue, "media.bcc.player")
        XCTAssertEqual(MetadataNamespace.BccmExtras.rawValue, "media.bcc.extras")
    }
}
