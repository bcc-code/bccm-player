import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CastButton extends StatelessWidget {
  const CastButton({super.key, this.color});

  final methodChannel = const MethodChannel('bccm_player/cast_button');
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final creationParams = <String, dynamic>{
      if (color != null) 'color': color!.value,
    };
    if (Platform.isAndroid) {
      return SizedBox(
        width: 24,
        child: _Android(creationParams: creationParams),
      );
    } else if (Platform.isIOS && const String.fromEnvironment('IS_MAESTRO_TEST', defaultValue: 'false') != 'true') {
      return SizedBox(
        width: 24,
        child: UiKitView(
          viewType: 'bccm_player/cast_button',
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        ),
      );
    }
    return Container();
  }
}

class _Android extends StatelessWidget {
  const _Android({
    Key? key,
    required this.creationParams,
  }) : super(key: key);

  final Map<String, dynamic> creationParams;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: 'bccm_player/cast_button',
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
        return PlatformViewsService.initAndroidView(
          id: params.id,
          viewType: 'bccm_player/cast_button',
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () {
            params.onFocusChanged(true);
          },
        )
          ..addOnPlatformViewCreatedListener((val) {
            params.onPlatformViewCreated(val);
          })
          ..create();
      },
    );
  }
}
