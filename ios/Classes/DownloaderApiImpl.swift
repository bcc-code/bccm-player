
class DownloaderApiImpl: NSObject, DownloaderPigeon {
    public let downloader: Downloader

    init(downloader: Downloader) {
        self.downloader = downloader
    }

    func startDownload(downloadConfig: DownloadConfig, completion: @escaping (Result<Download, Error>) -> Void) {
        completion(Result(catching: {
            try downloader.startDownload(config: downloadConfig)
        }))
    }

    func getDownloadStatus(downloadKey: String, completion: @escaping (Result<Double, Error>) -> Void) {
        Task {
            do {
                let progress = try await downloader.progress(forKey: downloadKey)
                completion(.success(progress))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func getDownloads(completion: @escaping (Result<[Download], Error>) -> Void) {
        completion(Result(catching: {
            downloader.getAll()
        }))
    }

    func getDownload(downloadKey: String, completion: @escaping (Result<Download?, Error>) -> Void) {
        completion(Result(catching: {
            downloader.get(forKey: downloadKey)
        }))
    }

    func removeDownload(downloadKey: String, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(Result(catching: {
            try downloader.remove(download: downloadKey)
        }))
    }

    func getFreeDiskSpace(completion: @escaping (Result<Double, Error>) -> Void) {
        completion(Result(catching: {
            try _getFreeDiskSpace()
        }))
    }

    private func _getFreeDiskSpace() throws -> Double {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return Double(capacity)
            }
            throw FlutterError(code: "diskspace", message: "Failed getting disk space", details: nil)
        } catch {
            print("Error retrieving capacity: \(error.localizedDescription)")
            throw FlutterError(code: "diskspace", message: error.localizedDescription, details: nil)
        }
    }
}
