import 'dart:async';

import 'package:bccm_player/src/widgets/controls/control_fade_out.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ControlsState extends InheritedWidget {
  final bool visible;
  final Animation<double> visibilityAnimation;
  final Duration animationDuration = const Duration(milliseconds: 150);
  final VoidCallback hide;

  const ControlsState({
    super.key,
    required this.visible,
    required this.visibilityAnimation,
    required this.hide,
    required super.child,
  });

  static ControlsState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ControlsState>()!;
  }

  @override
  bool updateShouldNotify(ControlsState oldWidget) {
    return oldWidget.visible != visible || oldWidget.visibilityAnimation != visibilityAnimation;
  }
}

class ControlsWrapper extends StatefulWidget {
  const ControlsWrapper({
    super.key,
    required this.builder,
    required this.autoHide,
    this.showByDefault = true,
    this.isTv = false,
    this.pure = false,
  });

  final WidgetBuilder builder;
  final bool autoHide;
  final bool showByDefault;
  final bool isTv;

  /// If true, there won't be any UI changes (e.g. no backdrop).
  final bool pure;

  @override
  ControlsWrapperState createState() => ControlsWrapperState();
}

class ControlsWrapperState extends State<ControlsWrapper> with SingleTickerProviderStateMixin {
  bool _visible = true;
  Timer? _visibilityTimer;
  late AnimationController visibilityAnimationController;

  @override
  void initState() {
    super.initState();
    visibilityAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      value: widget.showByDefault ? 1.0 : 0.0,
    );
    _startTimer();
  }

  @override
  void dispose() {
    _visibilityTimer?.cancel();
    visibilityAnimationController.dispose();
    super.dispose();
  }

  void _setVisible(bool visible) {
    if (!mounted) return;
    setState(() {
      _visible = visible;
    });
    if (visible) {
      _startTimer();
    }
    visibilityAnimationController.animateTo(visible ? 1.0 : 0.0, duration: const Duration(milliseconds: 150));
  }

  void _startTimer() {
    _visibilityTimer?.cancel();
    _visibilityTimer = Timer(const Duration(seconds: 5), () {
      if (!widget.autoHide || !mounted) {
        return;
      }
      _setVisible(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ControlsState(
      visible: _visible,
      visibilityAnimation: visibilityAnimationController,
      hide: () {
        _setVisible(false);
      },
      child: Builder(builder: (context) {
        return Focus(
          debugLabel: "Controls wrapper",
          canRequestFocus: false,
          onFocusChange: (value) {
            _setVisible(value);
          },
          onKeyEvent: (node, event) {
            if (!widget.isTv) return KeyEventResult.ignored;
            if (_visible) return KeyEventResult.ignored;
            if (event.logicalKey != LogicalKeyboardKey.goBack) {
              _setVisible(true);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Listener(
            onPointerMove: (_) {
              _setVisible(true);
            },
            onPointerDown: (_) {
              _setVisible(true);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _setVisible(!_visible);
              },
              child: Stack(
                children: [
                  if (!widget.pure)
                    ControlFadeOut(
                      child: Container(
                        color: Colors.black38,
                      ),
                    ),
                  widget.builder(context),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
