import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player_example/example_videos.dart';
import 'package:flutter/material.dart';

class ListOfPlayers extends StatefulWidget {
  const ListOfPlayers({super.key});

  @override
  State<ListOfPlayers> createState() => _ListOfPlayersState();
}

class _ListOfPlayersState extends State<ListOfPlayers> {
  late List<BccmPlayerController> controllers;

  @override
  void initState() {
    controllers = [
      BccmPlayerController.empty(),
      ...exampleVideos.map(
        (e) => BccmPlayerController(e),
      )
    ];
    for (var element in controllers) {
      element.initialize();
    }
    super.initState();
  }

  @override
  void dispose() {
    for (var element in controllers) {
      element.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ...controllers.map(
          (controller) => Column(
            children: [
              VideoPlayerView(controller: controller),
              ElevatedButton(
                  onPressed: () {
                    controller.setPrimary();
                  },
                  child: const Text('Make primary')),
            ],
          ),
        )
      ],
    );
  }
}
