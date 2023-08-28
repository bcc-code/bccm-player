// ignore_for_file: invalid_use_of_protected_member

import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/material.dart';

class FullscreenButton extends StatelessWidget {
  const FullscreenButton({
    super.key,
    required this.viewController,
    this.padding,
  });

  final BccmPlayerViewController viewController;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final controlsTheme = BccmPlayerTheme.safeOf(context).controls!;
    void onTap() {
      if (!viewController.isFullscreen) {
        viewController.enterFullscreen();
      } else {
        viewController.exitFullscreen();
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: double.infinity,
        padding: padding,
        child: FocusableActionDetector(
          actions: {
            ActivateIntent: CallbackAction<Intent>(
              onInvoke: (Intent intent) => onTap(),
            ),
          },
          child: Icon(
            viewController.isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: controlsTheme.iconColor,
          ),
        ),
      ),
    );
  }
}
