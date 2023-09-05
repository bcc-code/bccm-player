import AVKit
import Flutter
import GoogleCast
import UIKit
import Combine

public class SwiftBccmPlayerPlugin: NSObject, FlutterPlugin {
    static var cancellable: AnyCancellable? = nil
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        setupCast()
        let messenger = registrar.messenger()
        let channel = FlutterMethodChannel(name: "bccm_player", binaryMessenger: messenger)
        let instance = SwiftBccmPlayerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)

        let playbackListener = PlaybackListenerPigeon(binaryMessenger: messenger)

        let chromecastPigeon = ChromecastPigeon(binaryMessenger: messenger)
        let playbackApi = PlaybackApiImpl(chromecastPigeon: chromecastPigeon, playbackListener: playbackListener)
        
        let downloaderListener = DownloaderListenerPigeon(binaryMessenger: messenger)
        let downloader = Downloader()
        cancellable = downloader.statusChanged.sink { event in
            downloaderListener.onDownloadStatusChanged(event) { _ in
                // Do nothing
            }
        }

        registrar.register(
            BccmPlayerFactory(messenger: messenger, playbackApi: playbackApi),
            withId: "bccm-player")
        registrar.register(
            CastPlayerViewFactory(messenger: messenger, playbackApi: playbackApi),
            withId: "bccm-cast-player")
        registrar.register(
            CastButtonFactory(messenger: messenger, playbackApi: playbackApi),
            withId: "bccm_player/cast_button")

        PlaybackPlatformPigeonSetup(registrar.messenger(), playbackApi)
        DownloaderPigeonSetup(registrar.messenger(), DownloaderApiImpl(downloader: downloader))

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result("iOS " + UIDevice.current.systemVersion)
    }
    
    public func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) -> Bool {
        return true
    }
}
