import AVKit
import Foundation

public class MediaQueueController {
    public var items: [MediaItem] = []
    public var currentIndex: Int = 0
    let playerController: AVQueuePlayerController

    init(playerController: AVQueuePlayerController) {
        self.playerController = playerController
    }

    public func toMediaQueue() -> MediaQueue {
        debugPrint(items.map { $0.id })
        return MediaQueue.make(with: items, currentIndex: currentIndex as NSNumber)
    }

    public func add(_ mediaItem: MediaItem) {
        if mediaItem.id == nil {
            mediaItem.id = UUID().uuidString
        }
        items.append(mediaItem)
        if items.count == 1 {
            currentIndex = 0
            updatePlayerCurrentItem()
        }
        playerController.onQueueChanged()
    }

    public func moveQueueItem(from fromIndex: Int, to toIndex: Int) {
        guard fromIndex >= 0, fromIndex < items.count,
              toIndex >= 0, toIndex < items.count
        else {
            return
        }

        let item = items.remove(at: fromIndex)
        items.insert(item, at: toIndex)
        
        if currentIndex == fromIndex {
            currentIndex = toIndex
        } else if currentIndex > fromIndex, currentIndex <= toIndex {
            currentIndex -= 1
        } else if currentIndex < fromIndex, currentIndex >= toIndex {
            currentIndex += 1
        }
        playerController.onQueueChanged()
    }

    public func removeQueueItem(id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        items.remove(at: index)

        if index < currentIndex {
            currentIndex -= 1
        } else if index == currentIndex {
            currentIndex = min(currentIndex, items.count - 1)
            updatePlayerCurrentItem()
        }
        playerController.onQueueChanged()
    }

    public func clearQueue() {
        items.removeAll()
        playerController.player.replaceCurrentItem(with: nil)
        currentIndex = 0
        playerController.onQueueChanged()
    }

    public func replaceQueueItems(items newItems: [MediaItem], from fromIndex: Int, to toIndex: Int) {
        guard fromIndex >= 0, fromIndex <= toIndex, toIndex <= items.count else {
            return
        }

        for item in newItems {
            if item.id == nil {
                item.id = UUID().uuidString
            }
        }

        items.replaceSubrange(fromIndex ..< toIndex, with: newItems)

        if currentIndex >= fromIndex, currentIndex < toIndex {
            currentIndex = fromIndex
            updatePlayerCurrentItem()
        } else if currentIndex >= toIndex {
            currentIndex = min(currentIndex + (newItems.count - (toIndex - fromIndex)), items.count - 1)
        }
        playerController.onQueueChanged()
    }

    public func playNext() {
        if currentIndex == items.count - 1 {
            playerController.pause()
        } else {
            currentIndex = currentIndex + 1
        }
        updatePlayerCurrentItem()
        playerController.onQueueChanged()
    }

    public func setCurrentQueueItem(id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        currentIndex = index
        updatePlayerCurrentItem()
        playerController.onQueueChanged()
    }

    private func updatePlayerCurrentItem() {
        guard currentIndex >= 0, currentIndex < items.count else {
            playerController.player.replaceCurrentItem(with: nil)
            return
        }

        playerController.replaceCurrentMediaItem(items[currentIndex], autoplay: nil, completion: nil)
    }
}
