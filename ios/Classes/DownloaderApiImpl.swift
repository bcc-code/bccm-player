
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
}
