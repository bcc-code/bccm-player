import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player_example/example_videos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

enum PlaylistId { playlist1, playlist2 }

final playlist1 = exampleVideos;
final playlist2 = [
  MediaItem(
    url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    mimeType: 'video/mp4',
    metadata: MediaMetadata(
      title: 'Video 1',
      artist: 'Blender Foundation',
      artworkUri: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
    ),
  ),
  MediaItem(
    url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8',
    mimeType: 'application/x-mpegURL',
    metadata: MediaMetadata(
      title: 'Video 2',
    ),
  ),
  MediaItem(
    url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8',
    mimeType: 'application/x-mpegURL',
    metadata: MediaMetadata(
      title: 'Video 3',
      artist: 'Apple Inc.',
    ),
  ),
];

class QueueExample extends HookWidget {
  const QueueExample({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BccmPlayerController.primary;

    final queue = useListenable(controller.queue.queue);
    final nextUp = useListenable(controller.queue.nextUp);
    final history = useListenable(controller.queue.history);

    var tempQueueItems = useState([...queue.value]);
    useEffect(() {
      tempQueueItems.value = [...queue.value];
      return null;
    }, [queue.value]);

    debugPrint('queue: ${tempQueueItems.value.map((i) => i.id?.toString())}');

    final currentPlaylistId = useState<PlaylistId>(PlaylistId.playlist1);

    useEffect(() {
      if (currentPlaylistId.value == PlaylistId.playlist1) {
        controller.queue.setNextUp(playlist1);
      } else if (currentPlaylistId.value == PlaylistId.playlist2) {
        controller.queue.setNextUp(playlist2);
      }
      return null;
    }, [currentPlaylistId]);

    final shuffleEnabled = useListenable(controller.queue.shuffleEnabled);

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
              Wrap(
                children: [
                  ElevatedButton.icon(
                    label: const Text('Clear queue'),
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.queue.clearQueue();
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    label: const Text('Previous'),
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () {
                      controller.queue.skipToPrevious();
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    label: const Text('Next'),
                    icon: const Icon(Icons.skip_next),
                    onPressed: () {
                      controller.queue.skipToNext();
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    label: const Text('Shuffle'),
                    icon: Icon(shuffleEnabled.value == true ? Icons.shuffle_on_outlined : Icons.shuffle),
                    onPressed: () {
                      shuffleEnabled.value = !shuffleEnabled.value;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ...exampleVideos.map(
                (MediaItem mediaItem) => ElevatedButton(
                  onPressed: () {
                    controller.queue.addQueueItem(mediaItem);
                  },
                  child: Text('${mediaItem.metadata?.title}'),
                ),
              ),
              const SizedBox(height: 32),
              Text('History', style: Theme.of(context).textTheme.titleLarge),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.value.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {},
                      title: Text(
                        '${history.value[index].metadata?.title}',
                      ),
                      subtitle: Text(
                        '${history.value[index].id}',
                      ),
                    );
                  }),
              Text('Queue items', style: Theme.of(context).textTheme.titleLarge),
              ReorderableListView.builder(
                onReorder: (oldIndex, newIndex) {
                  tempQueueItems.value.insert(newIndex, tempQueueItems.value.removeAt(oldIndex));
                  controller.queue.moveQueueItem(oldIndex, newIndex);
                },
                shrinkWrap: true,
                itemCount: tempQueueItems.value.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    key: ValueKey(tempQueueItems.value[index].id),
                    onTap: () {
                      controller.replaceCurrentMediaItem(tempQueueItems.value[index]!);
                    },
                    trailing: GestureDetector(
                      onTap: () {
                        final id = tempQueueItems.value[index].id;
                        if (id != null) {
                          controller.queue.removeQueueItem(id);
                        }
                      },
                      child: const Icon(Icons.close),
                    ),
                    selected: tempQueueItems.value[index].id == controller.value.currentMediaItem?.id,
                    title: Text(
                      '${tempQueueItems.value[index].metadata?.title}',
                    ),
                    subtitle: Text(
                      '${tempQueueItems.value[index].id}',
                    ),
                  );
                },
              ),
              Text('Up next', style: Theme.of(context).textTheme.titleLarge),
              ListView.builder(
                shrinkWrap: true,
                itemCount: nextUp.value.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {},
                    title: Text(
                      '${nextUp.value[index].metadata?.title}',
                    ),
                    subtitle: Text(
                      '${nextUp.value[index].id}',
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MediaQueueManager {
  final List<MediaItem> queue = [];
  final List<MediaItem> upNext = [];

  MediaQueueManager() {}
}
