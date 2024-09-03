package media.bcc.bccm_player

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import media.bcc.bccm_player.pigeon.PlaybackPlatformApi.MediaItem
import java.util.UUID

class QueueManager {
    private val _queue = QueueList();
    private val _history = QueueList();
    private val _nextUp = ShuffleQueueList()
    val nextUp get() = _nextUp.items
    val queue get() = _queue.items
    val shuffle get() = _nextUp.shuffleEnabled
    val changeFlow = combine(queue, nextUp, shuffle) { _, _, _ -> }

    fun setShuffleEnabled(enabled: Boolean) {
        _nextUp.setShuffleEnabled(enabled)
    }

    fun setNextUp(mediaItems: List<MediaItem>) {
        for (item in mediaItems) {
            item.id = item.id ?: UUID.randomUUID().toString()
        }
        _nextUp.setItems(mediaItems)
    }

    fun addQueueItem(mediaItem: MediaItem) {
        mediaItem.id = mediaItem.id ?: UUID.randomUUID().toString()
        _queue.add(mediaItem)
    }

    fun removeQueueItem(id: String) {
        _queue.remove(id)
    }

    fun moveQueueItem(fromIndex: Int, toIndex: Int) {
        _queue.move(fromIndex, toIndex)
    }

    fun consumeNext(current: MediaItem?): MediaItem? {
        if (current != null) {
            _history.addToStart(current)
        }
        val q = _queue.consumeNext()
        return q ?: _nextUp.consumeNext()
    }

    fun consumePrevious(current: MediaItem?): MediaItem? {
        val m = _history.consumeNext()
        if (m != null && current != null) {
            _nextUp.addToStart(current)
        }
        return m
    }

    fun consumeSpecific(id: String): MediaItem? {
        val q = _queue.consumeSpecific(id)
        return q ?: _nextUp.consumeSpecific(id)
    }

    fun clearQueue() {
        _queue.clear()
    }
}


open class QueueList {
    protected val mutableItems = MutableStateFlow(listOf<MediaItem>())
    val items get() = mutableItems.asStateFlow()

    fun add(item: MediaItem) {
        mutableItems.update {
            it + item
        }
    }

    fun addToStart(item: MediaItem) {
        mutableItems.update {
            listOf(item) + it
        }
    }

    fun clear() {
        mutableItems.update {
            emptyList()
        }
    }

    fun remove(id: String) {
        mutableItems.update {
            it.filter { item -> item.id != id }
        }
    }

    fun move(fromIndex: Int, toIndex: Int) {
        mutableItems.update {
            val mutableList = it.toMutableList()
            mutableList.add(toIndex, mutableList.removeAt(fromIndex))
            mutableList
        }
    }

    fun consumeNext(): MediaItem? {
        return mutableItems.value.firstOrNull()?.also {
            mutableItems.update {
                it.drop(1)
            }
        }
    }

    fun consumeSpecific(id: String): MediaItem? {
        return mutableItems.value.firstOrNull { it.id == id }?.also {
            mutableItems.update {
                it.filter { item -> item.id != id }
            }
        }
    }
}

class ShuffleQueueList : QueueList() {
    private val _orderedItems = MutableStateFlow(listOf<MediaItem>())
    private val _shuffleEnabled = MutableStateFlow(false)
    val shuffleEnabled get() = _shuffleEnabled.asStateFlow()

    private fun maybeShuffle() {
        mutableItems.update {
            if (_shuffleEnabled.value) {
                _orderedItems.value.shuffled()
            } else {
                _orderedItems.value
            }
        }
    }

    fun setShuffleEnabled(shuffle: Boolean) {
        this._shuffleEnabled.value = shuffle
        maybeShuffle()
    }

    fun setItems(items: List<MediaItem>) {
        _orderedItems.value = items
        maybeShuffle()
    }
}