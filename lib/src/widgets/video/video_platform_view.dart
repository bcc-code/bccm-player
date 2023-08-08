import 'package:universal_io/io.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../bccm_player.dart';
import '../cast/cast_player.dart';

class VideoPlatformView extends StatefulWidget {
  final BccmPlayerController controller;
  final bool showControls;
  final bool? useSurfaceView;

  const VideoPlatformView({
    super.key,
    required this.controller,
    this.showControls = true,
    this.useSurfaceView,
  });

  @override
  State<VideoPlatformView> createState() => _VideoPlatformViewState();
}

class _VideoPlatformViewState extends State<VideoPlatformView> {
  late String playerId;
  late bool isInitialized;

  @override
  void initState() {
    super.initState();
    playerId = widget.controller.value.playerId;
    isInitialized = widget.controller.value.isInitialized;
    widget.controller.addListener(onControllerStateChanged);
  }

  void onControllerStateChanged() {
    if (!mounted) return;
    setState(() {
      playerId = widget.controller.value.playerId;
      isInitialized = widget.controller.value.isInitialized;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(onControllerStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.value.isInitialized == false) {
      return const SizedBox.shrink();
    } else if (widget.controller.value.playerId == 'chromecast') {
      return const CastPlayer();
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
    return HtmlElementView(viewType: 'bccm-player-${parent.controller.value.playerId}');
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
        'player_id': parent.controller.value.playerId,
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
            'player_id': parent.controller.value.playerId,
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
