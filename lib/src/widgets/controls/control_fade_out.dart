import 'package:flutter/material.dart';

import 'controls_wrapper.dart';

class ControlFadeOut extends StatelessWidget {
  const ControlFadeOut({super.key, required this.child, this.blockBackgroundClicks});

  final Widget child;
  final bool? blockBackgroundClicks;

  @override
  Widget build(BuildContext context) {
    final animation = ControlsState.of(context).visibilityAnimation;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => IgnorePointer(
        ignoring: animation.value < 0.1,
        child: Opacity(
          opacity: animation.value,
          child: _maybeBlock(child!),
        ),
      ),
    );
  }

  Widget _maybeBlock(Widget child) {
    if (blockBackgroundClicks == true) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => debugPrint("blocked"),
            ),
          ),
          child,
        ],
      );
    }
    return child;
  }
}
