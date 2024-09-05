import Combine
import Foundation

class QueueManager {
    private var queue = QueueList()
    private var history = QueueList()
    private var nextUp = ShuffleQueueList()
    
    // Combine's version of `combine` to track changes to the queue, nextUp, and shuffle state
    var changeFlow: AnyPublisher<Void, Never> {
        Publishers.CombineLatest3(queue.$items, nextUp.$items, nextUp.$shuffleEnabled)
            .map { _, _, _ in () }  // Ignore values, just emit Void when any changes
            .eraseToAnyPublisher()
    }

    // Accessors for queue, next-up, and shuffle state
    var currentQueue: [MediaItem] { queue.items }
    var currentNextUp: [MediaItem] { nextUp.items }
    var isShuffleEnabled: Bool { nextUp.shuffleEnabled }

    // Set shuffle state
    func setShuffleEnabled(enabled: Bool) {
        nextUp.setShuffleEnabled(enabled)
    }

    // Set the next-up list
    func setNextUp(mediaItems: [MediaItem]) {
        nextUp.setItems(mediaItems: mediaItems)
    }

    // Add a media item to the queue
    func addQueueItem(mediaItem: MediaItem) {
        queue.add(mediaItem)
    }

    // Remove a media item from the queue by ID
    func removeQueueItem(id: String) {
        queue.remove(id)
    }

    // Move a media item in the queue from one index to another
    func moveQueueItem(fromIndex: Int, toIndex: Int) {
        queue.move(fromIndex: fromIndex, toIndex: toIndex)
    }

    // Consume the next media item from the queue or next-up
    func consumeNext(current: MediaItem?) -> MediaItem? {
        if let current = current {
            history.addToStart(current)
        }
        return queue.consumeNext() ?? nextUp.consumeNext()
    }

    // Consume the previous media item from the history
    func consumePrevious(current: MediaItem?) -> MediaItem? {
        if let previous = history.consumeNext(), let current = current {
            nextUp.addToStart(current)
            return previous
        }
        return nil
    }

    // Consume a specific media item by ID from either the queue or next-up
    func consumeSpecific(id: String) -> MediaItem? {
        return queue.consumeSpecific(id: id) ?? nextUp.consumeSpecific(id: id)
    }

    // Clear the queue
    func clearQueue() {
        queue.clear()
    }
}


class QueueList {
    @Published var items = [MediaItem]()

    // Add an item to the end of the queue
    func add(_ item: MediaItem) {
        items.append(item)
    }

    // Add an item to the start of the queue (history)
    func addToStart(_ item: MediaItem) {
        items.insert(item, at: 0)
    }

    // Clear the queue
    func clear() {
        items.removeAll()
    }

    // Remove an item by ID
    func remove(_ id: String) {
        items.removeAll { $0.id == id }
    }

    // Move an item in the queue from one index to another
    func move(fromIndex: Int, toIndex: Int) {
        guard fromIndex != toIndex,
              fromIndex >= 0, fromIndex < items.count,
              toIndex >= 0, toIndex < items.count else { return }

        let item = items.remove(at: fromIndex)
        items.insert(item, at: toIndex)
    }

    // Consume (remove and return) the next item in the queue
    func consumeNext() -> MediaItem? {
        guard !items.isEmpty else { return nil }
        return items.removeFirst()
    }

    // Consume (remove and return) a specific item by ID
    func consumeSpecific(id: String) -> MediaItem? {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return nil }
        return items.remove(at: index)
    }
}

class ShuffleQueueList: QueueList {
    @Published private var orderedItems = [MediaItem]()
    @Published private(set) var shuffleEnabled = false

    // Maybe shuffle the items based on the shuffleEnabled flag
    private func maybeShuffle() {
        if shuffleEnabled {
            items = orderedItems.shuffled()
        } else {
            items = orderedItems
        }
    }

    // Set shuffleEnabled and update the shuffled state accordingly
    func setShuffleEnabled(_ shuffle: Bool) {
        shuffleEnabled = shuffle
        maybeShuffle()
    }

    // Set the items in the next-up queue and apply shuffling if enabled
    func setItems(mediaItems: [MediaItem]) {
        orderedItems = mediaItems
        maybeShuffle()
    }
}
