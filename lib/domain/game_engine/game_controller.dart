import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../../data/models/ending.dart';
import '../../data/models/character.dart';
import '../../data/models/game_card.dart';
import '../../data/models/era.dart';
import '../../data/models/stat.dart';
import '../../data/repositories/card_repository.dart';
import 'card_selector.dart';
import 'effect_applier.dart';
import 'ending_resolver.dart';
import 'game_state.dart';
import 'game_statistics.dart';
import '../../data/repositories/event_repository.dart';
import '../../services/persistence/progress_service.dart';

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository();
});

final gameControllerProvider =
StateNotifierProvider<GameController, GameControllerState>((ref) {
  return GameController(ref.watch(cardRepositoryProvider));
});

class GameControllerState {
  final GameState gameState;
  final GameCard? currentCard;
  final Ending? ending;
  final bool isLoading;
  final Character? unlockedCharacter;
  final GameStatistics statistics;
  final StatType? rescueOpportunity;

  const GameControllerState({
    required this.gameState,
    required this.currentCard,
    required this.ending,
    required this.isLoading,
    this.unlockedCharacter,
    this.statistics = const GameStatistics(),
    this.rescueOpportunity,
  });

  factory GameControllerState.loading() => GameControllerState(
    gameState: GameState.initial(),
    currentCard: null,
    ending: null,
    isLoading: true,
  );

  GameControllerState copyWith({
    GameState? gameState,
    GameCard? currentCard,
    Ending? ending,
    bool? isLoading,
    Character? unlockedCharacter,
    bool clearUnlockedCharacter = false,
    GameStatistics? statistics,
    StatType? rescueOpportunity,
  }) {
    return GameControllerState(
      gameState: gameState ?? this.gameState,
      currentCard: currentCard ?? this.currentCard,
      ending: ending ?? this.ending,
      isLoading: isLoading ?? this.isLoading,
      unlockedCharacter: clearUnlockedCharacter
          ? null
          : (unlockedCharacter ?? this.unlockedCharacter),
      statistics: statistics ?? this.statistics,
      rescueOpportunity: rescueOpportunity,
    );
  }
}

/// CAMBIO CLAVE de esta versión: ya no hay progresión de eras ni
/// filtrado por era. `_pickNextCard` elige siempre de
/// `_repository.allCards` (el mazo completo). Cuando ya se vieron
/// todas, se recicla automáticamente (se olvidan las vistas) para que
/// el mazo nunca se acabe, sin importar cuántas cartas tengas escritas.
class GameController extends StateNotifier<GameControllerState> {
  static const _assassinationCardIds = {
    'era1_guardaeaspalda_trampa',
    'era2_guardaeaspalda_trampa',
    'era3_guardaeaspalda_trampa',
    'era4_guardaeaspalda_trampa',
  };
  final CardRepository _repository;
  final CardSelector _selector = CardSelector();
  final EffectApplier _applier = EffectApplier();
  final EndingResolver _endingResolver = EndingResolver();
  final Random _random = Random();
  final ProgressService _progress = ProgressService();

  CardOption cardOptionFor(GameCard card, SwipeDirection direction) => direction == SwipeDirection.left ? card.left : card.right;
  StatType? _statType(String value) {
    for (final type in StatType.values) { if (type.name == value) return type; }
    return null;
  }

  GameCard? _findCard(String id) {
    final normal = _repository.cardById(id);
    if (normal != null) return normal;
    for (final event in EventRepository.definitions) {
      for (final card in event.cards) { if (card.id == id) return card; }
    }
    return null;
  }

  EventDefinition? _eventAfterDecision(CardOption option, GameState gameState) {
    if (gameState.turn < 5) return null;
    if (option.startsEvent != null) return EventRepository.byId(option.startsEvent!);

    final pueblo = option.effects[StatType.pueblo] ?? 0;
    final economia = option.effects[StatType.economia] ?? 0;
    final exterior = option.effects[StatType.relacionesExteriores] ?? 0;
    final estado = option.effects[StatType.aparatoDelEstado] ?? 0;

    var negativeCount = 0;
    if (pueblo < 0) negativeCount++;
    if (economia < 0) negativeCount++;
    if (exterior < 0) negativeCount++;
    if (estado < 0) negativeCount++;

    final chance = .05 + (negativeCount * .10);
    if (_random.nextDouble() >= chance) return null;

    final candidates = <String>[];
    if (pueblo < 0) candidates.addAll(['rebelion', 'refugiados']);
    if (economia < 0) candidates.addAll(['corrupcion', 'accidente']);
    if (exterior < 0) candidates.addAll(['refugiados', 'terrorismo']);
    if (estado < 0) candidates.addAll(['rebelion', 'terrorismo']);
    if (_random.nextDouble() < .08) candidates.add('huracan');
    candidates.removeWhere((id) => gameState.flags.contains('event_${id}_seen'));
    if (candidates.isEmpty) return null;
    return EventRepository.byId(candidates[_random.nextInt(candidates.length)]);
  }

