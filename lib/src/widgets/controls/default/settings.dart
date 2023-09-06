// ignore_for_file: invalid_use_of_protected_member

import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/src/pigeon/playback_platform_pigeon.g.dart';
import 'package:bccm_player/src/widgets/controls/default/settings_option_list.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

class SettingsButton extends HookWidget {
  const SettingsButton({
    super.key,
    required this.viewController,
    required this.controlsTheme,
    this.padding,
    this.playbackSpeeds,
    this.hidePlaybackSpeed,
    this.hideQualitySelector,
    this.iconSize = 24,
    this.removePadding = false,
  });

  final BccmPlayerViewController viewController;
  final BccmControlsThemeData controlsTheme;
  final EdgeInsets? padding;
  final List<double>? playbackSpeeds;
  final bool? hidePlaybackSpeed;
  final bool? hideQualitySelector;
  final double iconSize;
  final bool removePadding;

  @override
  Widget build(BuildContext context) {
    final focusing = useState(false);

    void onTap() {
      // open bottom sheet with settings
      showModalBottomSheet(
        context: context,
        isDismissible: true,
        builder: (context) => _SettingsBottomSheet(viewController: viewController),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(0),
        child: FocusableActionDetector(
          actions: {
            ActivateIntent: CallbackAction<Intent>(
              onInvoke: (Intent intent) => onTap(),
            ),
          },
          onFocusChange: (value) => focusing.value = value,
          child: SizedBox(
            width: removePadding ? iconSize : null,
            height: removePadding ? iconSize : null,
            child: IconButton(
              onPressed: onTap,
              icon: const Icon(
                Icons.settings,
              ),
              constraints: removePadding ? const BoxConstraints() : null,
              padding: removePadding ? EdgeInsets.zero : null,
              iconSize: iconSize,
              color: controlsTheme.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsBottomSheet extends HookWidget {
  const _SettingsBottomSheet({required this.viewController});

  final BccmPlayerViewController viewController;

  @override
  Widget build(BuildContext context) {
    final controlsTheme = BccmPlayerTheme.safeOf(context).controls ?? BccmControlsThemeData.defaultTheme(context);
    final playerController = viewController.playerController;
    final controlsConfig = viewController.config.controlsConfig;
    final tracksFuture = useState(useMemoized(playerController.getTracks));
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

    final playbackSpeed = useState(playerController.value.playbackSpeed);
    final isLive = useState(playerController.value.currentMediaItem?.isLive == true);
    final playbackState = useState(playerController.value.playbackState);
    useEffect(() {
      void listener() {
        playbackSpeed.value = playerController.value.playbackSpeed;
        isLive.value = playerController.value.currentMediaItem?.isLive == true;
        if (playbackState.value != playerController.value.playbackState) {
          playbackState.value = playerController.value.playbackState;
          tracksFuture.value = playerController.getTracks();
        }
      }

      playerController.addListener(listener);
      return () => playerController.removeListener(listener);
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
              await playerController.setSelectedTrack(TrackType.audio, selected.value.id);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (!context.mounted) return;
                tracksFuture.value = playerController.getTracks();
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
              await playerController.setSelectedTrack(TrackType.text, selected.value?.id);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (!context.mounted) return;
                tracksFuture.value = playerController.getTracks();
              });
            }
          },
        ),
      if (controlsConfig.hidePlaybackSpeed == false || controlsConfig.hidePlaybackSpeed == null && !isLive.value)
        ListTile(
          dense: true,
          title: Text('Playback speed: ${playbackSpeed.value.toStringAsFixed(1)}x', style: controlsTheme.settingsListTextStyle),
          onTap: () async {
            final selected = await showModalOptionList<double>(
              context: context,
              options: controlsConfig.playbackSpeeds
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
              playerController.setPlaybackSpeed(selected.value);
            }
          },
        ),
      if (controlsConfig.hideQualitySelector != true && uniqueVideoTracks != null && uniqueVideoTracks.length > 1)
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
              await playerController.setSelectedTrack(
                TrackType.video,
                selected.value != null ? selected.value!.id : autoTrackId,
              );
              Future.delayed(const Duration(milliseconds: 100), () {
                if (!context.mounted) return;
                tracksFuture.value = playerController.getTracks();
              });
            }
          },
        ),
    ];

    return Material(
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
