import 'package:flutter/widgets.dart';

import '../../../bccm_player.dart';

class SimpleBccmPlayerView extends StatefulWidget {
  final BccmPlayerController controller;

  const SimpleBccmPlayerView(this.controller, {super.key});

  @override
  State<SimpleBccmPlayerView> createState() => _SimpleBccmPlayerViewState();
}

class _SimpleBccmPlayerViewState extends State<SimpleBccmPlayerView> {
  late BccmPlayerViewController controller;

  @override
  void initState() {
    super.initState();
    controller = BccmPlayerViewController(playerController: widget.controller);
  }

  @override
  void didUpdateWidget(SimpleBccmPlayerView oldWidget) {
    debugPrint("didUpdateWidget controller check: ${oldWidget.controller.hashCode == controller.playerController.hashCode}");
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (controller.playerController.isPrimary) {
      debugPrint('disposing');
    }
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BccmPlayerView(controller);
  }
}
