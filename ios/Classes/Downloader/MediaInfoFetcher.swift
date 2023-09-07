import AVFoundation

enum MediaInfoFetcher {
    static func fetchInfo(for url: URL) async throws -> MediaInfo {
        let asset = AVURLAsset(url: url)
        
        try await withCheckedThrowingContinuation { continuation in
            asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                var error: NSError? = nil
                switch asset.statusOfValue(forKey: "tracks", error: &error) {
                case .loaded:
                    continuation.resume()
                case .failed:
                    
                    continuation.resume(throwing: error ?? NSError())
                case .cancelled:
                    continuation.resume(throwing: error ?? NSError())
                default:
                    continuation.resume()
                }
            }
        }
        
        var audioTracks: [Track] = TrackUtils.getAudioTracksForAsset(asset, playerItem: nil)
        var textTracks: [Track] = TrackUtils.getTextTracksForAsset(asset, playerItem: nil)
        var videoTracks: [Track] = TrackUtils.getVideoTracksForAsset(asset, playerItem: nil)
        
        return MediaInfo.make(withAudioTracks: audioTracks, textTracks: textTracks, videoTracks: videoTracks)
    }
}
