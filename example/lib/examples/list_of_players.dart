import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player_example/example_videos.dart';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';

class ListOfPlayers extends StatefulWidget {
  const ListOfPlayers({super.key});

  @override
  State<ListOfPlayers> createState() => _ListOfPlayersState();
}

class _ListOfPlayersState extends State<ListOfPlayers> {
  late List<BccmPlayerController> controllers;

  @override
  void initState() {
    ScreenProtector.preventScreenshotOn();
    ScreenProtector.protectDataLeakageWithBlur();
    controllers = [
      BccmPlayerController.empty(),
      ...exampleVideos.map(
        (e) => BccmPlayerController(e),
      ),
      BccmPlayerController.primary,
    ];
    for (final controller in controllers) {
      controller.initialize().then((_) => controller.setMixWithOthers(true));
    }
    super.initState();
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    ScreenProtector.protectDataLeakageWithBlurOff();
    for (var element in controllers) {
      if (!element.isPrimary) element.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ...controllers.map(
            (controller) => Column(
              children: [
                BccmPlayerView(controller),
                ElevatedButton(
                    onPressed: () {
                      controller.setPrimary();
                    },
                    child: const Text('Make primary')),
              ],
            ),
          )
        ],
      ),
    );
  }
}
