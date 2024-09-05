import AVKit
import Combine
import Flutter
import GoogleCast
import UIKit

public class SwiftBccmPlayerPlugin: NSObject, FlutterPlugin {
    static var cancellables: [AnyCancellable] = []

    public static func register(with registrar: FlutterPluginRegistrar) {
        setupCast()
        let messenger = registrar.messenger()
        let channel = FlutterMethodChannel(name: "bccm_player", binaryMessenger: messenger)
        let instance = SwiftBccmPlayerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)

        let playbackListener = PlaybackListenerPigeon(binaryMessenger: messenger)
        let queueManagerPigeon = QueueManagerPigeon(binaryMessenger: messenger)

        let chromecastPigeon = ChromecastPigeon(binaryMessenger: messenger)
        let playbackApi = PlaybackApiImpl(chromecastPigeon: chromecastPigeon, playbackListener: playbackListener, queueManagerPigeon: queueManagerPigeon)

        let downloaderListener = DownloaderListenerPigeon(binaryMessenger: messenger)
        let downloader = Downloader()
        cancellables.append(contentsOf: [
            downloader.changeEvents.sink { event in
                downloaderListener.onDownloadStatusChanged(event: event) { _ in }
            },
            downloader.removeEvents.sink { event in
                downloaderListener.onDownloadRemoved(event: event) { _ in }
            },
            downloader.failEvents.sink { event in
                downloaderListener.onDownloadFailed(event: event) { _ in }
            }
        ])

        registrar.register(
            BccmPlayerFactory(messenger: messenger, playbackApi: playbackApi),
            withId: "bccm-player")
        registrar.register(
            CastPlayerViewFactory(messenger: messenger, playbackApi: playbackApi),
            withId: "bccm-cast-player")
        registrar.register(
            CastButtonFactory(messenger: messenger, playbackApi: playbackApi),
            withId: "bccm_player/cast_button")

        SetUpPlaybackPlatformPigeon(registrar.messenger(), playbackApi)
        DownloaderPigeonSetup.setUp(binaryMessenger: registrar.messenger(), api: DownloaderApiImpl(downloader: downloader))

        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result("iOS " + UIDevice.current.systemVersion)
    }
}
