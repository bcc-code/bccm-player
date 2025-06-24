import 'package:flutter/material.dart';

class BccmMiniPlayerThemeData {
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? thumbnailBorderColor;
  final Color? topBorderColor;
  final Color? progressColor;
  final TextStyle? titleStyle;
  final TextStyle? secondaryTitleStyle;

  BccmMiniPlayerThemeData({
    this.iconColor,
    this.backgroundColor,
    this.thumbnailBorderColor,
    this.topBorderColor,
    this.progressColor,
    this.titleStyle,
    this.secondaryTitleStyle,
  });

  factory BccmMiniPlayerThemeData.defaultTheme(BuildContext context) {
    final theme = Theme.of(context);
    return BccmMiniPlayerThemeData(
      iconColor: theme.colorScheme.onSurface,
      backgroundColor: theme.colorScheme.surface,
      thumbnailBorderColor: Colors.white.withOpacity(0.01),
      topBorderColor: theme.colorScheme.onSurface.withOpacity(0.1),
      progressColor: theme.colorScheme.onSurface,
      titleStyle: theme.textTheme.labelMedium!.copyWith(color: theme.colorScheme.onSurface),
      secondaryTitleStyle: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
    );
  }

  BccmMiniPlayerThemeData fillWithDefaults(BccmMiniPlayerThemeData defaults) {
    return BccmMiniPlayerThemeData(
      iconColor: iconColor ?? defaults.iconColor,
      backgroundColor: backgroundColor ?? defaults.backgroundColor,
      thumbnailBorderColor: thumbnailBorderColor ?? defaults.thumbnailBorderColor,
      topBorderColor: topBorderColor ?? defaults.topBorderColor,
      progressColor: progressColor ?? defaults.progressColor,
      titleStyle: titleStyle ?? defaults.titleStyle,
      secondaryTitleStyle: secondaryTitleStyle ?? defaults.secondaryTitleStyle,
    );
  }

  BccmMiniPlayerThemeData copyWith({
    Color? iconColor,
    Color? backgroundColor,
    Color? thumbnailBorderColor,
    Color? topBorderColor,
    Color? progressColor,
    TextStyle? titleStyle,
    TextStyle? secondaryTitleStyle,
  }) {
    return BccmMiniPlayerThemeData(
      iconColor: iconColor ?? this.iconColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      thumbnailBorderColor: thumbnailBorderColor ?? this.thumbnailBorderColor,
      topBorderColor: topBorderColor ?? this.topBorderColor,
      progressColor: progressColor ?? this.progressColor,
      titleStyle: titleStyle ?? this.titleStyle,
      secondaryTitleStyle: secondaryTitleStyle ?? this.secondaryTitleStyle,
    );
  }
}
