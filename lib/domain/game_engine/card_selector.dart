import 'dart:math';

import '../../data/models/game_card.dart';
import '../../data/models/era.dart';
import 'game_state.dart';

/// Elige la próxima carta a mostrar, respetando:
/// 1. Ramificación forzada (pendingNextCardId) si existe.
/// 2. Condiciones de la carta (estadísticas mínimas/máximas, flags).
/// 3. Que no se repita una carta ya vista en la partida actual.
/// 4. Peso relativo (weight) para variar probabilidades.
class CardSelector {
  final Random _random;

  CardSelector({Random? random}) : _random = random ?? Random();

  GameCard? selectNext({
    required GameState state,
    required List<GameCard> availableCards,
    required GameCard? Function(String id) findById,
  }) {
    // 1. Ramificación forzada por la carta anterior.
    if (state.pendingNextCardId != null) {
      final forced = findById(state.pendingNextCardId!);
      // Las ramificaciones mantienen prioridad, pero tampoco pueden saltarse
      // la progresión temporal si pertenecen a una era futura bloqueada.
      if (forced != null && _isEraAvailable(forced, state)) return forced;
    }

    // 2 y 3. Filtrar por condiciones y por no-repetición.
    final eligible = availableCards.where((card) {
      if (state.seenCardIds.contains(card.id)) return false;
      return _matchesConditions(card, state);
    }).toList();

    if (eligible.isEmpty) return null;

    // 4. Selección ponderada.
    // Una carta marcada como rara conserva un peso explícito bajo (1 por
    // convención). Así puede salvar una estadística en peligro sin dominar
    // el mazo normal.
    final totalWeight = eligible.fold<int>(0, (sum, c) => sum + c.weight);
    var roll = _random.nextInt(totalWeight);
    for (final card in eligible) {
      if (roll < card.weight) return card;
      roll -= card.weight;
    }
    return eligible.last; // fallback defensivo
  }

  bool _matchesConditions(GameCard card, GameState state) {
    if (!_isEraAvailable(card, state)) return false;
    final condition = card.condition;

    for (final entry in condition.minValues.entries) {
      if (state.statOf(entry.key).value < entry.value) return false;
    }
    for (final entry in condition.maxValues.entries) {
      if (state.statOf(entry.key).value > entry.value) return false;
    }
    for (final flag in condition.requiresFlags) {
      if (!state.flags.contains(flag)) return false;
    }
    for (final flag in condition.excludesFlags) {
      if (state.flags.contains(flag)) return false;
    }
    return true;
  }

  bool _isEraAvailable(GameCard card, GameState state) {
    final cardEraIndex = Era.values.indexWhere((era) => era.name == card.eraId);
    if (cardEraIndex < 0) return false;
    if (cardEraIndex <= state.currentEra.index) return true;
    return state.unlockedCharacterIds.contains(card.characterId);
  }
}
