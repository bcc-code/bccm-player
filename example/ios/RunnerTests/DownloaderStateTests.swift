import XCTest

@testable import bccm_player

/**
 The downloader's entire state is a `Codable` blob in `UserDefaults`, and every
 read goes through an accessor that swallows decode errors:

 ```swift
 var downloaderState: DownloaderState {
     get { codable(forKey: Downloader.identifier) ?? DownloaderState(tasks: [:]) }
 }
 ```

 `codable(forKey:)` decodes with `try?`. So any incompatible change to this
 schema — a renamed property, a changed type, a new non-optional field — does
 not fail loudly. It returns nil, falls back to an empty state, and every
 download in the user's library silently disappears while the files stay
 orphaned on disk.

 `decodesAPinnedPayload` is the guard that matters: it decodes a literal JSON
 document captured from the current schema, so a breaking change fails here
 instead of in someone's app after an upgrade.
 */
final class DownloaderStateTests: XCTestCase {

    // MARK: Schema

    /// A payload written by the current schema. Changing this to make a failing
    /// test pass means accepting that existing downloads will be dropped — add a
    /// migration instead, or make the new field optional.
    private static let pinnedPayload = """
    {
      "tasks": {
        "3F2504E0-4F89-11D3-9A0C-0305E82C3301": {
          "key": "3F2504E0-4F89-11D3-9A0C-0305E82C3301",
          "input": {
            "url": "https://example.com/stream.m3u8",
            "mimeType": "application/x-mpegURL",
            "title": "Episode 1",
            "audioTrackIds": ["no", "en"],
            "videoTrackIds": ["720"],
            "additionalData": { "episodeId": "abc" }
          },
          "statusCode": 2,
          "progress": 1.0
        }
      }
    }
    """

    func testDecodesAPinnedPayload() throws {
        let state = try JSONDecoder().decode(
            DownloaderState.self,
            from: Data(Self.pinnedPayload.utf8))

        let task = try XCTUnwrap(state.tasks["3F2504E0-4F89-11D3-9A0C-0305E82C3301"])
        XCTAssertEqual(task.key.uuidString, "3F2504E0-4F89-11D3-9A0C-0305E82C3301")
        XCTAssertEqual(task.input.url.absoluteString, "https://example.com/stream.m3u8")
        XCTAssertEqual(task.input.mimeType, "application/x-mpegURL")
        XCTAssertEqual(task.input.title, "Episode 1")
        XCTAssertEqual(task.input.audioTrackIds, ["no", "en"])
        XCTAssertEqual(task.input.videoTrackIds, ["720"])
        XCTAssertEqual(task.input.additionalData, ["episodeId": "abc"])
        XCTAssertEqual(task.statusCode, DownloadStatus.finished.rawValue)
        XCTAssertEqual(task.progress, 1.0, accuracy: 0.0001)
        // Absent optionals decode as nil rather than failing the whole document.
        XCTAssertNil(task.tempOfflineUrl)
        XCTAssertNil(task.bookmark)
        XCTAssertNil(task.error)
    }

    func testRoundTripsThroughJSON() throws {
        let original = DownloaderState(tasks: ["a": Self.sampleTask(progress: 0.25)])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DownloaderState.self, from: encoded)

