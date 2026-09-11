import XCTest

@testable import bccm_player

/// Pigeon encodes enums **by index**, not by name. Reordering a case in
/// `pigeons/*.dart` therefore changes the wire value on every platform while
/// everything still compiles and every regenerated side still agrees with
/// itself — so a consumer running a stale native build silently gets
/// `playing` where `paused` was meant.
///
/// These are tripwires, not descriptions: if one fails, either the change was
/// a mistake, or it is deliberate and the matching Dart and Kotlin
/// assertions must be updated in the same commit.
final class PigeonEnumOrdinalTests: XCTestCase {
    func testBufferModeOrdinals() {
        XCTAssertEqual(BufferMode.standard.rawValue, 0)
        XCTAssertEqual(BufferMode.fastStartShortForm.rawValue, 1)
    }

    func testRepeatModeOrdinals() {
        XCTAssertEqual(RepeatMode.off.rawValue, 0)
        XCTAssertEqual(RepeatMode.one.rawValue, 1)
    }

    func testPlaybackStateOrdinals() {
        XCTAssertEqual(PlaybackState.stopped.rawValue, 0)
        XCTAssertEqual(PlaybackState.paused.rawValue, 1)
        XCTAssertEqual(PlaybackState.playing.rawValue, 2)
    }

    func testCastConnectionStateOrdinals() {
        let noDevices: CastConnectionState = .noDevicesAvailable
        let notConnected: CastConnectionState = .notConnected
        let connecting: CastConnectionState = .connecting
        let connected: CastConnectionState = .connected
        XCTAssertEqual(CastConnectionState(rawValue: 0), CastConnectionState.none)
        XCTAssertEqual(noDevices.rawValue, 1)
        XCTAssertEqual(notConnected.rawValue, 2)
        XCTAssertEqual(connecting.rawValue, 3)
        XCTAssertEqual(connected.rawValue, 4)
    }

    func testTrackTypeOrdinals() {
        XCTAssertEqual(TrackType.audio.rawValue, 0)
        XCTAssertEqual(TrackType.text.rawValue, 1)
        XCTAssertEqual(TrackType.video.rawValue, 2)
    }

    func testDownloadStatusOrdinals() {
        XCTAssertEqual(DownloadStatus.downloading.rawValue, 0)
        XCTAssertEqual(DownloadStatus.paused.rawValue, 1)
        XCTAssertEqual(DownloadStatus.finished.rawValue, 2)
        XCTAssertEqual(DownloadStatus.failed.rawValue, 3)
        XCTAssertEqual(DownloadStatus.queued.rawValue, 4)
        XCTAssertEqual(DownloadStatus.removing.rawValue, 5)
        // Catches a case being added or removed rather than reordered.
        XCTAssertEqual(DownloadStatus.allCases.count, 6)
    }
}