  GameController(this._repository) : super(GameControllerState.loading()) {
    _start();
  }

  Future<void> _start() async {
    await _progress.init();
    await EventRepository.loadEvents();
    await _repository.loadAll();
    await _progress.markEraReached(GameState.initial().currentEra.index);
    final initialState = GameState.initial();
    final saved = _progress.savedGame;
    if (saved != null) {
      final restored = _restoreState(saved);
      await _progress.markEraReached(restored.currentEra.index);
      final restoredCard = (saved['card'] as String?) != null ? _findCard(saved['card'] as String) : _pickNextCard(restored);
      final rescueIndex = (saved['rescueOpportunity'] as num?)?.toInt();
      state = GameControllerState(
        gameState: restored,
        currentCard: restoredCard,
        ending: null,
        isLoading: false,
        rescueOpportunity: rescueIndex == null || rescueIndex < 0 || rescueIndex >= StatType.values.length
            ? null
            : StatType.values[rescueIndex],
        statistics: GameStatistics.fromJson(saved['statistics'] as Map?),
      );
      return;
    }
    await _progress.registerGameStarted();
    final nextCard = _pickOpeningCard(initialState);
    final character = nextCard == null
        ? null
        : _repository.characterById(nextCard.characterId);
    final notifyCharacter = character != null && !_progress.unlockedCharacters.contains(character.id);
    if (character != null) await _progress.markCharacterUnlocked(character.id);
    final stateWithCharacter = character == null
        ? initialState
        : initialState.copyWith(unlockedCharacterIds: {character.id});
    state = GameControllerState(
      gameState: stateWithCharacter,
      currentCard: nextCard,
      ending: null,
      isLoading: false,
      unlockedCharacter: notifyCharacter ? character : null,
    );
  }

