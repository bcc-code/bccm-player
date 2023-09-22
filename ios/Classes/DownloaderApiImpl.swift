
public class DownloaderApiImpl: NSObject, DownloaderPigeon {
    public let downloader: Downloader

    init(downloader: Downloader) {
        self.downloader = downloader
    }

    public func startDownload(_ downloadConfiguration: DownloadConfig) async -> (Download?, FlutterError?) {
        await returnFlutterResult {
            try downloader.startDownload(config: downloadConfiguration)
        }
    }

    public func downloadStatus(_ downloadKey: String) async -> (NSNumber?, FlutterError?) {
        await returnFlutterResult {
            try await downloader.progress(forKey: downloadKey)
        }
    }

    public func downloads() async -> ([Download]?, FlutterError?) {
        await returnFlutterResult {
            downloader.getAll()
        }
    }

    public func download(_ downloadKey: String) async -> (Download?, FlutterError?) {
        await returnFlutterResult {
            downloader.get(forKey: downloadKey)
        }
    }

    public func removeDownload(_ downloadKey: String) async -> FlutterError? {
        await returnFlutterResult {
            try downloader.remove(download: downloadKey)
        }
    }

    public func freeDiskSpace() async -> (NSNumber?, FlutterError?) {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return (NSNumber(value: capacity), nil)
            }
            return (nil, FlutterError(code: "diskspace", message: "Failed getting disk space", details: nil))
        } catch {
            print("Error retrieving capacity: \(error.localizedDescription)")
            return (nil, FlutterError(code: "diskspace", message: error.localizedDescription, details: nil))
        }
    }
}
