import AVKit
import Foundation

public class PeakBitrateController {
    private var requestedPeakBitrate: Double = 0
    private var audioOnlyMode: Bool = false
    var playerCurrentItemObserver: NSKeyValueObservation?

    let player: AVPlayer
    init(player: AVPlayer) {
        self.player = player
        playerCurrentItemObserver = player.observe(\.currentItem, options: [.new, .old], changeHandler: { _, change in
            if change.newValue != nil {
                self.updateInternalValue()
            }
        })
    }

    func value() -> Double {
        return requestedPeakBitrate
    }

    func setAudioOnlyMode(_ v: Bool) {
        audioOnlyMode = v
        updateInternalValue()
    }

    func setPeakBitrate(_ v: Double) {
        requestedPeakBitrate = v
        updateInternalValue()
    }

    private func updateInternalValue() {
        if audioOnlyMode {
            debugPrint("bccm: Setting preferredPeakBitRate to 1 (Audio only)")
            player.currentItem?.preferredPeakBitRate = 1
        } else {
            debugPrint("bccm: Setting preferredPeakBitRate to \(requestedPeakBitrate).")
            player.currentItem?.preferredPeakBitRate = requestedPeakBitrate
        }
    }
}