  Future<void> choose(SwipeDirection direction) async {
    final card = state.currentCard;
    if (card == null || state.ending != null) return;
    _progress.addDiscoveredCard(card.id);
    if (card.characterId == 'el_creador') {
      await _progress.markCreatorMessageSeen(card.id);
    }

    final newState = _applier.applyChoice(
      state: state.gameState,
      card: card,
      direction: direction,
    );
    final granted = cardOptionFor(card, direction).grantsRescue;
    final available = {...newState.availableRescuePowers};
    if (granted != null) {
      final type = _statType(granted);
      if (type != null) available.add(type);
    }
    final stateWithRescue = newState.copyWith(availableRescuePowers: available);
    var stateWithRisk = stateWithRescue;
    final isTrapChoice = _assassinationCardIds.contains(card.id) && direction == SwipeDirection.left;
    if (isTrapChoice) {
      final compromises = state.gameState.securityCompromises + 1;
      stateWithRisk = stateWithRisk.copyWith(
        securityCompromises: compromises,
        assassinationCountdown: compromises >= 2 && state.gameState.assassinationCountdown == null
            ? 4
            : null,
      );
    }
    var assassinationTriggered = false;
    if (state.gameState.assassinationCountdown != null) {
      final remaining = state.gameState.assassinationCountdown! - 1;
      assassinationTriggered = remaining <= 0;
      stateWithRisk = stateWithRisk.copyWith(
        assassinationCountdown: remaining,
        clearAssassinationCountdown: assassinationTriggered,
      );
    }
    final updatedStatistics = state.statistics.record(
      turn: state.statistics.totalTurns + 1,
      era: state.gameState.currentEra,
      direction: direction,
      before: state.gameState.stats,
      after: newState.stats,
    );

    if (assassinationTriggered) {
      final ending = _repository.endings.firstWhere((e) => e.id == 'ending_aparato_min_asesinato');
      state = state.copyWith(gameState: stateWithRisk, ending: ending, statistics: updatedStatistics);
      await _progress.markEndingSeen(ending.id);
      await _progress.registerMandate(
        turns: updatedStatistics.totalTurns,
        left: updatedStatistics.leftSwipes,
        right: updatedStatistics.rightSwipes,
        eraIndex: stateWithRisk.currentEra.index,
        days: stateWithRisk.daysInPower,
        endingId: ending.id,
        endingTitle: ending.title,
        finalStats: {for (final entry in stateWithRisk.stats.entries) entry.key: entry.value.value},
      );
      _saveCurrentGame();
      return;
    }

    if (stateWithRisk.hasCollapsed) {
      final collapsed = stateWithRisk.collapsedStat;
      if (collapsed != null && available.contains(collapsed)) {
        state = state.copyWith(gameState: stateWithRisk, statistics: updatedStatistics, rescueOpportunity: collapsed);
        _saveCurrentGame();
        return;
      }
      final ending = _endingResolver.resolve(
        state: stateWithRisk,
        availableEndings: _repository.endings,
      );
      if (ending != null) {
        _progress.markEndingSeen(ending.id);
        _progress.registerMandate(
          turns: updatedStatistics.totalTurns,
          left: updatedStatistics.leftSwipes,
          right: updatedStatistics.rightSwipes,
          eraIndex: stateWithRescue.currentEra.index,
          days: stateWithRescue.daysInPower,
          endingId: ending.id,
          endingTitle: ending.title,
          finalStats: {
            for (final entry in stateWithRescue.stats.entries) entry.key: entry.value.value,
          },
        );
      }
      state = state.copyWith(
        gameState: stateWithRisk,
        ending: ending,
        statistics: updatedStatistics,
      );
      _saveCurrentGame();
      return;
    }

    var progressedState = stateWithRisk.copyWith(
      currentEra: _eraForTurn(newState.turn),
      daysInPower: state.gameState.daysInPower + 1 + _random.nextInt(6),
    );
    await _progress.markEraReached(progressedState.currentEra.index);
    if (progressedState.turn >= Era.contemporanea.unlockAtTurn) {
      final survival = _endingResolver.resolveSurvival(
        state: progressedState,
        availableEndings: _repository.endings,
      );
      if (survival != null) {
        await _progress.markEndingSeen(survival.id);
        await _progress.registerMandate(
          turns: updatedStatistics.totalTurns,
          left: updatedStatistics.leftSwipes,
          right: updatedStatistics.rightSwipes,
          eraIndex: progressedState.currentEra.index,
          days: progressedState.daysInPower,
          endingId: survival.id,
          endingTitle: survival.title,
          finalStats: {
            for (final entry in progressedState.stats.entries) entry.key: entry.value.value,
          },
        );
        state = state.copyWith(
          gameState: progressedState,
          currentCard: null,
          ending: survival,
          statistics: updatedStatistics,
        );
        _saveCurrentGame();
        return;
      }
    }
    GameCard? selectedCard;
    var recycled = false;
    if (state.gameState.activeEventId != null) {
      final nextIndex = state.gameState.eventCardsPlayed + 1;
      if (nextIndex >= state.gameState.activeEventCardIds.length) {
        progressedState = progressedState.copyWith(clearActiveEvent: true);
        final result = _pickNextCardResult(gameState: progressedState);
        selectedCard = result.card;
        recycled = result.recycled;
      } else {
        progressedState = progressedState.copyWith(eventCardsPlayed: nextIndex);
        selectedCard = _findCard(state.gameState.activeEventCardIds[nextIndex]);
      }
    } else {
      if (card.characterId == 'el_creador' && _progress.gamesPlayed == 1) {
        for (final creator in _repository.creatorCards) {
          if (!_progress.seenCreatorMessageIds.contains(creator.id) && creator.id != card.id) {
            selectedCard = creator;
            break;
          }
        }
      }
      final event = selectedCard == null
          ? _eventAfterDecision(cardOptionFor(card, direction), progressedState)
          : null;
      if (event != null) {
        final cards = [...event.cards]..shuffle(_random);
        final selected = cards.take(5 + _random.nextInt(4)).map((c) => c.id).toList();
        progressedState = progressedState.copyWith(activeEventId: event.id, eventCardsPlayed: 0, activeEventCardIds: selected, flags: {...progressedState.flags, 'event_${event.id}_seen'});
        _progress.markEventDiscovered(event.id);
        selectedCard = _findCard(selected.first);
      } else {
        final result = _pickNextCardResult(gameState: progressedState);
        selectedCard = result.card;
        recycled = result.recycled;
      }
    }
    final result = _PickResult(selectedCard, recycled);
    final finalState = result.recycled
        ? progressedState.copyWith(seenCardIds: const {})
        : progressedState;

    final nextCharacter = result.card == null
        ? null
        : _repository.characterById(result.card!.characterId);
    final isNewCharacter = nextCharacter != null &&
        !finalState.unlockedCharacterIds.contains(nextCharacter.id);
    final firstTimeCharacter = nextCharacter != null &&
        !_progress.unlockedCharacters.contains(nextCharacter.id);
    if (firstTimeCharacter) _progress.markCharacterUnlocked(nextCharacter.id);
    final stateWithCharacter = isNewCharacter
        ? finalState.copyWith(unlockedCharacterIds: {
      ...finalState.unlockedCharacterIds,
      nextCharacter.id,
    })
        : finalState;
    state = state.copyWith(
      gameState: stateWithCharacter,
      currentCard: result.card,
      unlockedCharacter: firstTimeCharacter ? nextCharacter : null,
      clearUnlockedCharacter: !firstTimeCharacter,
      statistics: updatedStatistics,
    );
    _saveCurrentGame();
  }

