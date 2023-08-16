import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/utils/svg_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class DefaultCastPlayer extends StatelessWidget {
  const DefaultCastPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        BccmPlayerInterface.instance.openExpandedCastController();
      },
      child: ClipRect(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(color: BccmPlayerTheme.safeOf(context).controls?.settingsListBackgroundColor),
            child: Center(
              child: SvgPicture.string(
                SvgIcons.castButton,
                height: 100,
                colorFilter: ColorFilter.mode(BccmPlayerTheme.safeOf(context).controls?.primaryColor ?? Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
