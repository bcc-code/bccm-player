import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';

class NativeControls extends StatefulWidget {
  const NativeControls({super.key});

  @override
  State<NativeControls> createState() => _NativeControlsState();
}

class _NativeControlsState extends State<NativeControls> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          children: [
            VideoPlatformView(
              playerController: BccmPlayerController.primary,
              showControls: true,
            ),
          ],
        ),
      ],
    );
  }
}
