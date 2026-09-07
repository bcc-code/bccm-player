import 'package:bccm_player/bccm_player.dart';
import 'package:bccm_player/plugins/riverpod.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

import '../utils/fake_platform.dart';

/// Every [PlayerStateNotifier] starts a periodic 1s timer in its constructor, so
/// counting live periodic timers is a direct measure of how many notifiers exist
/// and have not been disposed.
void main() {
  group('playerProviderFor', () {
    test('resolves an existing player', () {
      fakeAsync((async) {
        final fake = FakeBccmPlayerInterface.install();
        final container = ProviderContainer();
        final player = fake.stateNotifier.getOrAddPlayerNotifier('p1');
        player.setPlaybackState(PlaybackState.playing);

        expect(container.read(playerProviderFor('p1').notifier), same(player));
        expect(container.read(playerProviderFor('p1'))?.playbackState, PlaybackState.playing);

        container.dispose();
        fake.restore();
      });
    });

    test('leaves nothing running once the container and players are disposed', () {
      // Regression: the placeholder `PlayerStateNotifier(keepAlive: false)` was
      // built *inside* the `select` callback. A selector runs more than once per
      // rebuild — once to detect the change, again while recomputing — so each
      // recompute allocated two placeholders while riverpod owned and disposed
      // only one. The surplus kept a 1s periodic timer alive forever.
      fakeAsync((async) {
        final fake = FakeBccmPlayerInterface.install();
        final container = ProviderContainer();
        container.listen(playerProviderFor('missing'), (_, __) {}, fireImmediately: true);

        // Force at least one recompute of the provider.
        fake.stateNotifier.getOrAddPlayerNotifier('other');
        container.read(playerProviderFor('missing').notifier);

        container.dispose();
        fake.restore();

        expect(async.periodicTimerCount, 0, reason: 'a leaked notifier keeps its timer alive');
      });
    });

    test('re-resolves once the player appears', () {
      fakeAsync((async) {
        final fake = FakeBccmPlayerInterface.install();
        final container = ProviderContainer();
        container.listen(playerProviderFor('p1'), (_, __) {}, fireImmediately: true);

        final placeholder = container.read(playerProviderFor('p1').notifier);
        final real = fake.stateNotifier.getOrAddPlayerNotifier('p1');

        expect(container.read(playerProviderFor('p1').notifier), same(real));
        expect(container.read(playerProviderFor('p1').notifier), isNot(same(placeholder)));

        container.dispose();
        fake.restore();
      });
    });

    test('disposes the placeholder it handed out', () {
      fakeAsync((async) {
        final fake = FakeBccmPlayerInterface.install();
        final container = ProviderContainer();
        container.listen(playerProviderFor('missing'), (_, __) {}, fireImmediately: true);
        final placeholder = container.read(playerProviderFor('missing').notifier);

        container.dispose();

        expect(placeholder.mounted, isFalse, reason: 'riverpod owns and disposes the placeholder');
        fake.restore();
      });
    });
  });

  group('primaryPlayerProvider', () {
    test('follows the primary player', () {
      fakeAsync((async) {
        final fake = FakeBccmPlayerInterface.install();
        final container = ProviderContainer();
        final local = fake.stateNotifier.getOrAddPlayerNotifier('local');
        final cast = fake.stateNotifier.getOrAddPlayerNotifier('chromecast');
        container.listen(primaryPlayerProvider, (_, __) {}, fireImmediately: true);

        fake.stateNotifier.setPrimaryPlayer('local');
        expect(container.read(primaryPlayerProvider.notifier), same(local));

        fake.stateNotifier.setPrimaryPlayer('chromecast');
        expect(container.read(primaryPlayerProvider.notifier), same(cast));

        container.dispose();
        fake.restore();
      });
    });

    test('leaves nothing running once the container and players are disposed', () {
      // This provider already built its placeholder in the body rather than in
      // the selector, so it was never affected — pinned so it stays that way.
      fakeAsync((async) {
        final fake = FakeBccmPlayerInterface.install();
        final container = ProviderContainer();
        container.listen(primaryPlayerProvider, (_, __) {}, fireImmediately: true);

        fake.stateNotifier.getOrAddPlayerNotifier('other');
        container.read(primaryPlayerProvider.notifier);

        container.dispose();
        fake.restore();

        expect(async.periodicTimerCount, 0);
      });
    });
  });
}