  GameCard? _pickNextCard(GameState gameState) {
    return _pickNextCardResult(gameState: gameState).card;
  }

  GameCard? _pickOpeningCard(GameState gameState) {
    final games = _progress.gamesPlayed;
    if (games != 1 && games % 5 != 0) return _pickNextCard(gameState);
    for (final card in _repository.creatorCards) {
      if (!_progress.seenCreatorMessageIds.contains(card.id)) return card;
    }
    return _pickNextCard(gameState);
  }

  _PickResult _pickNextCardResult({required GameState gameState}) {
    // El mazo completo evita quedarse sin cartas cuando una era agotó sus
    // cartas elegibles por condiciones o por historial.
    final eraCards = _repository.allCards;
    if (eraCards.isEmpty) return const _PickResult(null, false);

    // 1er intento: cartas nuevas (no vistas) que cumplan condiciones.
    final card = _selector.selectNext(
      state: gameState,
      availableCards: eraCards,
      findById: _repository.cardById,
    );
    if (card != null) return _PickResult(card, false);

    // 2do intento (reciclaje): ya se vio todo el mazo -> se olvida el
    // historial de "vistas" y se vuelve a barajar desde cero, para que
    // el juego jamás se quede sin cartas.
    final recycledState = gameState.copyWith(seenCardIds: const {});
    final recycledCard = _selector.selectNext(
      state: recycledState,
      availableCards: eraCards,
      findById: _repository.cardById,
    );
    return _PickResult(recycledCard, recycledCard != null);
  }

  Future<void> restart() async {
    state = GameControllerState.loading();
    await _progress.clearGame();
    await _startWithStatistics(const GameStatistics());
  }

  Future<void> _startWithStatistics(GameStatistics statistics) async {
    await EventRepository.loadEvents();
    await _repository.loadAll();
    await _progress.registerGameStarted();
    await _progress.markEraReached(GameState.initial().currentEra.index);
    final initialState = GameState.initial();
    final nextCard = _pickOpeningCard(initialState);
    final character = nextCard == null
        ? null
        : _repository.characterById(nextCard.characterId);
    final notifyCharacter = character != null && !_progress.unlockedCharacters.contains(character.id);
    if (character != null) await _progress.markCharacterUnlocked(character.id);
    final stateWithCharacter = character == null
        ? initialState
        : initialState.copyWith(unlockedCharacterIds: {character.id});
    state = GameControllerState(
      gameState: stateWithCharacter,
      currentCard: nextCard,
      ending: null,
      isLoading: false,
      unlockedCharacter: notifyCharacter ? character : null,
      statistics: statistics,
    );
  }

  void acknowledgeCharacterUnlock() {
    state = state.copyWith(clearUnlockedCharacter: true);
  }

  bool canUseRescuePower(StatType type) {
    return state.gameState.availableRescuePowers.contains(type) &&
        !state.gameState.usedRescuePowers.contains(type) &&
        state.ending == null;
  }

