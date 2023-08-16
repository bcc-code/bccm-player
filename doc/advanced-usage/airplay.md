### Airplay

An airplay button is not included out-of-the-box because bccm_player uses AVPlayerViewController, AVAudioSession, etc, under-the-hood so it should integrate quite seamlessly with other flutter airplay packages.

One such package is [flutter_to_airplay](https://pub.dev/packages/flutter_to_airplay):

```bash
flutter pub add flutter_to_airplay
```

````dart
import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_to_airplay/flutter_to_airplay.dart';

class MyPlayer extends StatelessWidget {
  const MyPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BccmPlayerView(
      BccmPlayerController.primary,
      config: BccmPlayerViewConfig(
        controlsConfig: BccmPlayerControlsConfig(
            additionalActionsBuilder: (context) => [
              if (Platform.isIOS)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Transform.scale(
                    scale: 0.85,
                    child: const AirPlayRoutePickerView(
                      width: 20,
                      height: 34,
                      prioritizesVideoDevices: true,
                      tintColor: Colors.white,
                      activeTintColor: Colors.white,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                )
            ],
        ),
      ),
    );
  }
}```
````
