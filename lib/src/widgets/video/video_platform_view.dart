import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:universal_io/io.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../bccm_player.dart';
import '../cast/cast_player.dart';

class VideoPlatformView extends StatefulWidget implements BccmPlayerView {
  final BccmPlayerController playerController;
  final bool showControls;
  final bool? useSurfaceView;
  final bool? allowSystemGestures;

  /// Creates a platform view for video playback.
  ///
  /// Use this if you need a very custom setup, otherwise use [BccmPlayerView] which provides a simpler API.
  const VideoPlatformView({
    super.key,
    required this.playerController,
    required this.showControls,
    this.useSurfaceView,
    this.allowSystemGestures,
  });

  @override
  State<VideoPlatformView> createState() => _VideoPlatformViewState();
}

class _VideoPlatformViewState extends State<VideoPlatformView> {
  late String playerId;
  late bool isInitialized;
  late bool isCurrentPlayerView;
  late VideoSize? lastKnownSize;

  void onPlayerControllerUpdate() {
    if (!mounted) return;
    final newIsCurrentPlayerView = widget.playerController.currentPlayerView == this;
    final anyRelevantFieldHasChanged = playerId != widget.playerController.value.playerId ||
        isInitialized != widget.playerController.value.isInitialized ||
        isCurrentPlayerView != newIsCurrentPlayerView ||
        widget.playerController.value.videoSize != lastKnownSize;

    if (anyRelevantFieldHasChanged) {
      setState(() {
        isCurrentPlayerView = newIsCurrentPlayerView;
        playerId = widget.playerController.value.playerId;
        isInitialized = widget.playerController.value.isInitialized;
        lastKnownSize = widget.playerController.value.videoSize;
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
    lastKnownSize = widget.playerController.value.videoSize;
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
    final aspectRatio = lastKnownSize?.aspectRatio ?? 16 / 9;
    if (!isCurrentPlayerView || widget.playerController.value.isInitialized == false) {
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(color: const Color(0x00000000)),
      );
    }

    if (widget.playerController.value.playerId == 'chromecast') {
      return DefaultCastPlayer(aspectRatio: aspectRatio);
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
      aspectRatio: aspectRatio,
      child: Focus(
        canRequestFocus: widget.showControls,
        descendantsAreFocusable: widget.showControls,
        descendantsAreTraversable: widget.showControls,
        child: getPlatformSpecificPlayer(),
      ),
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
            if (parent.allowSystemGestures == true) 'allow_system_gestures': true,
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
