import 'package:bccm_player/src/utils/extensions.dart';
import 'package:bccm_player/src/theme/controls_theme_data.dart';
import 'package:bccm_player/src/theme/mini_player_theme_data.dart';
import 'package:flutter/material.dart';

class BccmPlayerTheme extends InheritedWidget {
  BccmPlayerTheme({
    super.key,
    required this.playerTheme,
    Widget Function(BuildContext)? builder,
    Widget? child,
  })  : assert(child != null || builder != null, "Either child or builder must be set."),
        assert(child == null || builder == null, "You cant set both child and builder at the same time."),
        super(child: Builder(builder: builder ?? (context) => child!));

  final BccmPlayerThemeData playerTheme;

  @override
  bool updateShouldNotify(BccmPlayerTheme oldWidget) => oldWidget.playerTheme != playerTheme;
  static BccmPlayerThemeData? read(BuildContext context) =>
      context.getElementForInheritedWidgetOfExactType<BccmPlayerTheme>()?.widget.asOrNull<BccmPlayerTheme>()?.playerTheme;
  static BccmPlayerThemeData? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<BccmPlayerTheme>()?.playerTheme;
  static BccmPlayerThemeData rawOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<BccmPlayerTheme>()!.playerTheme;

  static BccmPlayerThemeData safeOf(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<BccmPlayerTheme>()?.playerTheme;
    final defaults = BccmPlayerThemeData.defaultTheme(context);
    return theme?.fillWithDefaults(defaults) ?? defaults;
  }
}

class BccmPlayerThemeData {
  BccmPlayerThemeData({this.miniPlayer, this.controls});

  final BccmMiniPlayerThemeData? miniPlayer;
  final BccmControlsThemeData? controls;

  factory BccmPlayerThemeData.defaultTheme(BuildContext context) {
    return BccmPlayerThemeData(
      miniPlayer: BccmMiniPlayerThemeData.defaultTheme(context),
      controls: BccmControlsThemeData.defaultTheme(context),
    );
  }

  BccmPlayerThemeData fillWithDefaults(BccmPlayerThemeData defaults) {
    return BccmPlayerThemeData(
      miniPlayer: miniPlayer?.fillWithDefaults(defaults.miniPlayer!) ?? defaults.miniPlayer,
      controls: controls?.fillWithDefaults(defaults.controls!) ?? defaults.controls,
    );
  }
}
