//
//  Downloader.swift
//  bccm_player
//
//  Created by Coen Jan Wessels on 05/09/2023.
//

import AVFoundation
import Combine

public class Downloader {
    static let identifier = "\(Bundle.main.bundleIdentifier!).Downloader"

    private let delegate = Delegate()
    private let session: AVAssetDownloadURLSession

    init() {
        let config = URLSessionConfiguration.background(withIdentifier: Downloader.identifier)
        session = AVAssetDownloadURLSession(configuration: config,
                                            assetDownloadDelegate: delegate,
                                            delegateQueue: OperationQueue.main)
    }
    
    public var changeEvents: any Subject<DownloadChangedEvent, Never> {
        delegate.changeEvents
    }

    public var removeEvents: any Subject<DownloadRemovedEvent, Never> {
        delegate.removeEvents
    }
    
    public var failEvents: any Subject<DownloadFailedEvent, Never> {
        delegate.failEvents
    }
    
    public func getAll() -> [Download] {
        for taskKV in UserDefaults.standard.downloaderState.tasks {
            if let path = taskKV.value.getUrlFromBookmark()?.path {
                if !FileManager.default.fileExists(atPath: path) {
                    do {
                        try remove(download: taskKV.key)
                    } catch {
                        debugPrint("Tried to remove nonexistent download, but failed. Key is: \(taskKV.key)")
                    }
                }
            }
        }
        return UserDefaults.standard.downloaderState.tasks.values.map { taskState in
            taskState.toDownloadModel()
        }
    }

    public func get(forKey key: String) -> Download? {
        UserDefaults.standard.downloaderState.tasks.values.first { $0.key.uuidString == key }?.toDownloadModel()
    }
    
    public func startDownload(config: DownloadConfig) throws -> Download {
        guard let url = URL(string: config.url) else {
            throw FlutterError(code: "invalid_url", message: "Passed url is invalid", details: "The passed url was \(config.url)")
        }
        
        let taskInput = DownloaderState.TaskInput(
            url: url,
            mimeType: config.mimeType,
            title: config.title,
            audioTrackIds: config.audioTrackIds,
            videoTrackIds: config.videoTrackIds,
            additionalData: config.additionalData
        )
        
        let taskState = DownloaderState.TaskState(key: UUID(), input: taskInput, statusCode: DownloadStatus.queued.rawValue)
        UserDefaults.standard.downloaderState = UserDefaults.standard.downloaderState.updateTask(task: taskState)
        
        let asset = AVURLAsset(url: url)
        
        let audioMediaSelections = try TrackUtils.getAVMediaSelectionsForAudio(asset, ids: config.audioTrackIds)
        let textMediaSelections = try TrackUtils.getAVMediaSelectionsForText(asset)
        let videoTracks = TrackUtils.getVideoTracksForAsset(asset, playerItem: nil)
        let videoTrack = videoTracks.first(where: { $0.id == config.videoTrackIds.first })
        
        var options: [String: Any] = [:]
        if videoTrack?.bitrate != nil {
            options[AVAssetDownloadTaskMinimumRequiredMediaBitrateKey] = videoTrack?.bitrate
        }
        
        var assetArtworkData: Data? = nil
        if let artworkUri = config.additionalData["artwork_uri"] {
            if let url = URL(string: artworkUri) {
                assetArtworkData = try? Data(contentsOf: url)
            }
        }
        
        guard let downloadTask = session.aggregateAssetDownloadTask(
            with: asset,
            mediaSelections: audioMediaSelections + textMediaSelections,
            assetTitle: config.title,
            assetArtworkData: assetArtworkData,
            options: options
        ) else {
            throw FlutterError(code: "download_task_null", message: "Failed to create download task", details: nil)
        }
        
        downloadTask.taskDescription = taskState.key.uuidString
        downloadTask.resume()
        
        return taskState.toDownloadModel()
    }
    
    public func progress(forKey key: String) async throws -> Double {
        guard let task = UserDefaults.standard.downloaderState.tasks[key] else {
            throw FlutterError(code: "unknown_key", message: "Unknown download key/id: \(key)", details: nil)
        }
        
        if task.statusCode == DownloadStatus.finished.rawValue {
            return 1
        }
        
        let urlSessionTask = await session.allTasks.first {
            $0.taskDescription == key
        }
        
        return urlSessionTask?.progress.fractionCompleted ?? 0 // TODO: Error message?
    }
    
