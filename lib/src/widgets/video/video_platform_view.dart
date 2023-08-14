import 'package:universal_io/io.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../bccm_player.dart';
import '../cast/cast_player.dart';

/// Creates a platform view for video playback.
///
/// Use this if you need a very custom setup, otherwise use [BccmPlayerView] which provides a simpler API.
class VideoPlatformView extends StatefulWidget {
  final BccmPlayerController playerController;
  final bool showControls;
  final bool? useSurfaceView;

  const VideoPlatformView({
    super.key,
    required this.playerController,
    required this.showControls,
    this.useSurfaceView,
  });

  @override
  State<VideoPlatformView> createState() => _VideoPlatformViewState();
}

class _VideoPlatformViewState extends State<VideoPlatformView> {
  late String playerId;
  late bool isInitialized;
  late bool isCurrentPlayerView;

  void onPlayerControllerUpdate() {
    if (!mounted) return;
    final newIsCurrentPlayerView = widget.playerController.currentPlayerView == this;
    final anyRelevantFieldHasChanged = playerId != widget.playerController.value.playerId ||
        isInitialized != widget.playerController.value.isInitialized ||
        isCurrentPlayerView != newIsCurrentPlayerView;

    if (anyRelevantFieldHasChanged) {
      debugPrint('bccm: Updating state isCurrent:$newIsCurrentPlayerView for $this');
      setState(() {
        isCurrentPlayerView = newIsCurrentPlayerView;
        playerId = widget.playerController.value.playerId;
        isInitialized = widget.playerController.value.isInitialized;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.playerController.addListener(onPlayerControllerUpdate);
    playerId = widget.playerController.value.playerId;
    isInitialized = widget.playerController.value.isInitialized;
    isCurrentPlayerView = widget.playerController.currentPlayerView == this;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.playerController.attach(this);
    });
  }

  @override
  void dispose() {
    widget.playerController.removeListener(onPlayerControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.playerController.detach(this);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isCurrentPlayerView) {
      debugPrint('bccm: hiding $playerId in $this');
      return AspectRatio(aspectRatio: 16 / 9, child: Container(color: const Color(0xff000000)));
    }
    if (widget.playerController.value.isInitialized == false) {
      return const SizedBox.shrink();
    } else if (widget.playerController.value.playerId == 'chromecast') {
      return const DefaultCastPlayer();
    }

    Widget getPlatformSpecificPlayer() {
      if (kIsWeb) {
        return _WebPlayer(parent: widget);
      } else if (Platform.isAndroid) {
        return _AndroidPlayer(parent: widget);
      } else if (Platform.isIOS) {
        return _IOSPlayer(parent: widget);
      }
      return const SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: getPlatformSpecificPlayer(),
    );
  }
}

class _WebPlayer extends StatelessWidget {
  const _WebPlayer({
    required this.parent,
  });

  final VideoPlatformView parent;

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: 'bccm-player-${parent.playerController.value.playerId}');
  }
}

class _IOSPlayer extends StatelessWidget {
  const _IOSPlayer({
    required this.parent,
  });

  final VideoPlatformView parent;

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: 'bccm-player',
      hitTestBehavior: PlatformViewHitTestBehavior.translucent,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(
          () => EagerGestureRecognizer(),
        ),
      },
      creationParams: <String, dynamic>{
        'player_id': parent.playerController.value.playerId,
        'show_controls': parent.showControls,
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

class _AndroidPlayer extends StatelessWidget {
  const _AndroidPlayer({
    Key? key,
    required this.parent,
  }) : super(key: key);

  final VideoPlatformView parent;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: 'bccm-player',
      surfaceFactory: (context, controller) {
        debugPrint("viewId ${controller.viewId}");
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          gestureRecognizers: {
            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
            Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
          },
        );
      },
      onCreatePlatformView: (params) {
        var controller = PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: 'bccm-player',
          layoutDirection: TextDirection.ltr,
          creationParams: <String, dynamic>{
            'player_id': parent.playerController.value.playerId,
            'show_controls': parent.showControls,
            if (parent.useSurfaceView == true) 'use_surface_view': true,
          },
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () {
            params.onFocusChanged(true);
          },
        );
        controller
          ..addOnPlatformViewCreatedListener((val) {
            params.onPlatformViewCreated(val);
          })
          ..create();
        return controller;
      },
    );
  }
}
