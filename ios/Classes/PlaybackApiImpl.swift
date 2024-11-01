import AVKit
import Foundation
import GoogleCast

// Implementation of the PlaybackPlatformPigeon
// See pigeons/playback_platform_pigeon.dart
// TODO: this file should be a pure api towards flutter,
// we should move the "players" array and state into a dedicated class
public class PlaybackApiImpl: NSObject, PlaybackPlatformPigeon {

    public func getAndroidPerformanceClass(completion: @escaping (NSNumber?, FlutterError?) -> Void) {
        completion(nil, nil)
    }

    public func switchToVideoTexture(forPlayer playerId: String, textureId: Int, completion: @escaping (NSNumber?, FlutterError?) -> Void) {
        completion(nil, FlutterError(code: "PlaybackApiImpl", message: "Textures are not implemented on iOS. Wrap with Platform.isAndroid().", details: nil))
    }

    public func createVideoTexture(_ completion: @escaping (NSNumber?, FlutterError?) -> Void) {
        completion(nil, FlutterError(code: "PlaybackApiImpl", message: "Textures are not implemented on iOS. Wrap with Platform.isAndroid().", details: nil))
    }

    public func disposeVideoTexture(_ textureId: Int, completion: @escaping (NSNumber?, FlutterError?) -> Void) {
        completion(nil, FlutterError(code: "PlaybackApiImpl", message: "Textures are not implemented on iOS. Wrap with Platform.isAndroid().", details: nil))
    }

    var players = [PlayerController]()
    private var primaryPlayerId: String? = nil
    private var previousPrimaryPlayerId: String? = nil
    let playbackListener: PlaybackListenerPigeon
    let chromecastPigeon: ChromecastPigeon
    let queueManagerPigeon: QueueManagerPigeon
    var npawConfig: NpawConfig? = nil
    var appConfig: AppConfig? = nil

    init(chromecastPigeon: ChromecastPigeon, playbackListener: PlaybackListenerPigeon, queueManagerPigeon: QueueManagerPigeon) {
        self.playbackListener = playbackListener
        self.chromecastPigeon = chromecastPigeon
        self.queueManagerPigeon = queueManagerPigeon
        super.init()
        let castPlayerController = CastPlayerController(playbackApi: self)
        players.append(castPlayerController)
        newPlayer(nil, disableNpaw: false, completion: { playerId, _ in
            if playerId != nil {
                self.setPrimary(playerId!, completion: { _ in })
            }
        })
    }

    public func attach(completion: @escaping (FlutterError?) -> Void) {
        // stop and remove all of type AVQueuePlayerController except primary
        for p in players {
            if p is AVQueuePlayerController && p.id != primaryPlayerId {
                p.stop(reset: true)
            }
            let event = PlayerStateUpdateEvent.make(withPlayerId: p.id, snapshot: p.getPlayerStateSnapshot())
            playbackListener.onPlayerStateUpdate(event, completion: { _ in })
        }
        players.removeAll(where: { $0 is AVQueuePlayerController && $0.id != primaryPlayerId })

        completion(nil)
    }

    public func setAppConfig(_ config: AppConfig?, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        appConfig = config
        for p in players {
            p.updateAppConfig(appConfig: appConfig)
        }
    }

