//
//  DownloaderState.swift
//  bccm_player
//
//  Created by Coen Jan Wessels on 05/09/2023.
//

public struct DownloaderState: Codable {
    public struct Track: Codable {
        public let id: String
        public let label: String?
        public let language: String?
        public let frameRate: Double?
        public let bitrate: Int?
        public let width: Int?
        public let height: Int?
        public let isSelected: Bool
    }

    public struct TaskInput: Codable {
        public let url: URL
        public let mimeType: String
        public let title: String
        public let audioTrackIds: [String]
        public let videoTrackIds: [String]
        public let additionalData: [String: String]
    }

    public struct TaskState: Codable {
        public let key: UUID
        public let input: TaskInput
        public var offlineUrl: URL? = nil
        public var bookmark: Data? = nil
        public var finished: Bool = false
        public var progress: Double = 0.0
    }

    var tasks: [String: TaskState]

    mutating func add(input: TaskInput) -> TaskState {
        let task = TaskState(key: UUID(), input: input)
        updateTask(task: task)
        return task
    }

    mutating func updateTask(task: TaskState) -> DownloaderState {
        tasks[task.key.uuidString] = task
        return self
    }
}

extension DownloaderState.TaskInput {
    var downloadConfig: DownloadConfig {
        DownloadConfig.make(withUrl: url.absoluteString,
                            mimeType: mimeType,
                            title: title,
                            audioTrackIds: audioTrackIds,
                            videoTrackIds: videoTrackIds,
                            additionalData: additionalData)
    }
}

extension DownloaderState.TaskState {
    func toDownloadModel() -> Download {
        let url = bookmark.flatMap {
            var staleBookmark = false
            let url = try? URL(resolvingBookmarkData: $0, bookmarkDataIsStale: &staleBookmark)
            return url?.absoluteString
        }
        var status: DownloadStatus = .downloading
        if progress == 1.0 {
            status = .finished
        }
        return Download.make(withKey: key.uuidString,
                             config: input.downloadConfig,
                             offlineUrl: url,
                             fractionDownloaded: progress as NSNumber,
                             status: .downloading)
    }
}
