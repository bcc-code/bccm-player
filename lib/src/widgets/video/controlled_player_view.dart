import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/widgets.dart';

import '../controls/default_controls.dart';

/// Read comments on [BccmPlayerView.withViewController] for more details.
class ControlledBccmPlayerView extends StatefulWidget implements BccmPlayerView {
  final BccmPlayerViewController viewController;
  const ControlledBccmPlayerView(this.viewController, {super.key});

  @override
  State<ControlledBccmPlayerView> createState() => _ControlledBccmPlayerViewState();
}

class _ControlledBccmPlayerViewState extends State<ControlledBccmPlayerView> {
  late bool isChromecast;

  void onPlayerControllerUpdate() {
    if (isChromecast == widget.viewController.playerController.isChromecast) return;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        isChromecast = widget.viewController.playerController.isChromecast;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    widget.viewController.playerController.addListener(onPlayerControllerUpdate);
    isChromecast = widget.viewController.playerController.isChromecast;
  }

  @override
  void dispose() {
    widget.viewController.playerController.removeListener(onPlayerControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedBccmPlayerViewController(
      controller: widget.viewController,
      child: Builder(
        builder: (context) {
          // Note: This is not redudant, InheritedBccmPlayerViewController.of(context) makes sure we rebuild when the viewController calls notifyListeners().
          final viewController = InheritedBccmPlayerViewController.of(context);
          if (isChromecast) {
            return viewController.config.castPlayerBuilder != null
                ? viewController.config.castPlayerBuilder!(context)
                : VideoPlatformView(
                    playerController: viewController.playerController,
                    showControls: false,
                    useSurfaceView: viewController.config.useSurfaceView,
                    allowSystemGestures: viewController.config.allowSystemGestures,
                    aspectRatioOverride: viewController.config.aspectRatioOverride,
                    pipOnLeave: viewController.config.pipOnLeave,
                  );
          }

          return Stack(
            children: [
              Center(
                child: ListenableBuilder(
                  listenable: viewController,
                  builder: (context, _) => LayoutBuilder(builder: (context, constraints) {
                    final fit = widget.viewController.config.videoFit;
                    return IgnorePointer(
                      ignoring: true,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
                          minHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
                          maxWidth: constraints.maxWidth,
                          maxHeight: constraints.maxHeight,
                        ),
                        child: FittedBox(
                          clipBehavior: Clip.hardEdge,
                          fit: fit ?? BoxFit.contain,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                              maxHeight: constraints.maxHeight,
                            ),
                            child: VideoPlatformView(
                              playerController: viewController.playerController,
                              showControls: false,
                              useSurfaceView: viewController.config.useSurfaceView,
                              allowSystemGestures: viewController.config.allowSystemGestures,
                              aspectRatioOverride: viewController.config.aspectRatioOverride,
                              pipOnLeave: viewController.config.pipOnLeave,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Positioned.fill(
                child: Builder(builder: (context) {
                  final controlsBuilder = viewController.config.controlsConfig.customBuilder ?? DefaultControls.builder;
                  return controlsBuilder(context);
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
