import '../../data/models/ending.dart';
import 'game_state.dart';

/// Dado el estado final de la partida, elige qué [Ending] narrativo
/// mostrar. Prioriza un final específico de la era actual; si no existe,
/// cae en un final genérico para esa estadística.
class EndingResolver {
  Ending? resolve({
    required GameState state,
    required List<Ending> availableEndings,
  }) {
    final collapsedType = state.collapsedStat;
    if (collapsedType == null) return null;

    final stat = state.statOf(collapsedType);

    final specific = availableEndings.where((e) =>
        e.causedBy == collapsedType &&
        e.wasAtMin == stat.isAtMin &&
        e.eraId == state.currentEra.name);
    if (specific.isNotEmpty) return specific.first;

    final generic = availableEndings.where(
      (e) =>
          e.causedBy == collapsedType &&
          e.wasAtMin == stat.isAtMin &&
          e.eraId == 'generic',
    );
    if (generic.isNotEmpty) return generic.first;

    return null;
  }

  Ending? resolveSurvival({required GameState state, required List<Ending> availableEndings}) {
    if (state.hasCollapsed) return null;
    for (final ending in availableEndings) {
      if (ending.isSurvival) return ending;
    }
    return null;
  }
}
