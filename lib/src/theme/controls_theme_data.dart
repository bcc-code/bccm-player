import 'package:flutter/material.dart';

class BccmControlsThemeData {
  final Color? primaryColor;
  final Color? iconColor;
  final TextStyle? durationTextStyle;
  final Color? settingsListBackgroundColor;
  final TextStyle? settingsListTextStyle;
  final TextStyle? fullscreenTitleStyle;
  final SliderThemeData? progressBarTheme;
  final Color? playNextButtonBackgroundColor;
  final Color? playNextButtonProgressColor;

  BccmControlsThemeData({
    this.primaryColor,
    this.iconColor,
    this.durationTextStyle,
    this.settingsListBackgroundColor,
    this.settingsListTextStyle,
    this.fullscreenTitleStyle,
    this.progressBarTheme,
    this.playNextButtonBackgroundColor,
    this.playNextButtonProgressColor,
  });

  factory BccmControlsThemeData.defaultTheme(BuildContext context) {
    final theme = Theme.of(context);
    return BccmControlsThemeData(
      primaryColor: theme.colorScheme.primary,
      iconColor: Colors.white,
      durationTextStyle: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface),
      settingsListBackgroundColor: theme.colorScheme.surface,
      settingsListTextStyle: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface),
      fullscreenTitleStyle: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface),
      progressBarTheme: SliderThemeData(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: theme.colorScheme.primary,
        inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.2),
        thumbColor: theme.colorScheme.primary,
      ),
      playNextButtonBackgroundColor: Colors.blue.withOpacity(0.75),
      playNextButtonProgressColor: Colors.blue,
    );
  }

  BccmControlsThemeData fillWithDefaults(BccmControlsThemeData defaults) {
    return BccmControlsThemeData(
      primaryColor: primaryColor ?? defaults.primaryColor,
      iconColor: primaryColor ?? iconColor ?? defaults.iconColor,
      durationTextStyle: durationTextStyle ?? defaults.durationTextStyle,
      settingsListBackgroundColor: settingsListBackgroundColor ?? defaults.settingsListBackgroundColor,
      settingsListTextStyle: settingsListTextStyle ?? defaults.settingsListTextStyle,
      fullscreenTitleStyle: fullscreenTitleStyle ?? defaults.fullscreenTitleStyle,
      progressBarTheme: progressBarTheme ??
          (primaryColor == null
              ? defaults.progressBarTheme
              : defaults.progressBarTheme?.copyWith(activeTrackColor: primaryColor, thumbColor: primaryColor)),
      playNextButtonBackgroundColor: playNextButtonBackgroundColor ?? defaults.playNextButtonBackgroundColor,
      playNextButtonProgressColor: playNextButtonProgressColor ?? defaults.playNextButtonProgressColor,
    );
  }

  BccmControlsThemeData copyWith({
    Color? primaryColor,
    Color? iconColor,
    TextStyle? durationTextStyle,
    Color? settingsListBackgroundColor,
    TextStyle? settingsListTextStyle,
    TextStyle? fullscreenTitleStyle,
    SliderThemeData? progressBarTheme,
    Color? playNextButtonBackgroundColor,
    Color? playNextButtonProgressColor,
  }) {
    return BccmControlsThemeData(
      primaryColor: primaryColor ?? this.primaryColor,
      iconColor: iconColor ?? this.iconColor,
      durationTextStyle: durationTextStyle ?? this.durationTextStyle,
      settingsListBackgroundColor: settingsListBackgroundColor ?? this.settingsListBackgroundColor,
      settingsListTextStyle: settingsListTextStyle ?? this.settingsListTextStyle,
      fullscreenTitleStyle: fullscreenTitleStyle ?? this.fullscreenTitleStyle,
      progressBarTheme: progressBarTheme ?? this.progressBarTheme,
      playNextButtonBackgroundColor: playNextButtonBackgroundColor ?? this.playNextButtonBackgroundColor,
      playNextButtonProgressColor: playNextButtonProgressColor ?? this.playNextButtonProgressColor,
    );
  }
}