    public func setPlayerViewVisibility(_ viewId: Int, visible: Bool, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {}

    public func setNpawConfig(_ config: NpawConfig?, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        npawConfig = config
        for p in players {
            p.setNpawConfig(npawConfig: npawConfig)
        }
    }

    public func getPlayer(_ id: String) -> PlayerController? {
        players.first(where: { $0.id == id })
    }

    public func getPrimaryPlayer() -> PlayerController? {
        players.first(where: { $0.id == primaryPlayerId })
    }

    public func setPrimary(_ id: String, completion: @escaping (FlutterError?) -> Void) {
        if primaryPlayerId == id { return }
        previousPrimaryPlayerId = primaryPlayerId
        primaryPlayerId = id
        getPrimaryPlayer()?.hasBecomePrimary()
        playbackListener.onPrimaryPlayerChanged(PrimaryPlayerChangedEvent.make(withPlayerId: id), completion: { _ in })
        completion(nil)
    }

    public func newPlayer(_ bufferModeBoxed: BufferModeBox?, disableNpaw: NSNumber?, completion: @escaping (String?, FlutterError?) -> Void) {
        let bufferMode = bufferModeBoxed?.value ?? BufferMode.standard
        let player = AVQueuePlayerController(
            playbackListener: playbackListener,
            bufferMode: bufferMode,
            npawConfig: npawConfig,
            appConfig: appConfig,
            disableNpaw: disableNpaw?.boolValue,
            queueManagerPigeon: queueManagerPigeon
        )
        players.append(player)

        completion(player.id, nil)
    }

    public func disposePlayer(_ playerId: String, completion: @escaping (NSNumber?, FlutterError?) -> Void) {
        guard let player = getPlayer(playerId) else {
            completion(false, nil)
            return
        }
        player.stop(reset: true)
        players.removeAll(where: { $0.id == playerId })
        completion(true, nil)
    }

    public func getChromecastState(_ completion: @escaping (ChromecastState?, FlutterError?) -> Void) {
        let castPlayer = players.first(where: { $0.id == CastPlayerController.DEFAULT_ID })
        let mediaItem = castPlayer?.getCurrentItem()

        let connectionStateRaw = GCKCastContext.sharedInstance().castState.rawValue + 1
        let connectionState = CastConnectionState(rawValue: UInt(connectionStateRaw))
        if connectionState != nil {
            completion(ChromecastState.make(with: connectionState!, mediaItem: mediaItem), nil)
        } else {
            completion(ChromecastState.make(with: CastConnectionState.noDevicesAvailable, mediaItem: mediaItem), nil)
        }
    }

    public func openExpandedCastController(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        GCKCastContext.sharedInstance().presentDefaultExpandedMediaControls()
    }

    public func openCastDialog(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        GCKCastContext.sharedInstance().presentCastDialog()
    }

    public func replaceCurrentMediaItem(_ playerId: String, mediaItem: MediaItem, playbackPositionFromPrimary: NSNumber?, autoplay: NSNumber?, completion: @escaping (FlutterError?) -> Void) {
        let player = getPlayer(playerId)

        updateAudioSession()
        player?.replaceCurrentMediaItem(mediaItem, autoplay: autoplay, completion: completion)
    }

    public func getTracks(_ playerId: String?, completion: @escaping (PlayerTracksSnapshot?, FlutterError?) -> Void) {
        let player = playerId == nil ? getPrimaryPlayer() : getPlayer(playerId!)
        let snapshot = player?.getPlayerTracksSnapshot()
        completion(snapshot, nil)
    }

    public func getPlayerState(_ playerId: String?, completion: @escaping (PlayerStateSnapshot?, FlutterError?) -> Void) {
        let player = playerId == nil ? getPrimaryPlayer() : getPlayer(playerId!)
        let snapshot = player?.getPlayerStateSnapshot()
        completion(snapshot, nil)
    }

    public func setSelectedTrack(_ playerId: String, type: TrackType, trackId: String?, completion: @escaping (FlutterError?) -> Void) {
        let player = getPlayer(playerId)
        player?.setSelectedTrack(type: type, trackId: trackId)
        completion(nil)
    }

    public func setPlaybackSpeed(_ playerId: String, speed: Double, completion: @escaping (FlutterError?) -> Void) {
        let player = getPlayer(playerId)
        player?.setPlaybackSpeed(Float(speed))
        completion(nil)
    }

    public func setVolume(_ playerId: String, volume: Double, completion: @escaping (FlutterError?) -> Void) {
        let player = getPlayer(playerId)
        player?.setVolume(Float(volume))
        completion(nil)
    }

    public func setRepeatMode(_ playerId: String, repeatMode: RepeatMode, completion: @escaping (FlutterError?) -> Void) {
        let player = getPlayer(playerId)
        let repeatMode = repeatMode
        player?.setRepeatMode(repeatMode)
        completion(nil)
    }

    public func play(_ playerId: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        let player = getPlayer(playerId)
        player?.play()
    }

    public func seek(_ playerId: String, positionMs: Double, completion: @escaping (FlutterError?) -> Void) {
        let player = getPlayer(playerId)
        player?.seekTo(Int64(positionMs)) { _ in
            completion(nil)
        }
    }

    public func pause(_ playerId: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        let player = getPlayer(playerId)
        player?.pause()
    }

    public func stop(_ playerId: String, reset: Bool, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        let player = getPlayer(playerId)
        player?.stop(reset: reset)
    }

    public func exitFullscreen(_ playerId: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        let player = getPlayer(playerId)
        player?.exitFullscreen()
    }

    public func enterFullscreen(_ playerId: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        let player = getPlayer(playerId)
        player?.enterFullscreen()
    }

    public func setMixWithOthers(_ playerId: String, mixWithOthers: Bool, completion: @escaping (FlutterError?) -> Void) {
        var player = getPlayer(playerId)
        player?.mixWithOthers = mixWithOthers
        updateAudioSession()
    }

    public func fetchMediaInfo(_ urlString: String, mimeType: String?) async -> (MediaInfo?, FlutterError?) {
        return await returnFlutterResult {
            guard let url = URL(string: urlString) else {
                throw BccmPlayerError.runtimeError("Invalid url")
            }
            let tracks = try await MediaInfoFetcher.fetchInfo(for: url, mimeType: mimeType)
            return tracks
        }
    }

    func updateAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

}

public extension PlaybackApiImpl {
    func unclaimIfPrimary(_ playerId: String) {
        if primaryPlayerId != playerId { return }
        if let previousPrimaryPlayerId, let previous = getPlayer(previousPrimaryPlayerId) {
            setPrimary(previous.id, completion: { _ in })
            return
        }
        if let player = players.first(where: { $0 is AVQueuePlayerController }) {
            setPrimary(player.id, completion: { _ in })
            return
        }
        primaryPlayerId = nil
        playbackListener.onPrimaryPlayerChanged(PrimaryPlayerChangedEvent.make(withPlayerId: nil), completion: { _ in })
        assertionFailure("unclaimIfPrimary was called, but no player was given primary.")
    }
}
