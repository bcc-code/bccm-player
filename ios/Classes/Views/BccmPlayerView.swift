import AVKit
import Flutter
import MediaPlayer
import UIKit

class BccmPlayerFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var playbackApi: PlaybackApiImpl

    init(messenger: FlutterBinaryMessenger, playbackApi: PlaybackApiImpl) {
        self.messenger = messenger
        self.playbackApi = playbackApi
        super.init()
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        debugPrint("BccmPlayerFactory create")
        let argDictionary = args as! [String: Any]?
        let playerId = argDictionary?["player_id"] as? String
        let showControls = argDictionary?["show_controls"] as? Bool ?? true
        let pipOnLeave = argDictionary?["pip_on_leave"] as? Bool ?? true
        let allowsVideoFrameAnalysis = argDictionary?["allows_video_frame_analysis"] as? Bool ?? showControls
        guard playerId != nil else {
            fatalError("argument 'player_id' cannot be null")
        }
        let playerController = playbackApi.getPlayer(playerId!)
        if playerController == nil {
            fatalError("player with id " + playerId! + "does not exist")
        }
        if let pc = playerController as? AVQueuePlayerController {
            return AVPlayerBccmPlayerView(
                frame: frame,
                playerController: pc,
                showControls: showControls,
                pipOnLeave: pipOnLeave,
                allowsVideoFrameAnalysis: allowsVideoFrameAnalysis
            )
        } else if let pc = playerController as? CastPlayerController {
            return CastPlayerView(frame: frame, playerController: pc)
        } else {
            fatalError("Playercontroller is of unknown type.")
        }
    }
}

class AVPlayerBccmPlayerView: NSObject, FlutterPlatformView {
    private var _view: UIView = .init()
    private var _playerController: AVQueuePlayerController
    private var playerViewController: AVPlayerViewController? = nil
    private var _showControls: Bool
    private var _pipOnLeave: Bool
    private var _allowsVideoFrameAnalysis: Bool

    init(
        frame: CGRect,
        playerController: AVQueuePlayerController,
        showControls: Bool,
        pipOnLeave: Bool,
        allowsVideoFrameAnalysis: Bool
    ) {
        debugPrint("AVPlayerBccmPlayerView init")
        _view.frame = frame
        _playerController = playerController
        _showControls = showControls
        _pipOnLeave = pipOnLeave
        _allowsVideoFrameAnalysis = allowsVideoFrameAnalysis
        super.init()

        createNativeView()
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIScene.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(willBecomeActive), name: UIScene.willEnterForegroundNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(willBecomeActive), name: UIApplication.willEnterForegroundNotification, object: nil)
        }
    }

    @objc func willResignActive(_ notification: Notification) {
        // code to execute
        print("willResignActive")
        reset()
        if _playerController.player.volume == 0 || _playerController.player.isMuted {
            _playerController.stop(reset: true)
        }
    }

    @objc func willBecomeActive(_ notification: Notification) {
        // code to execute
        print("willBecomeActive")
        createNativeView()
        perform(#selector(pipFix), with: nil, afterDelay: 1)
    }

    func view() -> UIView {
        return _view
    }

    deinit {
        print("deinit playerview")
        playerViewController?.removeFromParent()
        if let playerViewController = playerViewController {
            _playerController.releasePlayerView(playerViewController)
        }
        playerViewController = nil
        print("deinit playerview done")
    }

    func createNativeView() {
        if _playerController.pipController != nil && _playerController.fullscreenViewController == nil {
            print("starting with existing pipController")
            playerViewController = _playerController.pipController
            if let viewController = (UIApplication.shared.delegate?.window??.rootViewController)  {
                viewController.addChild(playerViewController!)
            }
        } else {
            print("starting with new avplayerviewcontroller")
            playerViewController = LandscapeAVPlayerViewController()
            if let viewController = (UIApplication.shared.delegate?.window??.rootViewController) {
                viewController.addChild(playerViewController!)
            }
        }

        if let playerViewController = playerViewController {
            playerViewController.view.frame = _view.frame
            playerViewController.showsPlaybackControls = _showControls
            playerViewController.delegate = _playerController
            playerViewController.exitsFullScreenWhenPlaybackEnds = false
            playerViewController.allowsPictureInPicturePlayback = _pipOnLeave
            playerViewController.updatesNowPlayingInfoCenter = false
            playerViewController.view.backgroundColor = UIColor(white: 0, alpha: 0)
            if #available(iOS 16.0, *) {
                var speeds = AVPlaybackSpeed.systemDefaultSpeeds
                speeds.append(AVPlaybackSpeed(rate: 0.75, localizedName: "0.75x"))
                speeds.sort { $0.rate < $1.rate }
                playerViewController.speeds = speeds
                playerViewController.allowsVideoFrameAnalysis = _allowsVideoFrameAnalysis
            }
            if #available(iOS 14.2, *) {
                playerViewController.canStartPictureInPictureAutomaticallyFromInline = _pipOnLeave
            }
            _view.addSubview(playerViewController.view)
            _playerController.takeOwnership(playerViewController)
        }
    }

    @objc func pipFix() {
        let rate = _playerController.player.rate
        _playerController.player.pause()
        reset()
        createNativeView()
        _playerController.player.playImmediately(atRate: rate)
    }

    @objc func reset() {
        if let playerViewController = playerViewController {
            _playerController.releasePlayerView(playerViewController)
        }
        _view.subviews.forEach {
            $0.removeFromSuperview()
        }
        playerViewController?.removeFromParent()
        playerViewController = nil
    }
}