    public func remove(download key: String) throws {
        var state = UserDefaults.standard.downloaderState
        
        guard let taskState = state.tasks[key] else {
            throw FlutterError(code: "unknown_key", message: "Unknown download key/id: \(key)", details: nil)
        }

        if let path = taskState.getUrlFromBookmark()?.path {
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(atPath: path)
            }
        }
        
        state.tasks.removeValue(forKey: key)
        UserDefaults.standard.downloaderState = state
        delegate.removeEvents.send(
            DownloadRemovedEvent.make(withKey: key)
        )
    }

    public class Delegate: NSObject, AVAssetDownloadDelegate {
        public let changeEvents = PassthroughSubject<DownloadChangedEvent, Never>()
        public let removeEvents = PassthroughSubject<DownloadRemovedEvent, Never>()
        public let failEvents = PassthroughSubject<DownloadFailedEvent, Never>()

        public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
            var state = UserDefaults.standard.downloaderState
            
            guard let downloadKey = aggregateAssetDownloadTask.taskDescription, var taskState = state.tasks[downloadKey] else {
                return
            }

            taskState.tempOfflineUrl = location
            UserDefaults.standard.downloaderState = state.updateTask(task: taskState)
            
            changeEvents.send(
                DownloadChangedEvent.make(with: taskState.toDownloadModel())
            )
        }
        
        public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
            guard let downloadKey = aggregateAssetDownloadTask.taskDescription, var taskState = UserDefaults.standard.downloaderState.tasks[downloadKey] else {
                return
            }
            
            let progress = loadedTimeRanges.reduce(0.0) { result, value in
                result + (value.timeRangeValue.duration.seconds / timeRangeExpectedToLoad.duration.seconds)
            }
            if aggregateAssetDownloadTask.state == .running {
                taskState.statusCode = DownloadStatus.downloading.rawValue
                taskState.progress = min(max(progress, 0), 1)
            }
            if progress >= 1.0 || aggregateAssetDownloadTask.state == .completed {
                taskState.statusCode = DownloadStatus.finished.rawValue
                taskState.progress = 1.0
            }
            
            if taskState.bookmark == nil {
                do {
                    taskState.bookmark = try taskState.tempOfflineUrl?.bookmarkData()
                } catch {
                    print("Failed to save bookmark: \(error)")
                }
            }
            
            UserDefaults.standard.downloaderState = UserDefaults.standard.downloaderState.updateTask(task: taskState)
            
            changeEvents.send(DownloadChangedEvent.make(with: taskState.toDownloadModel()))
        }
        
        public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
            print("didFinishDownloadingTo")
        }
        
        public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            var state = UserDefaults.standard.downloaderState
            
            guard let downloadKey = task.taskDescription, var taskState = state.tasks[downloadKey] else {
                return
            }
            
            if let error = error {
                if let path = taskState.getUrlFromBookmark()?.path {
                    if FileManager.default.fileExists(atPath: path) {
                        do {
                            try FileManager.default.removeItem(atPath: path)
                        } catch {}
                    }
                }
                taskState.statusCode = DownloadStatus.failed.rawValue
                taskState.error = error.localizedDescription
                failEvents.send(DownloadFailedEvent.make(withKey: taskState.key.uuidString, error: error.localizedDescription))
            } else {
                if taskState.bookmark == nil {
                    do {
                        taskState.bookmark = try taskState.tempOfflineUrl?.bookmarkData()
                    } catch let e {
                        taskState.error = e.localizedDescription
                    }
                }
                if taskState.bookmark != nil {
                    taskState.statusCode = DownloadStatus.finished.rawValue
                } else {
                    taskState.statusCode = DownloadStatus.failed.rawValue
                }
            }
            UserDefaults.standard.downloaderState = state.updateTask(task: taskState)
            changeEvents.send(DownloadChangedEvent.make(with: taskState.toDownloadModel()))
        }
    }
}

extension UserDefaults {
    func codable<T>(forKey key: String) -> T? where T: Decodable {
        guard let data = data(forKey: key) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: data)
    }
    
    func set<T>(encodable value: T?, forKey key: String) where T: Encodable {
        guard let value else {
            return removeObject(forKey: key)
        }

        let encoder = JSONEncoder()
        set(try? encoder.encode(value), forKey: key)
    }
    
    var downloaderState: DownloaderState {
        get { codable(forKey: Downloader.identifier) ?? DownloaderState(tasks: [:]) }
        set { set(encodable: newValue, forKey: Downloader.identifier) }
    }
}
