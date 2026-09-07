import 'package:bccm_player/controls.dart';
import 'package:bccm_player/src/widgets/controls/controls_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Mounts a wrapper whose child reports the visibility it was handed.
  ///
  /// [child] matters for the key tests: the wrapper's `Focus` has
  /// `canRequestFocus: false`, so it only receives key events that bubble up
  /// from a focused descendant. With an unfocusable child its `onKeyEvent`
  /// never runs at all — which is not how the real controls are built.
  Future<void> pumpWrapper(
    WidgetTester tester, {
    required bool autoHide,
    bool showByDefault = true,
    bool isTv = false,
    bool pure = false,
    void Function(ControlsState)? capture,
    Widget? child,
  }) {
    return tester.pumpWidget(MaterialApp(
      home: ControlsWrapper(
        autoHide: autoHide,
        showByDefault: showByDefault,
        isTv: isTv,
        pure: pure,
        builder: (context) {
          capture?.call(ControlsState.of(context));
          return child ?? const Text('controls');
        },
      ),
    ));
  }

  ControlsWrapperState stateOf(WidgetTester tester) =>
      tester.state<ControlsWrapperState>(find.byType(ControlsWrapper));

  group('auto-hide', () {
    testWidgets('hides after five seconds when autoHide is on', (tester) async {
      late ControlsState controls;
      await pumpWrapper(tester, autoHide: true, capture: (c) => controls = c);

      expect(controls.visible, isTrue);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(controls.visible, isFalse);
    });

    testWidgets('stays visible when autoHide is off', (tester) async {
      late ControlsState controls;
      await pumpWrapper(tester, autoHide: false, capture: (c) => controls = c);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      expect(controls.visible, isTrue);
    });

    testWidgets('does not hide before the timer elapses', (tester) async {
      late ControlsState controls;
      await pumpWrapper(tester, autoHide: true, capture: (c) => controls = c);

      await tester.pump(const Duration(seconds: 4));

      expect(controls.visible, isTrue);
    });

    testWidgets('showByDefault false starts the animation closed', (tester) async {
      await pumpWrapper(tester, autoHide: false, showByDefault: false);

      expect(stateOf(tester).visibilityAnimationController.value, 0.0);
    });

    testWidgets('showByDefault true starts the animation open', (tester) async {
      await pumpWrapper(tester, autoHide: false);

      expect(stateOf(tester).visibilityAnimationController.value, 1.0);
    });
  });

  group('pointer interaction', () {
    testWidgets('tapping toggles visibility', (tester) async {
      late ControlsState controls;
      await pumpWrapper(tester, autoHide: false, capture: (c) => controls = c);

      await tester.tap(find.text('controls'));
      await tester.pumpAndSettle();
      expect(controls.visible, isFalse);

      await tester.tap(find.byType(ControlsWrapper));
      await tester.pumpAndSettle();
      expect(controls.visible, isTrue);
    });

    testWidgets('a pointer move brings hidden controls back', (tester) async {
      late ControlsState controls;
      await pumpWrapper(tester, autoHide: false, capture: (c) => controls = c);

      // Put the pointer down first (which shows them), then hide, so the move
      // below is what does the work rather than onPointerDown.
      final gesture = await tester.startGesture(tester.getCenter(find.text('controls')));
      await tester.pumpAndSettle();
      controls.hide();
      await tester.pumpAndSettle();
      expect(controls.visible, isFalse);

      await gesture.moveTo(const Offset(100, 100));
      await tester.pumpAndSettle();
      expect(controls.visible, isTrue);

      await gesture.up();
    });

    testWidgets('a pointer down brings hidden controls back', (tester) async {
      late ControlsState controls;
      await pumpWrapper(tester, autoHide: true, capture: (c) => controls = c);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(controls.visible, isFalse);

      final gesture = await tester.startGesture(tester.getCenter(find.text('controls')));
      await tester.pumpAndSettle();

      expect(controls.visible, isTrue);
      await gesture.up();
    });

    testWidgets('the auto-hide timer restarts every time the controls are shown', (tester) async {
      late ControlsState controls;
      await pumpWrapper(tester, autoHide: true, capture: (c) => controls = c);

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byType(ControlsWrapper)); // hide
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ControlsWrapper)); // show, restarting the timer
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 4));
      expect(controls.visible, isTrue, reason: 'the 5s window restarted on show');

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(controls.visible, isFalse);
    });
  });

  group('hide callback', () {
    testWidgets('ControlsState.hide hides the controls', (tester) async {
      late ControlsState controls;
      await pumpWrapper(tester, autoHide: false, capture: (c) => controls = c);

      controls.hide();
      await tester.pumpAndSettle();

      expect(controls.visible, isFalse);
    });
  });

  group('backdrop', () {
    testWidgets('renders a scrim by default', (tester) async {
      await pumpWrapper(tester, autoHide: false);

      expect(find.byType(ControlFadeOut), findsOneWidget);
    });

    testWidgets('pure suppresses the scrim', (tester) async {
      await pumpWrapper(tester, autoHide: false, pure: true);

      expect(find.byType(ControlFadeOut), findsNothing);
    });
  });

  group('TV key handling', () {
    /// A focusable button that records activations, so we can tell whether a key
    /// press reached the focused control or was swallowed by the wrapper.
    ///
    /// Deliberately activated through the ancestor Shortcuts/Actions that
    /// MaterialApp installs — the same route the real IconButtons take. A Focus
    /// with its own `onKeyEvent` would sit *below* the wrapper and consume the
    /// key first, since key events travel from the focused node upwards.
    Widget activateProbe(List<String> activations) => ElevatedButton(
          autofocus: true,
          onPressed: () => activations.add('pressed'),
          child: const Text('controls'),
        );

    testWidgets('the first key press only wakes the controls, without activating', (tester) async {
      // Otherwise waking a TV player would also trigger whatever button
      // happened to hold focus.
      final activations = <String>[];
      late ControlsState controls;
      await pumpWrapper(
        tester,
        autoHide: true,
        isTv: true,
        capture: (c) => controls = c,
        child: activateProbe(activations),
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(controls.visible, isFalse);

      await _sendKey(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(controls.visible, isTrue);
      expect(activations, isEmpty, reason: 'the wake-up press was consumed');
    });

    testWidgets('a key press with the controls visible reaches the control', (tester) async {
      final activations = <String>[];
      await pumpWrapper(
        tester,
        autoHide: false,
        isTv: true,
        child: activateProbe(activations),
      );

      await _sendKey(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(activations, ['pressed']);
    });

    testWidgets('the back key does not wake the controls', (tester) async {
      // Back has to keep closing the player rather than being eaten as a
      // wake-up press.
      late ControlsState controls;
      await pumpWrapper(
        tester,
        autoHide: true,
        isTv: true,
        capture: (c) => controls = c,
        child: activateProbe([]),
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await _sendKey(tester, LogicalKeyboardKey.goBack);
      await tester.pumpAndSettle();

      expect(controls.visible, isFalse);
    });

    testWidgets('the wake-on-key behaviour is TV-only', (tester) async {
      final activations = <String>[];
      late ControlsState controls;
      await pumpWrapper(
        tester,
        autoHide: true,
        capture: (c) => controls = c,
        child: activateProbe(activations),
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(controls.visible, isFalse);

      await _sendKey(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(controls.visible, isFalse, reason: 'no wake-on-key off TV');
      expect(activations, ['pressed'], reason: 'and the key is not swallowed either');
    });
  });

  group('focus', () {
    testWidgets('a descendant taking focus reveals the controls', (tester) async {
      late ControlsState controls;
      await pumpWrapper(
        tester,
        autoHide: false,
        showByDefault: false,
        capture: (c) => controls = c,
        child: const Focus(autofocus: true, child: Text('controls')),
      );
      await tester.pumpAndSettle();

      expect(controls.visible, isTrue);
    });
  });

  group('ControlsState.updateShouldNotify', () {
    ControlsState state({required bool visible, required Animation<double> animation}) => ControlsState(
          visible: visible,
          visibilityAnimation: animation,
          hide: () {},
          child: const SizedBox.shrink(),
        );

    test('notifies only when visibility or the animation identity changes', () {
      const a = AlwaysStoppedAnimation(1.0);
      const b = AlwaysStoppedAnimation(0.0);

      expect(state(visible: true, animation: a).updateShouldNotify(state(visible: true, animation: a)),
          isFalse);
      expect(state(visible: false, animation: a).updateShouldNotify(state(visible: true, animation: a)),
          isTrue);
      expect(state(visible: true, animation: b).updateShouldNotify(state(visible: true, animation: a)),
          isTrue);
    });
  });
}

/// Sends a key down/up through the focus tree.
///
/// `goBack` (the Android TV back button) is awkward to simulate: the harness
/// cannot infer a physical key for it, and `browserBack` is absent from every
/// platform's scan-code map except web's. Hence the special case — it is a
/// limitation of the test key maps, not of the code under test.
Future<void> _sendKey(WidgetTester tester, LogicalKeyboardKey key) async {
  final isGoBack = key == LogicalKeyboardKey.goBack;
  final physical = isGoBack ? PhysicalKeyboardKey.browserBack : null;
  final platform = isGoBack ? 'web' : null;
  await tester.sendKeyDownEvent(key, physicalKey: physical, platform: platform);
  await tester.sendKeyUpEvent(key, physicalKey: physical, platform: platform);
}
