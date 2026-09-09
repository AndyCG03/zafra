import '../../data/models/game_card.dart';
import 'game_state.dart';

enum SwipeDirection { left, right }

/// Aplica los efectos de la opción elegida y devuelve el nuevo GameState.
/// Pieza 100% pura (sin side effects, sin Flutter) para poder testear
/// el balance del juego sin levantar la UI.
class EffectApplier {
  GameState applyChoice({
    required GameState state,
    required GameCard card,
    required SwipeDirection direction,
  }) {
    final option = direction == SwipeDirection.left ? card.left : card.right;

    final newStats = {...state.stats};
    option.effects.forEach((type, delta) {
      // La dificultad aumenta: las pérdidas pesan más que las ganancias.
      final adjustedDelta = delta < 0
          ? (delta * 1.50).round()
          : (delta * 1.15).round();
      newStats[type] = newStats[type]!.copyWithDelta(adjustedDelta);
    });

    final newSeen = {...state.seenCardIds, card.id};

    return state.copyWith(
      stats: newStats,
      seenCardIds: newSeen,
      turn: state.turn + 1,
      pendingNextCardId: option.nextCardId,
      clearPendingNextCardId: option.nextCardId == null,
    );
  }
}