        let task = try XCTUnwrap(decoded.tasks["a"])
        XCTAssertEqual(task.key, Self.sampleKey)
        XCTAssertEqual(task.input.title, "Episode 1")
        XCTAssertEqual(task.input.additionalData, ["episodeId": "abc"])
        XCTAssertEqual(task.progress, 0.25, accuracy: 0.0001)
        XCTAssertEqual(task.statusCode, DownloadStatus.downloading.rawValue)
    }

    /// Demonstrates the fallback the pinned-payload test exists to protect:
    /// unreadable state is indistinguishable from no state at all.
    func testUnreadablePersistedStateIsSilentlyDiscarded() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: #function))
        defer { defaults.removePersistentDomain(forName: #function) }

        defaults.set(Data("not json".utf8), forKey: "state")
        let recovered: DownloaderState? = defaults.codable(forKey: "state")

        XCTAssertNil(recovered, "a decode failure yields nil, which the caller turns into an empty library")
    }

    func testPersistsThroughUserDefaults() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: #function))
        defer { defaults.removePersistentDomain(forName: #function) }

        defaults.set(encodable: DownloaderState(tasks: ["a": Self.sampleTask()]), forKey: "state")
        let recovered: DownloaderState? = defaults.codable(forKey: "state")

        XCTAssertEqual(recovered?.tasks["a"]?.input.title, "Episode 1")
    }

    // MARK: Task bookkeeping

    func testUpdateTaskInsertsAndReplacesByKey() {
        var state = DownloaderState(tasks: [:])

        _ = state.updateTask(task: Self.sampleTask(progress: 0.1))
        XCTAssertEqual(state.tasks.count, 1)
        XCTAssertEqual(state.tasks[Self.sampleKey.uuidString]?.progress, 0.1)

        _ = state.updateTask(task: Self.sampleTask(progress: 0.9))
        XCTAssertEqual(state.tasks.count, 1, "the same key updates in place rather than duplicating")
        XCTAssertEqual(state.tasks[Self.sampleKey.uuidString]?.progress, 0.9)
    }

    // MARK: Mapping to the pigeon model

    func testMapsToTheDownloadModel() {
        let download = Self.sampleTask(progress: 0.5).toDownloadModel()

        XCTAssertEqual(download.key, Self.sampleKey.uuidString)
        XCTAssertEqual(download.config.url, "https://example.com/stream.m3u8")
        XCTAssertEqual(download.config.mimeType, "application/x-mpegURL")
        XCTAssertEqual(download.config.title, "Episode 1")
        XCTAssertEqual(download.config.audioTrackIds, ["no", "en"])
        XCTAssertEqual(download.config.videoTrackIds, ["720"])
        XCTAssertEqual(download.fractionDownloaded, 0.5, accuracy: 0.0001)
        XCTAssertEqual(download.status, .downloading)
        XCTAssertNil(download.error)
        // No bookmark resolved yet, so there is nothing to play offline.
        XCTAssertNil(download.offlineUrl)
    }

    func testEveryStatusCodeSurvivesTheMapping() {
        for status in DownloadStatus.allCases {
            let download = Self.sampleTask(statusCode: status.rawValue).toDownloadModel()
            XCTAssertEqual(download.status, status)
        }
    }

    /// A status code we no longer recognise (an enum case removed or reordered
    /// while state from an older build is still on disk) reads as failed, not as
    /// a crash.
    func testUnknownStatusCodeBecomesFailed() {
        let download = Self.sampleTask(statusCode: 9999).toDownloadModel()

        XCTAssertEqual(download.status, .failed)
    }

    func testErrorIsCarriedThrough() {
        var task = Self.sampleTask(statusCode: DownloadStatus.failed.rawValue)
        task.error = "disk full"

        let download = task.toDownloadModel()

        XCTAssertEqual(download.status, .failed)
        XCTAssertEqual(download.error, "disk full")
    }

    // MARK: Fixtures

    private static let sampleKey = UUID(uuidString: "3F2504E0-4F89-11D3-9A0C-0305E82C3301")!

    private static func sampleTask(
        statusCode: Int = DownloadStatus.downloading.rawValue,
        progress: Double = 0.0
    ) -> DownloaderState.TaskState {
        DownloaderState.TaskState(
            key: sampleKey,
            input: DownloaderState.TaskInput(
                url: URL(string: "https://example.com/stream.m3u8")!,
                mimeType: "application/x-mpegURL",
                title: "Episode 1",
                audioTrackIds: ["no", "en"],
                videoTrackIds: ["720"],
                additionalData: ["episodeId": "abc"]),
            statusCode: statusCode,
            progress: progress)
    }
}
