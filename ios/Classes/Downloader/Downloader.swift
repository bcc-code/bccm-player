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
    
    public var statusChanged: any Subject<DownloadStatusChangedEvent, Never> {
        delegate.statusChanged
    }
    
    public func getAll() -> [Download] {
        UserDefaults.standard.downloaderState.tasks.values.map { taskState in
            taskState.download
        }
    }

    public func get(forKey key: String) -> Download? {
        UserDefaults.standard.downloaderState.tasks.values.first { $0.key.uuidString == key }?.download
    }
    
    public func startDownload(config: DownloadConfig) throws -> Download {
        guard let url = URL(string: config.url) else {
            throw DownloaderError.invalidUrl(url: config.url)
        }
        
        let taskInput = DownloaderState.TaskInput(
            url: url,
            mimeType: config.mimeType,
            title: config.title,
            audioTrackIds: config.audioTrackIds,
            videoTrackIds: config.videoTrackIds,
            additionalData: config.additionalData
        )
        
        var state = UserDefaults.standard.downloaderState
        let taskState = state.add(input: taskInput)
        UserDefaults.standard.downloaderState = state
        
        let asset = AVURLAsset(url: url)
        
        let mediaSelections = try TrackUtils.getAVMediaSelectionsForAudio(asset, ids: config.audioTrackIds)
        if let downloadTask = session.aggregateAssetDownloadTask(with: asset, mediaSelections: mediaSelections, assetTitle: config.title, assetArtworkData: nil) {
            downloadTask.taskDescription = taskState.key.uuidString
            downloadTask.resume()
        }

        return taskState.download
    }
    
    public func status(forKey key: String) async throws -> Double {
        guard let task = UserDefaults.standard.downloaderState.tasks[key] else {
            throw DownloaderError.unknownDownloadKey(key: key)
        }
        
        if task.finished {
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
            throw DownloaderError.unknownDownloadKey(key: key)
        }

        if let url = taskState.offlineUrl {
            if FileManager.default.fileExists(atPath: url.absoluteString) {
                try FileManager.default.removeItem(at: url)
            }
        }
        
        state.tasks.removeValue(forKey: key)
        UserDefaults.standard.downloaderState = state
    }

    public class Delegate: NSObject, AVAssetDownloadDelegate {
        public let statusChanged = PassthroughSubject<DownloadStatusChangedEvent, Never>()

        public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
            var state = UserDefaults.standard.downloaderState
            
            guard let downloadKey = aggregateAssetDownloadTask.taskDescription, var taskState = state.tasks[downloadKey] else {
                return
            }

            taskState.offlineUrl = location
            state.update(task: taskState)
            UserDefaults.standard.downloaderState = state
            
            statusChanged.send(
                DownloadStatusChangedEvent.make(
                    with: taskState.download,
                    progress: NSNumber(value: 0.0)
                )
            )
        }
        
        public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
            guard let downloadKey = aggregateAssetDownloadTask.taskDescription, let taskState = UserDefaults.standard.downloaderState.tasks[downloadKey] else {
                return
            }
            
            let progress = loadedTimeRanges.reduce(0.0) { result, value in
                result + (value.timeRangeValue.duration.seconds / timeRangeExpectedToLoad.duration.seconds)
            }
            
            statusChanged.send(
                DownloadStatusChangedEvent.make(
                    with: taskState.download,
                    progress: NSNumber(value: progress)
                )
            )
        }
        
        public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
            print("didFinishDownloadingTo")
        }
        
        public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            var state = UserDefaults.standard.downloaderState
            
            guard let downloadKey = task.taskDescription, var taskState = state.tasks[downloadKey] else {
                return
            }

            if error == nil {
                taskState.finished = true
                do {
                    taskState.bookmark = try taskState.offlineUrl?.bookmarkData()
                } catch {
                    print("Some error \(error)")
                }
                state.update(task: taskState)
            }
            
            UserDefaults.standard.downloaderState = state
            
            statusChanged.send(DownloadStatusChangedEvent.make(with: taskState.download, progress: NSNumber(value: 1.0)))
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