  void useRescuePower(StatType type) {
    if (!state.gameState.availableRescuePowers.contains(type)) return;
    final stats = {...state.gameState.stats};
    stats[type] = stats[type]!.copyWithDelta(22);
    state = state.copyWith(
      gameState: state.gameState.copyWith(
        stats: stats,
        usedRescuePowers: {...state.gameState.usedRescuePowers, type},
        availableRescuePowers: {...state.gameState.availableRescuePowers}..remove(type),
      ),
      ending: null,
      rescueOpportunity: null,
    );
    final next = _pickNextCard(state.gameState.copyWith(seenCardIds: {...state.gameState.seenCardIds}));
    state = state.copyWith(currentCard: next);
    _saveCurrentGame();
  }

  void declineRescue() {
    final type = state.rescueOpportunity;
    if (type == null) return;
    final ending = _endingResolver.resolve(state: state.gameState, availableEndings: _repository.endings);
    if (ending != null) {
      _progress.markEndingSeen(ending.id);
      _progress.registerMandate(
        turns: state.statistics.totalTurns,
        left: state.statistics.leftSwipes,
        right: state.statistics.rightSwipes,
        eraIndex: state.gameState.currentEra.index,
        days: state.gameState.daysInPower,
        endingId: ending.id,
        endingTitle: ending.title,
        finalStats: {
          for (final entry in state.gameState.stats.entries) entry.key: entry.value.value,
        },
      );
    }
    state = state.copyWith(ending: ending, rescueOpportunity: null);
  }

  void _saveCurrentGame() {
    final s = state.gameState;
    _progress.saveGame({
      'stats': {for (final e in s.stats.entries) e.key.index.toString(): e.value.value},
      'era': s.currentEra.index, 'turn': s.turn, 'days': s.daysInPower,
      'seen': s.seenCardIds.toList(), 'flags': s.flags.toList(),
      'unlocked': s.unlockedCharacterIds.toList(), 'rescue': s.usedRescuePowers.map((e) => e.index).toList(),
      'pending': s.pendingNextCardId,
      'availableRescue': s.availableRescuePowers.map((e) => e.index).toList(),
      'rescueOpportunity': state.rescueOpportunity?.index,
      'card': state.currentCard?.id,
      'activeEvent': s.activeEventId,
      'eventPlayed': s.eventCardsPlayed,
      'eventCards': s.activeEventCardIds,
      'statistics': state.statistics.toJson(),
      'securityCompromises': s.securityCompromises,
      'assassinationCountdown': s.assassinationCountdown,
    });
  }

  GameState _restoreState(Map<String, dynamic> data) {
    final rawStats = Map<String, dynamic>.from(data['stats'] as Map);
    return GameState(stats: {for (final type in StatType.values) type: Stat(type, (rawStats[type.index.toString()] as num?)?.toInt() ?? Stat.initial)}, currentEra: Era.values[(data['era'] as num?)?.toInt() ?? 0], turn: (data['turn'] as num?)?.toInt() ?? 0, daysInPower: (data['days'] as num?)?.toInt() ?? 1, seenCardIds: {...((data['seen'] as List?)?.cast<String>() ?? [])}, flags: {...((data['flags'] as List?)?.cast<String>() ?? [])}, unlockedCharacterIds: {...((data['unlocked'] as List?)?.cast<String>() ?? [])}, usedRescuePowers: {...(((data['rescue'] as List?) ?? []).map((e) => StatType.values[(e as num).toInt()]))}, availableRescuePowers: {...(((data['availableRescue'] as List?) ?? []).map((e) => StatType.values[(e as num).toInt()]))}, pendingNextCardId: data['pending'] as String?, activeEventId: data['activeEvent'] as String?, eventCardsPlayed: (data['eventPlayed'] as num?)?.toInt() ?? 0, activeEventCardIds: ((data['eventCards'] as List?)?.cast<String>() ?? const []), securityCompromises: (data['securityCompromises'] as num?)?.toInt() ?? 0, assassinationCountdown: (data['assassinationCountdown'] as num?)?.toInt());
  }

  Era _eraForTurn(int turn) {
    return Era.values.lastWhere((era) => turn >= era.unlockAtTurn);
  }
}

class _PickResult {
  final GameCard? card;
  final bool recycled;
  const _PickResult(this.card, this.recycled);
}
