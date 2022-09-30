import Foundation
import AVKit
import GoogleCast

public class PlaybackApiImpl: NSObject, PlaybackPlatformPigeon {
    var players = [PlayerController]()
    private var primaryPlayerId: String? = nil
    let playbackListener: PlaybackListenerPigeon
    let chromecastPigeon: ChromecastPigeon
    var user: User? = nil
    var npawConfig: NpawConfig? = nil

    init(chromecastPigeon: ChromecastPigeon, castPlayerController: CastPlayerController, playbackListener: PlaybackListenerPigeon) {
        self.playbackListener = playbackListener
        self.chromecastPigeon = chromecastPigeon
        super.init()
        players.append(castPlayerController);
    }

    public func setUser(_ user: User?, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        self.user = user;
    }

    public func setNpawConfig(_ config: NpawConfig?, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        npawConfig = config;
    }

    public func getPlayer(_ id: String) -> PlayerController? {
        players.first(where: { $0.id == id })
    }
    public func getPrimaryPlayer() -> PlayerController? {
        players.first(where: { $0.id == primaryPlayerId })
    }

    public func setPrimary(_
                           id: String, completion: @escaping (FlutterError?) -> Void) {
        primaryPlayerId = id;
    }

    public func newPlayer(_ url: String?, completion: @escaping (String?, FlutterError?) -> Void) {
        let player = AVQueuePlayerController(playbackListener: playbackListener, npawConfig: npawConfig);
        players.append(player)
        if (url != nil) {
            player.replaceCurrentMediaItem(MediaItem.make(withUrl: url!, mimeType: "application/x-mpegURL", metadata: nil, isLive: false, playbackStartPositionMs: nil))
        }
        completion(player.id, nil)
    }

    public func getChromecastState(_ completion: @escaping (ChromecastState?, FlutterError?) -> Void) {
        let connectionStateRaw = GCKCastContext.sharedInstance().castState.rawValue+1
        let connectionState = CastConnectionState.init(rawValue: UInt(connectionStateRaw))
        if (connectionState != nil) {
            completion(ChromecastState.make(with: connectionState!), nil);
        } else {
            completion(ChromecastState.make(with: CastConnectionState.noDevicesAvailable), nil);
        }
    }
    
    public func openExpandedCastController(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        GCKCastContext.sharedInstance().presentDefaultExpandedMediaControls();
    }
    
    public func openCastDialog(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        GCKCastContext.sharedInstance().presentCastDialog();
    }

    public func queueMediaItem(_ playerId: String, mediaItem: MediaItem, completion: (FlutterError?) -> ()) {
        let player = getPlayer(playerId);
        player?.queueItem(mediaItem)
        completion(nil)
    }

    public func replaceCurrentMediaItem(_ playerId: String, mediaItem: MediaItem, playbackPositionFromPrimary: NSNumber?, completion: (FlutterError?) -> ()) {
        let player = getPlayer(playerId);

        player?.replaceCurrentMediaItem(mediaItem)
        completion(nil)
    }


    public func play(_ playerId: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        let player = getPlayer(playerId);
        player?.play();
    }

    public func pause(_ playerId: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        let player = getPlayer(playerId);
        player?.pause();
    }

    public func stop(_ playerId: String, reset: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        let player = getPlayer(playerId);
        player?.stop(reset: reset.boolValue)
    }
}
