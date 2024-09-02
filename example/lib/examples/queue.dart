import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player_example/example_videos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class QueueExample extends HookWidget {
  const QueueExample({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BccmPlayerController.primary;

    final queue = useListenableSelector(controller, () => controller.value.queue);

    var tempQueueItems = useState([...queue?.items ?? []]);
    useEffect(() {
      tempQueueItems.value = [...queue?.items ?? []];
      return null;
    }, [queue?.items]);

    debugPrint('queue: ${tempQueueItems.value.map((i) => i?.id?.toString())}');

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 24, bottom: 16),
                child: Text(
                  'Queue',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
              BccmPlayerView(controller),
              ValueListenableBuilder<PlayerState>(
                valueListenable: controller,
                builder: (context, value, _) => controller.value.currentMediaItem?.metadata?.artworkUri == null
                    ? const SizedBox.shrink()
                    : MiniPlayer(
                        title: controller.value.currentMediaItem!.metadata!.title!,
                        secondaryTitle: null,
                        artworkUri: controller.value.currentMediaItem!.metadata!.artworkUri,
                        isPlaying: controller.value.playbackState == PlaybackState.playing,
                        onPlayTap: () => controller.play(),
                        onPauseTap: () => controller.pause(),
                        onCloseTap: () => controller.stop(reset: true),
                      ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    label: const Text('Clear queue'),
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clearQueue();
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    label: const Text('Next'),
                    icon: const Icon(Icons.skip_next),
                    onPressed: () {
                      controller.next();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ...exampleVideos.map(
                (MediaItem mediaItem) => ElevatedButton(
                  onPressed: () {
                    BccmPlayerInterface.instance.queueMediaItem(
                      controller.value.playerId,
                      mediaItem,
                    );
                  },
                  child: Text('${mediaItem.metadata?.title}'),
                ),
              ),
              const SizedBox(height: 32),
              ReorderableListView.builder(
                  onReorder: (oldIndex, newIndex) {
                    tempQueueItems.value.insert(newIndex, tempQueueItems.value.removeAt(oldIndex));
                    controller.moveQueueItem(oldIndex, newIndex);
                  },
                  shrinkWrap: true,
                  itemCount: tempQueueItems.value.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      key: ValueKey(tempQueueItems.value[index]?.id),
                      onTap: () {
                        controller.replaceCurrentMediaItem(tempQueueItems.value[index]!);
                      },
                      trailing: GestureDetector(
                        onTap: () {
                          final id = tempQueueItems.value[index]?.id;
                          if (id != null) {
                            controller.removeQueueItem(id);
                          }
                        },
                        child: const Icon(Icons.close),
                      ),
                      selected: tempQueueItems.value[index]?.id == controller.value.currentMediaItem?.id,
                      title: Text(
                        '${tempQueueItems.value[index]?.metadata?.title}',
                      ),
                      subtitle: Text(
                        '${tempQueueItems.value[index]?.id}',
                      ),
                    );
                  })
            ],
          ),
        ),
      ),
    );
  }
}
