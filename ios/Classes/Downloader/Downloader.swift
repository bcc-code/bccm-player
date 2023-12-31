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
    static var session: AVAssetDownloadURLSession?

    init() {
        if Downloader.session != nil {
            debugPrint("static downloader session already exists")
            return
        }
        let config = URLSessionConfiguration.background(withIdentifier: Downloader.identifier)
        config.networkServiceType = .video
        config.isDiscretionary = false
        config.allowsCellularAccess = true
        
        Downloader.session = AVAssetDownloadURLSession(configuration: config,
                                                       assetDownloadDelegate: delegate,
                                                       delegateQueue: OperationQueue.main)

        // We cant resume a task anyway, so lets just clean up old tasks every restart
        // This is also to prevent a bug where new tasks can get stuck at 0% (not starting properly), reproducable when many (15 ish?) tasks are stuck in an active state.
        Downloader.session!.getAllTasks(completionHandler: { tasks in
            for task in tasks {
                task.cancel()
            }
        })
    }
    
    var changeEvents: any Subject<DownloadChangedEvent, Never> {
        delegate.changeEvents
    }

    var removeEvents: any Subject<DownloadRemovedEvent, Never> {
        delegate.removeEvents
    }
    
    var failEvents: any Subject<DownloadFailedEvent, Never> {
        delegate.failEvents
    }
    
    func getAll() -> [Download] {
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

    func get(forKey key: String) -> Download? {
        UserDefaults.standard.downloaderState.tasks.values.first { $0.key.uuidString == key }?.toDownloadModel()
    }
    
    func startDownload(config: DownloadConfig) async throws -> Download {
        guard let url = URL(string: config.url) else {
            throw FlutterError(code: "invalid_url", message: "Passed url is invalid", details: "The passed url was \(config.url)")
        }
        
        let taskInput = DownloaderState.TaskInput(
            url: url,
            mimeType: config.mimeType,
            title: config.title,
            audioTrackIds: config.audioTrackIds.compactMap { $0 },
            videoTrackIds: config.videoTrackIds.compactMap { $0 },
            additionalData: config.additionalData.removeNil()
        )
        
        let taskState = DownloaderState.TaskState(key: UUID(), input: taskInput, statusCode: DownloadStatus.queued.rawValue)
        UserDefaults.standard.downloaderState = UserDefaults.standard.downloaderState.updateTask(task: taskState)
        
        let asset = AVURLAsset(url: url)
        
        let audioMediaSelections = try TrackUtils.getAVMediaSelectionsForAudio(asset, ids: config.audioTrackIds.compactMap { $0 })
        let textMediaSelections = try TrackUtils.getAVMediaSelectionsForText(asset)
        let videoTracks = TrackUtils.getVideoTracksForAsset(asset, playerItem: nil)
        let videoTrack = videoTracks.first(where: { $0.id == config.videoTrackIds.first })
        
        var options: [String: Any] = [:]
        if videoTrack?.bitrate != nil {
            options[AVAssetDownloadTaskMinimumRequiredMediaBitrateKey] = videoTrack?.bitrate
        }
        
        var assetArtworkData: Data? = nil
        if let artworkUri = config.additionalData.removeNil()["artwork_uri"] {
            if let url = URL(string: artworkUri) {
                assetArtworkData = try await getData(from: url)
            }
        }
        
        let downloadTask = Downloader.session!.aggregateAssetDownloadTask(
            with: asset,
            mediaSelections: audioMediaSelections + textMediaSelections,
            assetTitle: config.title,
            assetArtworkData: assetArtworkData,
            options: options
        )
        guard let downloadTask = downloadTask else {
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
        
        let urlSessionTask = await Downloader.session!.allTasks.first {
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
            DownloadRemovedEvent(key: key)
        )
    }

    public class Delegate: NSObject, AVAssetDownloadDelegate {
        let changeEvents = PassthroughSubject<DownloadChangedEvent, Never>()
        let removeEvents = PassthroughSubject<DownloadRemovedEvent, Never>()
        let failEvents = PassthroughSubject<DownloadFailedEvent, Never>()

        public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
            var state = UserDefaults.standard.downloaderState
            
            guard let downloadKey = aggregateAssetDownloadTask.taskDescription, var taskState = state.tasks[downloadKey] else {
                return
            }

            taskState.tempOfflineUrl = location
            UserDefaults.standard.downloaderState = state.updateTask(task: taskState)
            
            changeEvents.send(
                DownloadChangedEvent(download: taskState.toDownloadModel())
            )
        }
        
        public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
            debugPrint("taskIsWaitingForConnectivity")
        }
        
        public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            debugPrint("didBecomeInvalidWithError")
        }
        
        public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didCompleteFor mediaSelection: AVMediaSelection) {
            debugPrint("didCompleteFor \(mediaSelection.debugDescription)")
        }
        
        public func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
            debugPrint("didCreateTask")
        }
        
        public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
            guard let downloadKey = aggregateAssetDownloadTask.taskDescription, var taskState = UserDefaults.standard.downloaderState.tasks[downloadKey] else {
                return
            }
            
            var progress = 0.0
            for value in loadedTimeRanges where timeRangeExpectedToLoad.duration.seconds > 0 {
                let loadedTimeRange = value.timeRangeValue
                progress += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
            }
            taskState.progress = min(max(progress, 0), 1)
            
            if aggregateAssetDownloadTask.state == .running {
                taskState.statusCode = DownloadStatus.downloading.rawValue
            }
            if aggregateAssetDownloadTask.state == .completed {
                taskState.statusCode = DownloadStatus.finished.rawValue
                taskState.progress = 1.0
            }
            
            if taskState.progress == 1.0 {
                debugPrint(taskState.progress)
                debugPrint(aggregateAssetDownloadTask.state.rawValue)
            }
            
            if taskState.bookmark == nil {
                do {
                    taskState.bookmark = try taskState.tempOfflineUrl?.bookmarkData()
                } catch {
                    print("Failed to save bookmark: \(error)")
                }
            }
            
            UserDefaults.standard.downloaderState = UserDefaults.standard.downloaderState.updateTask(task: taskState)
            
            changeEvents.send(DownloadChangedEvent(download: taskState.toDownloadModel()))
        }
        
        public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
            print("didFinishDownloadingTo")
        }
        
        public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            debugPrint("didCompleteWithError: \(task.progress.debugDescription), \(error?.localizedDescription ?? "nil")")
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
                failEvents.send(DownloadFailedEvent(key: taskState.key.uuidString, error: error.localizedDescription))
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
            changeEvents.send(DownloadChangedEvent(download: taskState.toDownloadModel()))
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
