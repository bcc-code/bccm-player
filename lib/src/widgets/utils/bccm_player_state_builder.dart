/*

Modified version of flutter_state_notifier:
https://github.com/rrousselGit/state_notifier/blob/master/packages/flutter_state_notifier/lib/flutter_state_notifier.dart

MIT License

Copyright (c) 2020 Remi Rousselet

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

import 'package:bccm_player/bccm_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:state_notifier/state_notifier.dart';

class BccmPlayerStateBuilder<T> extends StatelessWidget {
  const BccmPlayerStateBuilder({
    super.key,
    required this.playerId,
    required this.builder,
    required this.select,
  });

  final String? playerId;
  final Widget Function(BuildContext context, T? state) builder;
  final T Function(PlayerState state) select;

  @override
  Widget build(BuildContext context) {
    if (playerId != null) {
      return buildForPlayerId(context, playerId);
    }

    return StateNotifierSelectBuilder<PlayerPluginState, String?>(
      stateNotifier: BccmPlayerInterface.instance.stateNotifier,
      select: (state) => state.primaryPlayerId,
      builder: (context, value, child) {
        return buildForPlayerId(context, value);
      },
    );
  }

  Widget buildForPlayerId(BuildContext context, String? playerId) {
    if (playerId == null) return builder(context, null);

    final notifier = BccmPlayerInterface.instance.stateNotifier.getPlayerNotifier(playerId);
    if (notifier == null) return builder(context, null);

    return StateNotifierSelectBuilder<PlayerState, T>(
      stateNotifier: notifier,
      builder: (context, state, child) => builder(context, state),
      select: select,
    );
  }
}

/// {@template flutter_state_notifier.state_notifier_builder}
/// Listens to a [StateNotifier] and use it builds a widget tree based on the
/// latest value.
///
/// This is similar to [ValueListenableBuilder] for [ValueNotifier].
/// {@endtemplate}
class StateNotifierSelectBuilder<T, T2> extends StatefulWidget {
  /// {@macro flutter_state_notifier.state_notifier_builder}
  const StateNotifierSelectBuilder({
    Key? key,
    required this.builder,
    required this.stateNotifier,
    required this.select,
    this.child,
  }) : super(key: key);

  /// A callback that builds a [Widget] based on the current value of [stateNotifier]
  ///
  /// Cannot be `null`.
  final ValueWidgetBuilder<T2?> builder;

  /// The listened to [StateNotifier].
  ///
  /// Cannot be `null`.
  final StateNotifier<T> stateNotifier;

  final T2 Function(T state) select;

  /// A cache of a subtree that does not depend on [stateNotifier].
  ///
  /// It will be sent untouched to [builder]. This is useful for performance
  /// optimizations to not rebuild the entire widget tree if it isn't needed.
  final Widget? child;

  @override
  StateNotifierSelectBuilderState<T, T2> createState() => StateNotifierSelectBuilderState<T, T2>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<StateNotifier<T>>('stateNotifier', stateNotifier),
      )
      ..add(DiagnosticsProperty<Widget>('child', child))
      ..add(ObjectFlagProperty<ValueWidgetBuilder<T2>>.has('builder', builder));
  }
}

class StateNotifierSelectBuilderState<T, T2> extends State<StateNotifierSelectBuilder<T, T2>> {
  T2? state;
  VoidCallback? removeListener;

  @override
  void initState() {
    super.initState();
    _listen(widget.stateNotifier);
  }

  @override
  void didUpdateWidget(StateNotifierSelectBuilder<T, T2> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stateNotifier != oldWidget.stateNotifier) {
      _listen(widget.stateNotifier);
    }
  }

  void _listen(StateNotifier<T> notifier) {
    removeListener?.call();
    removeListener = notifier.addListener(_listener);
  }

  void _listener(T value) {
    final temp = widget.select(value);
    if (!identical(temp, state)) {
      setState(() => state = temp);
    }
  }

  @override
  void dispose() {
    removeListener?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, state, widget.child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T2>('state', state));
  }
}
