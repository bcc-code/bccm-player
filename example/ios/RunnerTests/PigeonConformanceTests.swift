import XCTest

@testable import bccm_player

/// Compile-time guards on the shape of the Pigeon-generated Swift APIs.
///
/// Pigeon has silently reshaped these before: v22 -> v28 moved `@async` host
/// APIs from completion handlers to `async throws`, which broke every
/// hand-written implementation without a single Dart test noticing. Nothing
/// in `flutter test` or `flutter analyze` compiles Swift, so the build was
/// the only thing that caught it — and only if someone happened to build iOS.
///
/// These references make that breakage a test-suite failure instead. Most of
/// the value is in whether this file *compiles*; the assertions are almost
/// incidental.
final class PigeonConformanceTests: XCTestCase {
    /// `DownloaderApiImpl` must satisfy the generated `DownloaderPigeon`
    /// protocol. This is exactly what broke on the v28 regeneration.
    func testDownloaderApiImplConformsToGeneratedProtocol() {
        XCTAssertTrue(DownloaderApiImpl.self is DownloaderPigeon.Type)
    }

    /// `PlaybackApiImpl` must satisfy the generated (Objective-C)
    /// `PlaybackPlatformPigeon` protocol.
    func testPlaybackApiImplConformsToGeneratedProtocol() {
        XCTAssertTrue(PlaybackApiImpl.self is PlaybackPlatformPigeon.Type)
    }

    /// The downloader listener must stay `async throws`. `SwiftBccmPlayerPlugin`
    /// calls these from synchronous Combine sinks via `Task { try? await ... }`;
    /// if codegen reverts to completion handlers this stops compiling here as
    /// well as there.
    func testDownloaderListenerIsAsync() async throws {
        func requireAsyncShape(_ listener: any DownloaderListenerPigeonProtocol) async throws {
            try await listener.onDownloadStatusChanged(
                event: DownloadChangedEvent(download: Self.sampleDownload))
            try await listener.onDownloadRemoved(
                event: DownloadRemovedEvent(key: "key"))
            try await listener.onDownloadFailed(
                event: DownloadFailedEvent(key: "key", error: "boom"))
        }
        XCTAssertNotNil(requireAsyncShape)
    }

    /// The downloader host API must stay `async throws` and keep its return
    /// types. Referencing every method pins the full signature set.
    func testDownloaderHostApiIsAsync() async throws {
        func requireAsyncShape(_ api: any DownloaderPigeon) async throws {
            _ = try await api.startDownload(downloadConfig: Self.sampleConfig)
            _ = try await api.getDownloadStatus(downloadKey: "key")
            _ = try await api.getDownloads()
            _ = try await api.getDownload(downloadKey: "key")
            try await api.removeDownload(downloadKey: "key")
            _ = try await api.getFreeDiskSpace()
        }
        XCTAssertNotNil(requireAsyncShape)
    }

    static let sampleConfig = DownloadConfig(
        url: "https://example.com/stream.m3u8",
        mimeType: "application/x-mpegURL",
        title: "Sample",
        audioTrackIds: ["no"],
        videoTrackIds: ["720"],
        additionalData: ["k": "v"])

    static let sampleDownload = Download(
        key: "key",
        config: sampleConfig,
        offlineUrl: nil,
        fractionDownloaded: 0.5,
        status: .downloading,
        error: nil)
}
