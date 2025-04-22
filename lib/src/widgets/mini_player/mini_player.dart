import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/controls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/svg_icons.dart';
import '../../utils/transparent_image.dart';
import 'loading_indicator.dart';

const double kMiniPlayerHeight = 62;

class MiniPlayer extends HookWidget {
  final String? secondaryTitle;
  final String title;
  final String? artworkUri;
  final ImageProvider? artwork;
  final bool isPlaying;
  final bool? loading;
  final VoidCallback? onPauseTap;
  final VoidCallback? onPlayTap;
  final VoidCallback? onCloseTap;
  final bool? hideCloseButton;
  final bool showBorder;
  final BccmPlayerController? playerController;

  final Key? titleKey;
  final Widget? loadingIndicator;
  final String? playSemanticLabel;
  final String? pauseSemanticLabel;

  const MiniPlayer({
    super.key,
    required this.secondaryTitle,
    required this.title,
    required this.isPlaying,
    this.artworkUri,
    this.artwork,
    this.onPauseTap,
    this.onPlayTap,
    this.onCloseTap,
    this.loading,
    this.hideCloseButton,
    this.showBorder = true,
    this.titleKey,
    this.loadingIndicator,
    this.playSemanticLabel,
    this.pauseSemanticLabel,
    this.playerController,
  }) : assert(artworkUri != null || artwork != null, "Artwork must be set");

  @override
  Widget build(BuildContext context) {
    final theme = BccmPlayerTheme.safeOf(context).miniPlayer!;
    final controller = playerController ?? BccmPlayerInterface.instance.primaryController;

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        Container(
          height: kMiniPlayerHeight,
          width: MediaQuery.sizeOf(context).width,
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            border: showBorder ? Border(top: BorderSide(color: theme.topBorderColor ?? Colors.transparent, width: 1)) : null,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                width: 64,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: theme.thumbnailBorderColor ?? Colors.transparent, width: 1),
                ),
                child: artworkUri == null
                    ? null
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: FadeInImage(
                          fadeInDuration: const Duration(milliseconds: 200),
                          placeholder: MemoryImage(kTransparentImage),
                          fit: BoxFit.cover,
                          image: artwork ?? ResizeImage.resizeIfNeeded(null, 64, NetworkImage(artworkUri!)),
                          width: 64,
                          height: 36,
                        )),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (secondaryTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          secondaryTitle!,
                          semanticsLabel: secondaryTitle!,
                          overflow: TextOverflow.ellipsis,
                          style: theme.secondaryTitleStyle,
                        ),
                      ),
                    Text(
                      title,
                      semanticsLabel: title,
                      key: titleKey,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleStyle,
                    ),
                  ],
                ),
              ),
              if (loading == true)
                Container(
                  margin: const EdgeInsets.only(left: 16),
                  height: 36,
                  width: 36,
                  child: loadingIndicator ?? const LoadingIndicator(height: 24),
                )
              else
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => isPlaying ? onPauseTap?.call() : onPlayTap?.call(),
                  child: Container(
                    margin: const EdgeInsets.only(left: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    height: 36,
                    width: 36,
                    child: isPlaying
                        ? SvgPicture.string(
                            SvgIcons.pause,
                            semanticsLabel: pauseSemanticLabel,
                            colorFilter: ColorFilter.mode(theme.iconColor ?? Colors.transparent, BlendMode.srcIn),
                          )
                        : SvgPicture.string(
                            SvgIcons.play,
                            semanticsLabel: playSemanticLabel,
                            colorFilter: ColorFilter.mode(theme.iconColor ?? Colors.transparent, BlendMode.srcIn),
                          ),
                  ),
                ),
              if (hideCloseButton != true)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onCloseTap?.call(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    height: 36,
                    width: 48,
                    child: SvgPicture.string(
                      SvgIcons.close,
                      colorFilter: ColorFilter.mode(theme.iconColor ?? Colors.transparent, BlendMode.srcIn),
                    ),
                  ),
                ),
            ],
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutExpo,
          opacity: controller.value.playbackPositionMs != null ? 1 : 0,
          child: SizedBox(
            width: double.infinity,
            height: 2,
            child: LayoutBuilder(builder: (context, constraints) {
              return Align(
                alignment: Alignment.bottomLeft,
                child: SmoothVideoProgress(
                  controller: controller,
                  builder: (context, position, duration, child) {
                    if (duration.inMilliseconds == 0) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      decoration: BoxDecoration(color: theme.progressColor),
                      width: constraints.maxWidth * clampDouble(position.inMilliseconds / duration.inMilliseconds, 0, 1),
                    );
                  },
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
