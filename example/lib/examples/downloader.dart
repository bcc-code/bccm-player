import 'dart:async';
import 'dart:core';

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/controls.dart';
import 'package:bccm_player_example/example_videos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Downloader extends StatefulWidget {
  const Downloader({super.key});

  @override
  State<Downloader> createState() => _DownloaderState();
}

class DownloadState {
  DownloadState({required this.download, required this.progress});

  Download download;
  double progress;
}

class _DownloaderState extends State<Downloader> {
  List<DownloadState> downloads = [];
  StreamSubscription<DownloadStatusChangedEvent>? _subscription;
  List<Track> selectedAudioTracks = [];
  List<Track> selectedVideoTracks = [];
  bool isOffline = false;

  void loadDownloads() async {
    final localDownloads = await DownloaderInterface.instance.getDownloads();
    final List<DownloadState> result = [];
    for (var download in localDownloads) {
      result.add(DownloadState(download: download, progress: await DownloaderInterface.instance.getDownloadStatus(download.key)));
    }
    result.sort((a, b) => a.download.key.compareTo(b.download.key));

    setState(() {
      downloads = result;
    });
  }

  @override
  void initState() {
    _subscription = DownloaderInterface.instance.downloadStatusEvents.listen((event) async {
      setState(() {
        final state = downloads.firstWhere((element) => element.download.key == event.download.key);
        state.download = event.download;
        state.progress = event.progress;

        debugPrint("Progress: ${state.progress} - ${state.download.isFinished}");
      });
    });

    loadDownloads();

    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          children: [
            BccmPlayerView(BccmPlayerController.primary),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    isOffline = !isOffline;
                  });
                },
                child: Text('Offline player mode: $isOffline')),
            ...downloads.map((state) => Row(children: [
                  Column(children: [
                    Text(state.download.config.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  state.download.isFinished
                      ? ElevatedButton(
                          onPressed: () {
                            debugPrint(state.download.config.additionalData.toString());
                            debugPrint("Play ${state.download.offlineUrl}");
                            BccmPlayerController.primary.replaceCurrentMediaItem(MediaItem(
                                url: state.download.offlineUrl,
                                mimeType: state.download.config.mimeType,
                                isOffline: true,
                                metadata: MediaMetadata(title: state.download.config.title)));
                          },
                          child: const Text("Play"))
                      : CircularProgressIndicator(value: state.progress),
                  ElevatedButton(
                      onPressed: () async {
                        await DownloaderInterface.instance.removeDownload(state.download.key);
                        loadDownloads();
                      },
                      child: const Text("Remove"))
                ])),
            Text(
                'Selected tracks: ${selectedAudioTracks.map((e) => e.labelWithFallback).join(", ")} - ${selectedVideoTracks.map((e) => e.labelWithFallback).join(", ")}'),
            ...exampleVideos.map(
              (mediaItem) => Column(
                children: [
                  Text(mediaItem.metadata?.title ?? "Unknown"),
                  ElevatedButton(
                    onPressed: () async {
                      final info = await BccmPlayerInterface.instance.fetchMediaInfo(url: mediaItem.url!);
                      if (!context.mounted) return;
                      final selection = await showModalBottomSheet<({List<Track> audioTracks, List<Track> videoTracks})>(
                        useRootNavigator: true,
                        enableDrag: true,
                        context: context,
                        builder: (ctx) => _TrackSelection(info: info),
                      );
                      if (selection == null) return;
                      setState(() {
                        selectedAudioTracks = selection.audioTracks;
                        selectedVideoTracks = selection.videoTracks;
                      });
                    },
                    child: const Text('Select tracks'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final config = DownloadConfig(
                          url: mediaItem.url!,
                          mimeType: mediaItem.mimeType!,
                          title: mediaItem.metadata?.title ?? "Unknown title",
                          audioTrackIds: selectedAudioTracks.map((e) => e.id).toList(),
                          videoTrackIds: selectedVideoTracks.map((e) => e.id).toList(),
                          additionalData: {"test": "Coen"});
                      final download = await DownloaderInterface.instance.startDownload(config);
                      setState(() {
                        downloads.add(DownloadState(download: download, progress: 0.0));
                        downloads.sort((a, b) => a.download.key.compareTo(b.download.key));
                      });
                    },
                    child: const Text('Download'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrackSelection extends HookWidget {
  const _TrackSelection({
    required this.info,
  });

  final MediaInfo info;

  @override
  Widget build(BuildContext context) {
    final selectedAudioTracks = useState<List<Track>>([]);
    final selectedVideoTracks = useState<List<Track>>([]);
    return ListView(
      cacheExtent: 10000,
      shrinkWrap: true,
      children: [
        const Text("Media info"),
        Text("Audio tracks (${info.audioTracks.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
        ElevatedButton(
          onPressed: () async {
            final selected = await showModalOptionList(
              context: context,
              options: [
                ...info.audioTracks.safe.map(
                  (track) => SettingsOption(value: track, label: track.labelWithFallback, isSelected: track.isSelected),
                )
              ],
            );
            if (selected == null) return;
            if (!context.mounted) return;
            selectedAudioTracks.value = [selected.value];
          },
          child: const Text('Select audio'),
        ),
        Text("Text tracks (${info.textTracks.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
        ...info.textTracks.safe.map((e) => Text("${e.id} - ${e.labelWithFallback}")),
        Text("Video tracks (${info.videoTracks.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
        ElevatedButton(
          onPressed: () async {
            final selected = await showModalOptionList(
              context: context,
              options: [
                ...info.videoTracks.safe.map(
                  (track) => SettingsOption(value: track, label: track.labelWithFallback, isSelected: track.isSelected),
                )
              ],
            );
            if (selected == null) return;
            if (!context.mounted) return;
            selectedVideoTracks.value = [selected.value];
          },
          child: const Text('Select video'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop((audioTracks: selectedAudioTracks.value, videoTracks: selectedVideoTracks.value));
          },
          child: const Text('Save'),
        )
      ],
    );
  }
}
