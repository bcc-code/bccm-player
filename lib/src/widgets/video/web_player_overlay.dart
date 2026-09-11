import 'package:flutter/widgets.dart';

/// Hosts the web player's platform view in the root [Overlay], once per player,
/// and points it at whichever [VideoPlatformView] should currently show it.
///
/// On web a platform view is a real DOM element, and a player owns exactly one
/// of them. Mounting the [HtmlElementView] inline means the element is
/// re-parented every time the view that hosts it changes — pushing the
/// fullscreen route, switching tabs, or simply scrolling a list far enough for
/// Flutter to rebuild the subtree. Re-parenting costs the media element its
/// source, so the player reloads, and during a scroll it reloads continuously.
///
/// Here the [HtmlElementView] is mounted once and never moves in the widget
/// tree. Views register a [LayerLink] and their size; the overlay follows
/// whichever registered last. Switching between views changes only the link, so
/// the element stays exactly where it is in the DOM.
///
/// The entry goes in the **root** overlay so that pushing a route — the
/// fullscreen route in particular — does not tear it down.
///
/// The player draws its own controls on web, so nothing Flutter-drawn needs to
/// sit above the video — which is what makes hosting it up here workable.
///
/// Known limit, inherent to painting outside the normal tree: the video is not
/// clipped by ancestor scroll views, so a player scrolled past its viewport
/// paints over whatever is beside it. Route content pushed afterwards (dialogs,
/// sheets) still covers it, being a later entry in the same overlay.
class WebPlayerOverlay {
  WebPlayerOverlay._(this.playerId);

  static final Map<String, WebPlayerOverlay> _byPlayerId = {};

  final String playerId;

  /// The view the platform view currently follows. Null means no view wants it,
  /// in which case it stays mounted but unlinked, and therefore not painted.
  final ValueNotifier<_FollowTarget?> _target = ValueNotifier(null);

  /// Never linked to anything, so [CompositedTransformFollower] hides the child
  /// while still keeping it mounted.
  final LayerLink _idleLink = LayerLink();

  OverlayEntry? _entry;

  static WebPlayerOverlay _of(String playerId) =>
      _byPlayerId.putIfAbsent(playerId, () => WebPlayerOverlay._(playerId));

  /// Points this player's platform view at [link], creating the overlay entry
  /// on first use.
  static void show(
    BuildContext context, {
    required String playerId,
    required LayerLink link,
    required Size size,
    required bool showControls,
    required Widget Function(Map<Object?, Object?> creationParams) viewBuilder,
  }) {
    final overlay = _of(playerId);
    overlay._target.value = _FollowTarget(link, size, showControls);
    if (overlay._entry != null) return;

    final entry = OverlayEntry(
      builder: (context) => ValueListenableBuilder<_FollowTarget?>(
        valueListenable: overlay._target,
        builder: (context, target, child) {
          // Deliberately one widget shape in both states: swapping the subtree
          // would remount the platform view, which is the whole thing this
          // class exists to avoid.
          return Positioned(
            width: target?.size.width ?? 1,
            height: target?.size.height ?? 1,
            child: CompositedTransformFollower(
              link: target?.link ?? overlay._idleLink,
              showWhenUnlinked: false,
              child: child!,
            ),
          );
        },
        child: viewBuilder({
          'playerId': playerId,
          'showControls': showControls,
        }),
      ),
    );
    overlay._entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  /// Stops following [link], if it is still the one being followed.
  ///
  /// Deferred by a frame: a view being replaced disposes before its replacement
  /// registers, and unlinking in between would make the player blink.
  static void hide(String playerId, LayerLink link) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Looked up inside the callback, not captured outside it: the player can
      // be disposed in between, and disposeFor drops it from the map before
      // disposing the notifier.
      final overlay = _byPlayerId[playerId];
      if (overlay == null) return;
      if (overlay._target.value?.link == link) {
        overlay._target.value = null;
      }
    });
  }

  /// Tears the entry down for good. Called when the player itself is disposed —
  /// not when a view goes away, since the point is to outlive views.
  static void disposeFor(String playerId) {
    final overlay = _byPlayerId.remove(playerId);
    overlay?._entry?.remove();
    overlay?._entry = null;
    overlay?._target.dispose();
  }
}

class _FollowTarget {
  const _FollowTarget(this.link, this.size, this.showControls);

  final LayerLink link;
  final Size size;
  final bool showControls;
}
