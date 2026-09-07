import 'package:riverpod/riverpod.dart';
import '../../../../bccm_player.dart';
import 'plugin_state_provider.dart';

final playerProviderFor = StateNotifierProvider.family<PlayerStateNotifier, PlayerState?, String>((ref, playerId) {
  // The placeholder is built here rather than inside the `select` callback.
  // A selector runs more than once per rebuild — once to detect the change and
  // again while recomputing — so allocating in there produced notifiers riverpod
  // never owned, each with a live 1s timer that nothing ever cancelled.
  //
  // Returning it from the body instead makes it the provider's value, which
  // riverpod disposes on recompute and on container teardown. Selecting the
  // nullable notifier is also stabler: it compares by identity instead of being
  // a fresh instance every time.
  final notifier = ref.watch(pluginStateProvider.select((value) => value.players[playerId]));
  return notifier ?? PlayerStateNotifier(keepAlive: false);
});

final primaryPlayerProvider = StateNotifierProvider<PlayerStateNotifier, PlayerState?>((ref) {
  final playerNotifier = ref.watch(
    pluginStateProvider.select((value) => value.players[value.primaryPlayerId]),
  );
  if (playerNotifier == null) return PlayerStateNotifier(keepAlive: false);
  return playerNotifier;
});
