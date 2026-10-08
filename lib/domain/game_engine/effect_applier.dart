import '../../data/models/game_card.dart';
import '../../data/models/game_mode.dart';
import '../../data/models/decision_record.dart';
import '../../data/models/stat.dart';
import 'game_state.dart';

enum SwipeDirection { left, right }

/// Aplica los efectos de la opción elegida y devuelve el nuevo GameState.
/// Pieza 100% pura (sin side effects, sin Flutter) para poder testear
/// el balance del juego sin levantar la UI.
class EffectApplier {
  final double lossMultiplier;
  final double gainMultiplier;
  const EffectApplier({this.lossMultiplier = 1.45, this.gainMultiplier = 1.15});
  GameState applyChoice({
    required GameState state,
    required GameCard card,
    required SwipeDirection direction,
  }) {
    final option = direction == SwipeDirection.left ? card.left : card.right;

    final outcomes = option.conditionalOutcomes
        .where((o) => o.matches(state.flags, state.characterTrust))
        .toList();
    final effects = {...option.effects};
    for (final outcome in outcomes) {
      for (final entry in outcome.effects.entries) {
        effects[entry.key] = (effects[entry.key] ?? 0) + entry.value;
      }
    }
    final notes = outcomes.map((e) => e.feedback).whereType<String>().toList();

    final newStats = {...state.stats};
    effects.forEach((type, delta) {
      // La dificultad aumenta: las pérdidas pesan más que las ganancias.
      final loss = (state.mode == GameMode.campaign ? 1.15 : lossMultiplier) *
          state.difficulty.loss;
      final gain = (state.mode == GameMode.campaign ? 1.0 : gainMultiplier) *
          state.difficulty.gain;
      final adjustedDelta =
          delta < 0 ? (delta * loss).round() : (delta * gain).round();
      newStats[type] = newStats[type]!.copyWithDelta(adjustedDelta);
    });

    final newSeen = {...state.seenCardIds, card.id};
    final flags = {...state.flags}..removeAll(option.clearFlags);
    final flagTurns = {...state.flagSetAtTurn}
      ..removeWhere((flag, _) => option.clearFlags.contains(flag));
    for (final flag in [
      ...option.setFlags,
      ...outcomes.expand((o) => o.setFlags)
    ]) {
      if (flags.add(flag)) flagTurns[flag] = state.turn + 1;
    }
    final favors = {...state.characterFavorCount};
    const represented = {
      'el_general': StatType.aparatoDelEstado,
      'la_lider_vecinal': StatType.pueblo,
      'la_economista': StatType.economia,
      'el_diplomatico': StatType.relacionesExteriores
    };
    final interest = represented[card.characterId];
    final interestChange = interest == null ? 0 : option.effects[interest] ?? 0;
    final favored = option.favorsCharacter ??
        (interestChange > 0 ? card.characterId : null);
    if (favored != null) favors[favored] = (favors[favored] ?? 0) + 1;
    final trust = {...state.characterTrust};
    final trustChanges = {...option.trustChanges};
    if (favored != null && !trustChanges.containsKey(favored)) {
      trustChanges[favored] = 1;
    }
    if (interestChange < 0 && !trustChanges.containsKey(card.characterId)) {
      trustChanges[card.characterId] = -1;
    }
    for (final entry in trustChanges.entries) {
      trust[entry.key] = ((trust[entry.key] ?? 0) + entry.value).clamp(-5, 5);
    }
    if (state.promise?.status(flags) != state.promiseStatus) {
      notes.add(state.promise?.status(flags) == PromiseStatus.fulfilled
          ? 'Has cumplido tu promesa de gobierno.'
          : 'Has roto tu promesa de gobierno.');
    }

    final pending = state.pendingConsequences
        .where((entry) => entry.cardId != card.id)
        .toList();
    for (final followUp in state.mode == GameMode.campaign
        ? const <ScheduledConsequence>[]
        : option.scheduleCards) {
      if (newSeen.contains(followUp.cardId) ||
          pending.any((entry) => entry.cardId == followUp.cardId)) {
        continue;
      }
      pending.add(PendingConsequence(
          cardId: followUp.cardId,
          title: followUp.title,
          dueTurn: state.turn + 1 + followUp.afterTurns));
    }

    final project = state.project;
    final projectProgress =
        state.projectProgress + (project?.advances(effects) == true ? 1 : 0);
    final completed = project != null && projectProgress >= 4;
    final expired = project != null &&
        !completed &&
        state.turn + 1 >= state.projectDeadline;
    if (completed) {
      notes.add(
          'Proyecto completado: ${project.label}. Los vecinos recuperan margen para organizarse.');
      // Acercar los indicadores al equilibrio evita que una recompensa provoque un colapso.
      for (final type in StatType.values) {
        final value = newStats[type]!.value;
        if (value > 0 && value < 100) {
          newStats[type] =
              newStats[type]!.copyWithDelta((50 - value).clamp(-3, 3));
        }
      }
    }
    if (expired) {
      notes.add(
          'El proyecto no llegó a tiempo. La próxima convocatoria permitirá intentarlo de nuevo.');
    }
    final record = DecisionRecord(
        turn: state.turn + 1,
        importance: (option.endsStory ? 100 : 0) +
            option.setFlags.length * 3 +
            outcomes.expand((o) => o.setFlags).length * 3 +
            trustChanges.values.fold<int>(0, (sum, v) => sum + v.abs()) +
            effects.values.fold<int>(0, (sum, v) => sum + v.abs()) +
            (notes.isNotEmpty ? 10 : 0),
        cardId: card.id,
        scene: card.resolvedText(state.flags, trust: state.characterTrust),
        choice: option.text,
        notes: List.unmodifiable(notes));
    final defining = [
      ...(state.definingDecisions.isEmpty
          ? state.history
          : state.definingDecisions),
      record
    ]..sort((a, b) {
        final score = b.importance.compareTo(a.importance);
        return score == 0 ? a.turn.compareTo(b.turn) : score;
      });
    return state.copyWith(
      definingDecisions: defining.take(3).toList(),
      projectProgress: projectProgress.clamp(0, 4),
      clearProject: completed || expired,
      nextProjectTurn: completed || expired ? state.turn + 7 : null,
      projectsCompleted: state.projectsCompleted + (completed ? 1 : 0),
      characterTrust: Map.unmodifiable(trust),
      history: [
        ...state.history
            .skip(state.history.length > 59 ? state.history.length - 59 : 0),
        record,
      ],
      stats: newStats,
      seenCardIds: newSeen,
      flags: flags,
      flagSetAtTurn: flagTurns,
      characterFavorCount: favors,
      pendingConsequences: List.unmodifiable(pending),
      lastNarrativeTurn: card.storyArc != null ? state.turn + 1 : null,
      turn: state.turn + 1,
      pendingNextCardId: option.nextCardId,
      clearPendingNextCardId: option.nextCardId == null,
    );
  }
}
