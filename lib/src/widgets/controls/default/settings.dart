// ignore_for_file: invalid_use_of_protected_member

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:bccm_player/src/widgets/controls/default/settings_option_list.dart';
import 'package:bccm_player/theme/bccm_player_theme.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

class SettingsButton extends HookWidget {
  const SettingsButton({
    super.key,
    required this.controller,
    required this.controlsTheme,
    this.padding,
    this.playbackSpeeds,
    this.hidePlaybackSpeed,
    this.hideQualitySelector,
  });

  final BccmPlayerController controller;
  final ControlsThemeData controlsTheme;
  final EdgeInsets? padding;
  final List<double>? playbackSpeeds;
  final bool? hidePlaybackSpeed;
  final bool? hideQualitySelector;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // open bottom sheet with settings
        showModalBottomSheet(
          context: context,
          isDismissible: true,
          builder: (context) => _SettingsBottomSheet(
            controller: controller,
            controlsTheme: controlsTheme,
            playbackSpeeds: playbackSpeeds ?? const [0.75, 1.0, 1.25, 1.5, 2.0],
            hidePlaybackSpeed: hidePlaybackSpeed,
            hideQualitySelector: hideQualitySelector,
          ),
        );
      },
      child: Padding(
        padding: padding ?? const EdgeInsets.all(0),
        child: Icon(Icons.settings, color: controlsTheme.iconColor),
      ),
    );
  }
}

class _SettingsBottomSheet extends HookWidget {
  const _SettingsBottomSheet({
    required this.controller,
    required this.controlsTheme,
    required this.playbackSpeeds,
    required this.hidePlaybackSpeed,
    required this.hideQualitySelector,
  });

  final BccmPlayerController controller;
  final ControlsThemeData controlsTheme;
  final List<double> playbackSpeeds;
  final bool? hidePlaybackSpeed;
  final bool? hideQualitySelector;

  @override
  Widget build(BuildContext context) {
    final tracksFuture = useState(useMemoized(controller.getTracks));
    final tracksSnapshot = useFuture(tracksFuture.value);

    if (tracksSnapshot.data == null && tracksSnapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    } else if (tracksSnapshot.hasError) {
      return Center(child: Text(tracksSnapshot.error.toString()));
    }

    final tracksData = tracksSnapshot.data;
    if (tracksData == null) {}

    final selectedAudioTrack = tracksData?.audioTracks.safe.firstWhereOrNull((element) => element.isSelected);
    final selectedTextTrack = tracksData?.textTracks.safe.firstWhereOrNull((element) => element.isSelected);
    final selectedVideoTrack = tracksData?.videoTracks.safe.firstWhereOrNull((element) => element.isSelected);
    var uniqueHeights = <int>{};
    final uniqueVideoTracks = tracksData?.videoTracks.safe.where((t) => uniqueHeights.add(t.height ?? 0)).toList();

    final playbackSpeed = useState(controller.value.playbackSpeed);
    final isLive = useState(false);
    final playbackState = useState(controller.value.playbackState);
    useEffect(() {
      void listener() {
        playbackSpeed.value = controller.value.playbackSpeed;
        isLive.value = controller.value.currentMediaItem?.isLive == true;
        if (playbackState.value != controller.value.playbackState) {
          playbackState.value = controller.value.playbackState;
          tracksFuture.value = controller.getTracks();
        }
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    });

    final settings = [
      if (tracksData != null && tracksData.audioTracks.length > 1)
        ListTile(
          dense: true,
          onTap: () async {
            final selected = await showModalOptionList<Track>(
              context: context,
              options: [
                ...tracksData.audioTracks.safe.map(
                  (track) => SettingsOption(value: track, label: track.labelWithFallback, isSelected: track.isSelected),
                )
              ],
            );
            if (selected != null && context.mounted) {
              await controller.setSelectedTrack(TrackType.audio, selected.value.id);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (!context.mounted) return;
                tracksFuture.value = controller.getTracks();
              });
            }
          },
          title: Text(
            'Audio: ${selectedAudioTrack?.labelWithFallback ?? 'N/A'}',
            style: controlsTheme.settingsListTextStyle,
          ),
        ),
      if (tracksData?.textTracks.isNotEmpty == true)
        ListTile(
          dense: true,
          title: Text('Subtitles: ${selectedTextTrack?.labelWithFallback ?? 'None'}', style: controlsTheme.settingsListTextStyle),
          onTap: () async {
            final selected = await showModalOptionList<Track?>(
              context: context,
              options: [
                SettingsOption(value: null, label: "None", isSelected: selectedTextTrack == null),
                ...tracksData!.textTracks.safe.map(
                  (track) => SettingsOption(value: track, label: track.labelWithFallback, isSelected: track.isSelected),
                )
              ],
            );
            if (selected != null && context.mounted) {
              await controller.setSelectedTrack(TrackType.text, selected.value?.id);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (!context.mounted) return;
                tracksFuture.value = controller.getTracks();
              });
            }
          },
        ),
      if (hidePlaybackSpeed == false || hidePlaybackSpeed == null && !isLive.value)
        ListTile(
          dense: true,
          title: Text('Playback speed: ${playbackSpeed.value.toStringAsFixed(1)}x', style: controlsTheme.settingsListTextStyle),
          onTap: () async {
            final selected = await showModalOptionList<double>(
              context: context,
              options: playbackSpeeds
                  .map(
                    (speed) => SettingsOption(
                      value: speed,
                      label: "${speed}x",
                      isSelected: speed == playbackSpeed.value,
                    ),
                  )
                  .toList(),
            );
            if (selected != null && context.mounted) {
              controller.setPlaybackSpeed(selected.value);
            }
          },
        ),
      if (hideQualitySelector != true && uniqueVideoTracks != null && uniqueVideoTracks.length > 1)
        ListTile(
          dense: true,
          title: Text('${Platform.isIOS ? 'Max ' : ''}Quality: ${selectedVideoTrack?.labelWithFallback ?? 'Auto'}',
              style: controlsTheme.settingsListTextStyle),
          onTap: () async {
            final selected = await showModalOptionList<Track?>(
              context: context,
              options: [
                SettingsOption(value: null, label: "Auto", isSelected: selectedVideoTrack == null),
                ...uniqueVideoTracks.map(
                  (track) => SettingsOption(value: track, label: track.labelWithFallback, isSelected: track.isSelected),
                )
              ],
            );
            if (selected != null && context.mounted) {
              await controller.setSelectedTrack(
                TrackType.video,
                selected.value != null ? selected.value!.id : autoTrackId,
              );
              Future.delayed(const Duration(milliseconds: 100), () {
                if (!context.mounted) return;
                tracksFuture.value = controller.getTracks();
              });
            }
          },
        ),
    ];

    return Container(
      color: controlsTheme.settingsListBackgroundColor,
      child: ListView(
        shrinkWrap: true,
        children: [
          ...settings,
          if (settings.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              alignment: Alignment.center,
              child: const Text('No settings available for this video.'),
            ),
        ],
      ),
    );
  }
}
