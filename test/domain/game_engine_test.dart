import 'package:flutter_test/flutter_test.dart';
import 'package:zafra/data/models/game_card.dart';
import 'package:zafra/data/models/stat.dart';
import 'package:zafra/domain/game_engine/effect_applier.dart';
import 'package:zafra/domain/game_engine/game_state.dart';

// Ejemplo de test del motor de juego, 100% sin dependencias de Flutter UI.
// Este es el tipo de test que debe crecer junto con el guion de cartas:
// cada regla de balance importante debería tener su propio caso aquí.
void main() {
  group('EffectApplier', () {
    test('aplica efectos y clampea entre 0 y 100', () {
      final initialState = GameState.initial(); // todas las stats en 50
      final card = GameCard(
        id: 'test_card',
        characterId: 'el_general',
        eraId: 'fundacional',
        text: 'Carta de prueba',
        left: const CardOption(
          text: 'Izquierda',
          effects: {StatType.pueblo: -70},
        ),
        right: const CardOption(
          text: 'Derecha',
          effects: {StatType.pueblo: 10},
        ),
      );

      final applier = EffectApplier();
      final result = applier.applyChoice(
        state: initialState,
        card: card,
        direction: SwipeDirection.left,
      );

      // 50 - 70 = -20, pero debe quedar clampeado en 0.
      expect(result.statOf(StatType.pueblo).value, 0);
      expect(result.statOf(StatType.pueblo).isCollapsed, isTrue);
      expect(result.turn, 1);
      expect(result.seenCardIds.contains('test_card'), isTrue);
    });

    test('respeta la ramificación (nextCardId) de una opción', () {
      final initialState = GameState.initial();
      final card = GameCard(
        id: 'card_with_branch',
        characterId: 'el_general',
        eraId: 'fundacional',
        text: 'Carta con ramificación',
        left: const CardOption(text: 'Izquierda', effects: {}),
        right: const CardOption(
          text: 'Derecha',
          effects: {},
          nextCardId: 'card_child',
        ),
      );

      final applier = EffectApplier();
      final result = applier.applyChoice(
        state: initialState,
        card: card,
        direction: SwipeDirection.right,
      );

      expect(result.pendingNextCardId, 'card_child');
    });
  });
}
