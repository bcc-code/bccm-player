import AVFoundation

enum MediaInfoFetcher {
    static func fetchInfo(for url: URL, mimeType: String?) async throws -> MediaInfo {
        let asset = AVURLAsset(url: url,
                               options: mimeType != nil ? ["AVURLAssetOutOfBandMIMETypeKey": mimeType!] : nil)
        
        try await withCheckedThrowingContinuation { continuation in
            asset.loadValuesAsynchronously(forKeys: ["tracks", "variants"]) {
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
        
        let audioTracks: [Track] = TrackUtils.getAudioTracksForAsset(asset, playerItem: nil)
        let textTracks: [Track] = TrackUtils.getTextTracksForAsset(asset, playerItem: nil)
        let videoTracks: [Track] = TrackUtils.getVideoTracksForAsset(asset, playerItem: nil)
        
        return MediaInfo.make(withAudioTracks: audioTracks, textTracks: textTracks, videoTracks: videoTracks)
    }
}
