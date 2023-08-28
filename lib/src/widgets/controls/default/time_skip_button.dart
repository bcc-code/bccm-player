import 'package:bccm_player/src/theme/bccm_player_theme.dart';
import 'package:flutter/material.dart';

class TimeSkipButton extends StatelessWidget {
  const TimeSkipButton({
    super.key,
    required this.forwardRewindDurationSec,
    required this.icon,
    required this.onPressed,
    this.iconSize = 52,
  });

  final int forwardRewindDurationSec;
  final Widget icon;
  final VoidCallback onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final controlsTheme = BccmPlayerTheme.safeOf(context).controls;
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(
            "$forwardRewindDurationSec",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: controlsTheme?.iconColor,
            ),
          ),
        ),
        IconButton(
          icon: icon,
          padding: const EdgeInsets.all(0),
          iconSize: iconSize,
          color: controlsTheme?.iconColor,
          onPressed: onPressed,
        ),
      ],
    );
  }
}
