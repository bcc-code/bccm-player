import 'dart:async';

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/pigeon/downloader_pigeon.g.dart';
import 'package:bccm_player_example/example_videos.dart';
import 'package:flutter/material.dart';

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
  late BccmPlayerController controller;
  List<DownloadState> downloads = [];
  StreamSubscription<DownloadStatusChangedEvent>? _subscription;
  bool statusLoopRunning = false;

  void initializeController() async {
    controller = BccmPlayerController.empty();
    await controller.initialize();
    controller.setMixWithOthers(true);
  }

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

  void startStatusLoop() async {
    statusLoopRunning = true;

    while (statusLoopRunning) {
      await Future.delayed(const Duration(milliseconds: 300));

      final Map<String, double> results = {};
      for (var state in downloads) {
        final progress = await DownloaderInterface.instance.getDownloadStatus(state.download.key);
        results[state.download.key] = progress;
        debugPrint("P ${state.download.config.title}: ${state.progress}");
      }

      setState(() {
        downloads.forEach((state) {
          state.progress = results[state.download.key]!;
        });
      });
    }
  }

  @override
  void initState() {
    initializeController();
    startStatusLoop();

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
    controller.dispose();
    statusLoopRunning = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          children: [
            BccmPlayerView(controller),
            ...downloads.map((state) => Row(children: [
                  Column(children: [
                    Text(state.download.config.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  state.download.isFinished
                      ? ElevatedButton(
                          onPressed: () {
                            debugPrint("Play ${state.download.offlineUrl}");
                            controller.replaceCurrentMediaItem(MediaItem(
                                url: state.download.offlineUrl,
                                mimeType: state.download.config.mimeType,
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
            ...exampleVideos.map(
              (mediaItem) => ElevatedButton(
                onPressed: () async {
                  statusLoopRunning = false;
                  final config = DownloadConfig(
                      url: mediaItem.url!,
                      mimeType: mediaItem.mimeType!,
                      title: mediaItem.metadata?.title ?? "Unknown title",
                      tracks: [],
                      additionalData: {"test": "Coen"});
                  final download = await DownloaderInterface.instance.startDownload(config);
                  setState(() {
                    downloads.add(DownloadState(download: download, progress: 0.0));
                    downloads.sort((a, b) => a.download.key.compareTo(b.download.key));
                  });
                  startStatusLoop();
                },
                child: Text('Download ${mediaItem.metadata?.title ?? "Unknown"}'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
