import Combine
import Foundation

class QueueManager {
    private var queue = QueueList()
    private var history = QueueList()
    private var nextUp = ShuffleQueueList()

    var changeFlow: AnyPublisher<Void, Never> {
        Publishers.CombineLatest3(queue.$items, nextUp.$items, nextUp.$shuffleEnabled)
            .delay(for: .milliseconds(10), scheduler: DispatchQueue.main)
            .map { _, _, _ in () }
            .eraseToAnyPublisher()
    }

    var currentQueue: [MediaItem] { queue.items }
    var currentNextUp: [MediaItem] { nextUp.items }
    var isShuffleEnabled: Bool { nextUp.shuffleEnabled }

    func setShuffleEnabled(enabled: Bool) {
        nextUp.setShuffleEnabled(enabled)
    }

    func setNextUp(mediaItems: [MediaItem]) {
        mediaItems.forEach { $0.id = $0.id ?? UUID().uuidString }
        nextUp.setItems(mediaItems: mediaItems)
    }

    func addQueueItem(mediaItem: MediaItem) {
        mediaItem.id = mediaItem.id ?? UUID().uuidString
        queue.add(mediaItem)
    }

    func removeQueueItem(id: String) {
        queue.remove(id)
    }

    func moveQueueItem(fromIndex: Int, toIndex: Int) {
        queue.move(fromIndex: fromIndex, toIndex: toIndex)
    }

    func consumeNext(current: MediaItem?) -> MediaItem? {
        if let current = current {
            history.addToStart(current)
        }
        return queue.consumeNext() ?? nextUp.consumeNext()
    }

    func consumePrevious(current: MediaItem?) -> MediaItem? {
        if let previous = history.consumeNext(), let current = current {
            nextUp.addToStart(current)
            return previous
        }
        return nil
    }

    func consumeSpecific(id: String) -> MediaItem? {
        return queue.consumeSpecific(id: id) ?? nextUp.consumeSpecific(id: id)
    }

    func clearQueue() {
        queue.clear()
    }

    func toMediaQueue() -> MediaQueue {
        return MediaQueue.make(withQueue: currentQueue, nextUp: currentNextUp, shuffleEnabled: isShuffleEnabled)
    }
}

class QueueList {
    @Published var items = [MediaItem]()

    func add(_ item: MediaItem) {
        items.append(item)
    }

    func addToStart(_ item: MediaItem) {
        items.insert(item, at: 0)
    }

    func clear() {
        items.removeAll()
    }

    func remove(_ id: String) {
        items.removeAll { $0.id == id }
    }

    func move(fromIndex: Int, toIndex: Int) {
        guard fromIndex != toIndex,
              fromIndex >= 0, fromIndex < items.count,
              toIndex >= 0, toIndex < items.count else { return }

        let item = items.remove(at: fromIndex)
        items.insert(item, at: toIndex)
    }

    func consumeNext() -> MediaItem? {
        guard !items.isEmpty else { return nil }
        return items.removeFirst()
    }

    func consumeSpecific(id: String) -> MediaItem? {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return nil }
        return items.remove(at: index)
    }
}

class ShuffleQueueList: QueueList {
    @Published private var orderedItems = [MediaItem]()
    @Published private(set) var shuffleEnabled = false

    private func maybeShuffle() {
        if shuffleEnabled {
            items = orderedItems.shuffled()
        } else {
            items = orderedItems
        }
    }

    func setShuffleEnabled(_ shuffle: Bool) {
        shuffleEnabled = shuffle
        maybeShuffle()
    }

    func setItems(mediaItems: [MediaItem]) {
        orderedItems = mediaItems
        maybeShuffle()
    }
}
