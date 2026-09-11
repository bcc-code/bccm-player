
class DownloaderApiImpl: NSObject, DownloaderPigeon {
    public let downloader: Downloader

    init(downloader: Downloader) {
        self.downloader = downloader
    }

    func startDownload(downloadConfig: DownloadConfig) async throws -> Download {
        return try await downloader.startDownload(config: downloadConfig)
    }

    func getDownloadStatus(downloadKey: String) async throws -> Double {
        return try await downloader.progress(forKey: downloadKey)
    }

    func getDownloads() async throws -> [Download] {
        return downloader.getAll()
    }

    func getDownload(downloadKey: String) async throws -> Download? {
        return downloader.get(forKey: downloadKey)
    }

    func removeDownload(downloadKey: String) async throws {
        try downloader.remove(download: downloadKey)
    }

    func getFreeDiskSpace() async throws -> Double {
        return try _getFreeDiskSpace()
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
