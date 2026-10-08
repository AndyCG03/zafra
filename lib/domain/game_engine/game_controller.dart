import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../../data/models/ending.dart';
import '../../data/models/character.dart';
import '../../data/models/game_card.dart';
import '../../data/models/era.dart';
import '../../data/models/stat.dart';
import '../../data/models/game_mode.dart';
import '../../data/repositories/card_repository.dart';
import 'card_selector.dart';
import 'effect_applier.dart';
import 'ending_resolver.dart';
import 'island_chronicle.dart';
import '../../data/models/game_difficulty.dart';
import 'game_state.dart';
import 'game_state_codec.dart';
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
  static const _unchanged = Object();
  final GameState gameState;
  final GameCard? currentCard;
  final Ending? ending;
  final bool isLoading;
  final Character? unlockedCharacter;
  final GameStatistics statistics;
  final StatType? rescueOpportunity;
  final bool tutorialQuestion;
  final bool tutorialOptionsQuestion;
  final bool openOptionsRequested;
  final bool isTutorial;
  final String? loadError;

  const GameControllerState({
    required this.gameState,
    required this.currentCard,
    required this.ending,
    required this.isLoading,
    this.unlockedCharacter,
    this.statistics = const GameStatistics(),
    this.rescueOpportunity,
    this.tutorialQuestion = false,
    this.tutorialOptionsQuestion = false,
    this.openOptionsRequested = false,
    this.isTutorial = false,
    this.loadError,
  });

  factory GameControllerState.loading() => GameControllerState(
        gameState: GameState.initial(),
        currentCard: null,
        ending: null,
        isLoading: true,
        isTutorial: false,
      );

  GameControllerState copyWith({
    GameState? gameState,
    GameCard? currentCard,
    Ending? ending,
    bool? isLoading,
    Character? unlockedCharacter,
    bool clearUnlockedCharacter = false,
    bool clearCurrentCard = false,
    GameStatistics? statistics,
    Object? rescueOpportunity = _unchanged,
    bool? tutorialQuestion,
    bool? tutorialOptionsQuestion,
    bool? openOptionsRequested,
    bool? isTutorial,
    String? loadError,
  }) {
    return GameControllerState(
      gameState: gameState ?? this.gameState,
      currentCard: clearCurrentCard ? null : (currentCard ?? this.currentCard),
      ending: ending ?? this.ending,
      isLoading: isLoading ?? this.isLoading,
      unlockedCharacter: clearUnlockedCharacter
          ? null
          : (unlockedCharacter ?? this.unlockedCharacter),
      statistics: statistics ?? this.statistics,
      rescueOpportunity: identical(rescueOpportunity, _unchanged)
          ? this.rescueOpportunity
          : rescueOpportunity as StatType?,
      tutorialQuestion: tutorialQuestion ?? this.tutorialQuestion,
      tutorialOptionsQuestion:
          tutorialOptionsQuestion ?? this.tutorialOptionsQuestion,
      openOptionsRequested: openOptionsRequested ?? this.openOptionsRequested,
      isTutorial: isTutorial ?? this.isTutorial,
      loadError: loadError,
    );
  }
}

class GameController extends StateNotifier<GameControllerState> {
  static const _assassinationCardIds = {
    'era1_guardaeaspalda_trampa',
    'era2_guardaeaspalda_trampa',
    'era3_guardaeaspalda_trampa',
    'era4_guardaeaspalda_trampa',
  };
  final CardRepository _repository;
  final CardSelector _selector;
  final EffectApplier _applier;
  final EndingResolver _endingResolver = EndingResolver();
  final Random _random;
  final ProgressService _progress;
  late final Future<void> ready;
  bool _choosing = false;
  SwipeDirection? _pendingDirection;
  static const _tutorialCardIds = [
    'tutorial_001',
    'tutorial_002',
    'tutorial_003',
    'tutorial_004',
    'tutorial_005',
  ];
  static const _tutorialQuestionCardId = 'tutorial_question';
  static const _tutorialOptionsCardId = 'tutorial_options';

  CardOption cardOptionFor(GameCard card, SwipeDirection direction) =>
      direction == SwipeDirection.left ? card.left : card.right;
  StatType? _statType(String value) {
    for (final type in StatType.values) {
      if (type.name == value) return type;
    }
    return null;
  }

  GameCard? _findCard(String id) {
    final normal = _repository.cardById(id);
    if (normal != null) return normal;
    for (final creator in _repository.creatorCards) {
      if (creator.id == id) return creator;
    }
    return EventRepository.cardById(id);
  }

  EventDefinition? _eventAfterDecision(CardOption option, GameState gameState) {
    if (option.startsEvent != null) {
      if (gameState.flags.contains('event_${option.startsEvent}_seen')) {
        return null;
      }
      return EventRepository.byId(option.startsEvent!);
    }
    if (gameState.turn < 5 ||
        gameState.turn - gameState.lastEventEndedTurn < 4) {
      return null;
    }

    final pueblo = option.effects[StatType.pueblo] ?? 0;
    final economia = option.effects[StatType.economia] ?? 0;
    final exterior = option.effects[StatType.relacionesExteriores] ?? 0;
    final estado = option.effects[StatType.aparatoDelEstado] ?? 0;

    var negativeCount = 0;
    if (pueblo < 0) negativeCount++;
    if (economia < 0) negativeCount++;
    if (exterior < 0) negativeCount++;
    if (estado < 0) negativeCount++;

    final chance = .04 + (negativeCount * .03);
    if (_random.nextDouble() >= chance) return null;

    final candidates = <String>[];
    if (pueblo < 0) candidates.addAll(['rebelion', 'refugiados']);
    if (economia < 0) candidates.addAll(['corrupcion', 'accidente']);
    if (exterior < 0) candidates.addAll(['refugiados', 'terrorismo']);
    if (estado < 0) candidates.addAll(['rebelion', 'terrorismo']);
    if (_random.nextDouble() < .08) candidates.add('huracan');
    candidates
        .removeWhere((id) => gameState.flags.contains('event_${id}_seen'));
    if (candidates.isEmpty) return null;
    return EventRepository.byId(candidates[_random.nextInt(candidates.length)]);
  }

  GameController(this._repository,
      {ProgressService? progress, Random? random, EffectApplier? effectApplier})
      : _progress = progress ?? ProgressService(),
        _applier = effectApplier ?? const EffectApplier(),
        _random = random ?? Random(),
        _selector = CardSelector(random: random),
        super(GameControllerState.loading()) {
    ready = _start();
  }

  Future<void> _start() async {
    try {
      await _initialize();
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
          isLoading: false, loadError: 'No se pudo cargar el juego: $error');
    }
  }

  Future<void> retryLoad() async {
    if (state.isLoading) return;
    state = GameControllerState.loading();
    await _start();
  }

  Future<void> _initialize() async {
    await _progress.init();
    await EventRepository.loadEvents();
    await _repository.loadAll();
    await _progress.markEraReached(GameState.initial().currentEra.index);
    final initialState = GameState.initial();
    final saved = _progress.savedGame;
    if (saved != null) {
      _pendingDirection = saved['pendingDirection'] == 'right'
          ? SwipeDirection.right
          : SwipeDirection.left;
      var restored = GameStateCodec.decode(saved);
      // A content update may insert scenes before the saved cursor. The card ID
      // is stable; keep the current decision instead of replaying old chapters.
      if (restored.mode == GameMode.campaign &&
          saved['ending'] == null &&
          saved['isTutorial'] != true &&
          saved['card'] is String) {
        final cursor =
            _repository.campaignCardIds.indexOf(saved['card'] as String);
        if (cursor >= 0) restored = restored.copyWith(campaignIndex: cursor);
      }
      if (restored.mode == GameMode.endless &&
          restored.turn > 0 &&
          !restored.seenCardIds.contains('historia_agua_01') &&
          !restored.pendingConsequences
              .any((e) => e.cardId == 'historia_agua_01') &&
          _repository.cardById('historia_agua_01') != null) {
        restored = restored.copyWith(pendingConsequences: [
          ...restored.pendingConsequences,
          PendingConsequence(
              cardId: 'historia_agua_01',
              title: 'Agua: la promesa de reconstrucción',
              dueTurn: restored.turn),
        ]);
      }
      Ending? restoredEnding;
      for (final ending in _repository.endings) {
        if (ending.id == saved['ending']) restoredEnding = ending;
      }
      restoredEnding ??=
          restored.hasCollapsed && saved['rescueOpportunity'] == null
              ? _endingResolver.resolve(
                  state: restored, availableEndings: _repository.endings)
              : null;
      await _progress.markEraReached(restored.currentEra.index);
      final savedCard = saved['card'] as String?;
      final restoredCard =
          restoredEnding != null || saved['openOptionsRequested'] == true
              ? null
              : (savedCard == null ? null : _findCard(savedCard)) ??
                  _pickNextCard(restored);
      final rescueIndex = (saved['rescueOpportunity'] as num?)?.toInt();
      state = GameControllerState(
        gameState: restored,
        currentCard: restoredCard,
        ending: restoredEnding,
        isLoading: false,
        rescueOpportunity: rescueIndex == null ||
                rescueIndex < 0 ||
                rescueIndex >= StatType.values.length
            ? null
            : StatType.values[rescueIndex],
        statistics: GameStatistics.fromJson(saved['statistics'] as Map?),
        tutorialQuestion: saved['tutorialQuestion'] as bool? ?? false,
        tutorialOptionsQuestion:
            saved['tutorialOptionsQuestion'] as bool? ?? false,
        openOptionsRequested: saved['openOptionsRequested'] as bool? ?? false,
        isTutorial: saved['isTutorial'] as bool? ?? false,
      );
      return;
    }
    state = GameControllerState(
      gameState: initialState,
      currentCard: null,
      ending: null,
      isLoading: false,
    );
  }

  Future<void> choose(SwipeDirection direction) async {
    if (_choosing || state.isLoading || state.rescueOpportunity != null) return;
    _choosing = true;
    try {
      await _choose(direction);
    } finally {
      _choosing = false;
    }
  }

  Future<void> _choose(SwipeDirection direction) async {
    final card = state.currentCard;
    if (card == null || state.ending != null) return;

    if (state.isTutorial) {
      await _advanceTutorial(card, direction);
      return;
    }

    if (!_progress.hasCompletedTutorial &&
        _progress.gamesPlayed == 1 &&
        card.id == 'creador_001') {
      state = state.copyWith(
        isTutorial: true,
        currentCard: _findCard(_tutorialQuestionCardId),
        tutorialQuestion: true,
      );
      await _saveCurrentGame();
      return;
    }

    await _progress.addDiscoveredCard(card.id);
    if (card.characterId == 'el_creador') {
      await _progress.markCreatorMessageSeen(card.id);
    }

    _pendingDirection = direction;
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
    final isTrapChoice = _assassinationCardIds.contains(card.id) &&
        direction == SwipeDirection.left;
    if (isTrapChoice) {
      final compromises = state.gameState.securityCompromises + 1;
      stateWithRisk = stateWithRisk.copyWith(
        securityCompromises: compromises,
        assassinationCountdown:
            compromises >= 2 && state.gameState.assassinationCountdown == null
                ? 4
                : null,
      );
      if (compromises >= 2 &&
          state.gameState.assassinationCountdown == null &&
          _repository.cardById('seguridad_alerta') != null) {
        stateWithRisk = stateWithRisk.copyWith(
          pendingNextCardId: 'seguridad_alerta',
          seenCardIds: {...stateWithRisk.seenCardIds}
            ..remove('seguridad_alerta'),
        );
      }
    }
    var assassinationTriggered = false;
    if (cardOptionFor(card, direction).restoresSecurity) {
      stateWithRisk = stateWithRisk.copyWith(
          securityCompromises: 0, clearAssassinationCountdown: true);
    } else if (state.gameState.assassinationCountdown != null) {
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
      final ending = _repository.endings
          .firstWhere((e) => e.id == 'ending_aparato_min_asesinato');
      state = state.copyWith(
          gameState: stateWithRisk,
          ending: ending,
          statistics: updatedStatistics);
      await _progress.markEndingSeen(ending.id);
      await _progress.registerMandate(
        turns: updatedStatistics.totalTurns,
        left: updatedStatistics.leftSwipes,
        right: updatedStatistics.rightSwipes,
        eraIndex: stateWithRisk.currentEra.index,
        days: stateWithRisk.daysInPower,
        endingId: ending.id,
        endingTitle: ending.title,
        finalStats: {
          for (final entry in stateWithRisk.stats.entries)
            entry.key: entry.value.value
        },
      );
      await _saveCurrentGame();
      return;
    }

    if (stateWithRisk.hasCollapsed) {
      final collapsed = stateWithRisk.collapsedStat;
      if (collapsed != null &&
          available.contains(collapsed) &&
          !stateWithRisk.usedRescuePowers.contains(collapsed)) {
        state = state.copyWith(
            gameState: stateWithRisk,
            statistics: updatedStatistics,
            rescueOpportunity: collapsed);
        await _saveCurrentGame();
        return;
      }
      final ending = _endingResolver.resolve(
        state: stateWithRisk,
        availableEndings: _repository.endings,
      );
      if (ending != null) {
        await _progress.markEndingSeen(ending.id);
        await _progress.registerMandate(
          turns: updatedStatistics.totalTurns,
          left: updatedStatistics.leftSwipes,
          right: updatedStatistics.rightSwipes,
          eraIndex: stateWithRescue.currentEra.index,
          days: stateWithRescue.daysInPower,
          endingId: ending.id,
          endingTitle: ending.title,
          finalStats: {
            for (final entry in stateWithRescue.stats.entries)
              entry.key: entry.value.value,
          },
        );
      }
      state = state.copyWith(
        gameState: stateWithRisk,
        ending: ending,
        statistics: updatedStatistics,
      );
      await _saveCurrentGame();
      return;
    }

    await _advanceAfterChoice(
        stateWithRisk, updatedStatistics, card, direction);
  }

  Future<void> _advanceAfterChoice(
      GameState newState,
      GameStatistics updatedStatistics,
      GameCard card,
      SwipeDirection direction) async {
    final campaign = newState.mode == GameMode.campaign;
    final order = _repository.campaignCardIds;
    final index = campaign &&
            newState.campaignIndex < order.length &&
            (order[newState.campaignIndex] == card.id ||
                card.id.startsWith('ruta_'))
        ? newState.campaignIndex + 1
        : newState.campaignIndex;
    final nextScene = campaign && index < order.length
        ? _repository.cardById(order[index])
        : null;
    final nextEra = nextScene == null
        ? newState.currentEra
        : Era.values.firstWhere((e) => e.name == nextScene.eraId);
    var progressedState = newState.copyWith(
      campaignIndex: index,
      currentEra: campaign
          ? (nextEra.index > newState.currentEra.index
              ? nextEra
              : newState.currentEra)
          : _eraForTurn(newState.turn),
      daysInPower: state.gameState.daysInPower + 1 + _random.nextInt(6),
    );
    await _progress.markEraReached(progressedState.currentEra.index);
    if ((campaign && index >= order.length) ||
        cardOptionFor(card, direction).endsStory) {
      final survival = _endingResolver.resolveStory(
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
            for (final entry in progressedState.stats.entries)
              entry.key: entry.value.value,
          },
        );
        state = state.copyWith(
          gameState: progressedState,
          clearCurrentCard: true,
          ending: survival,
          statistics: updatedStatistics,
        );
        await _saveCurrentGame();
        return;
      }
    }
    GameCard? selectedCard;
    var recycled = false;
    if (campaign) {
      selectedCard = _repository.campaignCardAt(progressedState);
      if (_repository.campaignAct(index) >
          _repository.campaignAct(newState.campaignIndex)) {
        progressedState = progressedState.copyWith(
            newspaperAct: _repository.campaignAct(index));
      }
      if (selectedCard == null) {
        throw StateError('La campaña no tiene una escena para el paso $index.');
      }
    } else if (state.gameState.activeEventId != null) {
      final nextIndex = state.gameState.eventCardsPlayed + 1;
      if (nextIndex >= state.gameState.activeEventCardIds.length) {
        progressedState = progressedState.copyWith(
            clearActiveEvent: true, lastEventEndedTurn: progressedState.turn);
        if (EventRepository.definitions.every(
            (e) => progressedState.flags.contains('event_${e.id}_seen'))) {
          progressedState = progressedState.copyWith(
              flags: {
            ...progressedState.flags
          }..removeWhere((f) => f.startsWith('event_') && f.endsWith('_seen')));
        }
        final result = _pickNextCardResult(gameState: progressedState);
        selectedCard = result.card;
        recycled = result.recycled;
      } else {
        progressedState = progressedState.copyWith(eventCardsPlayed: nextIndex);
        selectedCard = _findCard(state.gameState.activeEventCardIds[nextIndex]);
      }
    } else {
      if (progressedState.pendingNextCardId != null) {
        selectedCard = _selector.selectNext(
          state: progressedState,
          availableCards: const [],
          findById: _repository.cardById,
        );
      }
      if (card.characterId == 'el_creador' && _progress.gamesPlayed == 1) {
        for (final creator in _repository.creatorCards) {
          if (!_progress.seenCreatorMessageIds.contains(creator.id) &&
              creator.id != card.id) {
            selectedCard = creator;
            break;
          }
        }
      }
      if (cardOptionFor(card, direction).startsEvent == null) {
        selectedCard ??=
            _selector.selectConsequence(progressedState, _repository.cardById);
      }
      final event = selectedCard == null
          ? _eventAfterDecision(cardOptionFor(card, direction), progressedState)
          : null;
      if (event != null) {
        final selected = event.sequence(_random);
        progressedState = progressedState.copyWith(
            activeEventId: event.id,
            eventCardsPlayed: 0,
            activeEventCardIds: selected,
            flags: {...progressedState.flags, 'event_${event.id}_seen'});
        await _progress.markEventDiscovered(event.id);
        selectedCard = _findCard(selected.first);
      } else if (selectedCard == null) {
        final result = _pickNextCardResult(gameState: progressedState);
        selectedCard = result.card;
        recycled = result.recycled;
      }
    }
    final result = _PickResult(selectedCard, recycled);
    final finalState = result.recycled
        ? progressedState.copyWith(
            seenCardIds: progressedState.seenCardIds
                .where((id) => _repository.cardById(id)?.storyArc != null)
                .toSet())
        : progressedState;

    final nextCharacter = result.card == null
        ? null
        : _repository.characterById(result.card!.characterId);
    final characterBelongsToEra = result.card != null &&
        nextCharacter != null &&
        !result.card!.characterId.startsWith('evento_');
    final isNewCharacter = characterBelongsToEra &&
        !finalState.unlockedCharacterIds.contains(nextCharacter.id);
    final firstTimeCharacter = characterBelongsToEra &&
        !_progress.unlockedCharacters.contains(nextCharacter.id);
    if (firstTimeCharacter) {
      await _progress.markCharacterUnlocked(nextCharacter.id);
    }
    final stateWithCharacter = isNewCharacter
        ? finalState.copyWith(unlockedCharacterIds: {
            ...finalState.unlockedCharacterIds,
            nextCharacter.id,
          })
        : finalState;
    state = state.copyWith(
      gameState: stateWithCharacter,
      currentCard: result.card,
      clearCurrentCard: result.card == null,
      unlockedCharacter: firstTimeCharacter ? nextCharacter : null,
      clearUnlockedCharacter: !firstTimeCharacter,
      statistics: updatedStatistics,
    );
    await _saveCurrentGame();
  }

  Future<void> _advanceTutorial(GameCard card, SwipeDirection direction) async {
    final isLeft = direction == SwipeDirection.left;

    if (card.id == 'creador_001') {
      state = state.copyWith(
        currentCard: _findCard(_tutorialQuestionCardId),
        tutorialQuestion: true,
      );
      await _saveCurrentGame();
      return;
    }

    if (card.id == _tutorialQuestionCardId) {
      final accepted = isLeft;
      state = state.copyWith(
        currentCard: accepted
            ? _findCard(_tutorialCardIds.first)
            : _findCard(_tutorialOptionsCardId),
        tutorialQuestion: false,
        tutorialOptionsQuestion: !accepted,
      );
      await _saveCurrentGame();
      return;
    }

    if (_tutorialCardIds.contains(card.id)) {
      final index = _tutorialCardIds.indexOf(card.id);
      final nextCard = index + 1 < _tutorialCardIds.length
          ? _findCard(_tutorialCardIds[index + 1])
          : _findCard(_tutorialOptionsCardId);
      state = state.copyWith(
        currentCard: nextCard,
        clearCurrentCard: nextCard == null,
        tutorialOptionsQuestion: nextCard?.id == _tutorialOptionsCardId,
      );
      await _saveCurrentGame();
      return;
    }

    if (card.id == _tutorialOptionsCardId) {
      final openOptions = isLeft;
      if (openOptions) {
        state = state.copyWith(
          currentCard: null,
          clearCurrentCard: true,
          openOptionsRequested: true,
          tutorialOptionsQuestion: false,
        );
      } else {
        await _finishTutorial();
      }
      await _saveCurrentGame();
      return;
    }
  }

  Future<void> _finishTutorial() async {
    await _progress.markTutorialCompleted();

    final fresh = GameState.initial(
        mode: state.gameState.mode,
        promise: state.gameState.promise,
        difficulty: state.gameState.difficulty);
    final nextCard = _pickNextCard(fresh);

    final character = nextCard == null
        ? null
        : _repository.characterById(nextCard.characterId);
    final characterBelongsToEra =
        nextCard != null && nextCard.eraId == fresh.currentEra.name;
    final notifyCharacter = characterBelongsToEra &&
        character != null &&
        !_progress.unlockedCharacters.contains(character.id);
    if (notifyCharacter) await _progress.markCharacterUnlocked(character.id);
    final stateWithCharacter = !characterBelongsToEra || character == null
        ? fresh
        : fresh.copyWith(unlockedCharacterIds: {character.id});

    state = GameControllerState(
      gameState: stateWithCharacter,
      currentCard: nextCard,
      ending: null,
      isLoading: false,
      unlockedCharacter: notifyCharacter ? character : null,
      isTutorial: false,
    );
    await _saveCurrentGame();
  }

  Future<void> finishOptionsSetup() async {
    if (!state.openOptionsRequested) return;
    if (state.isTutorial) {
      await _finishTutorial();
      return;
    }
    state = state.copyWith(
      currentCard: _pickNextCard(state.gameState),
      openOptionsRequested: false,
    );
    await _saveCurrentGame();
  }

  GameCard? _pickNextCard(GameState gameState) {
    return _pickNextCardResult(gameState: gameState).card;
  }

  GameCard? _pickOpeningCard(GameState gameState) {
    final games = _progress.gamesPlayed;
    if (gameState.mode == GameMode.campaign && games != 1) {
      return _pickNextCard(gameState);
    }
    if (games != 1 && games % 5 != 0) return _pickNextCard(gameState);
    for (final card in _repository.creatorCards) {
      if (!_progress.seenCreatorMessageIds.contains(card.id)) return card;
    }
    return _pickNextCard(gameState);
  }

  _PickResult _pickNextCardResult({required GameState gameState}) {
    final eraCards = _repository.allCards;
    if (eraCards.isEmpty) return const _PickResult(null, false);

    if (gameState.mode == GameMode.campaign) {
      final order = _repository.campaignCardIds;
      if (gameState.campaignIndex >= order.length) {
        return const _PickResult(null, false);
      }
      return _PickResult(_repository.campaignCardAt(gameState), false);
    }

    if (!gameState.seenCardIds.contains('historia_agua_01') &&
        gameState.turn <= 1) {
      final opening = _repository.cardById('historia_agua_01');
      if (opening != null) return _PickResult(opening, false);
    }
    final consequence =
        _selector.selectConsequence(gameState, _repository.cardById);
    if (consequence != null) return _PickResult(consequence, false);

    final card = _selector.selectNext(
      state: gameState,
      availableCards: eraCards,
      findById: _repository.cardById,
    );
    if (card != null) return _PickResult(card, false);

    // Solo reciclar asuntos cotidianos: los capítulos no deben reabrirse.
    final storyIds =
        eraCards.where((c) => c.storyArc != null).map((c) => c.id).toSet();
    final recycledState = gameState.copyWith(
        seenCardIds: gameState.seenCardIds.intersection(storyIds));
    final recycledCard = _selector.selectNext(
      state: recycledState,
      availableCards: eraCards,
      findById: _repository.cardById,
    );
    return _PickResult(recycledCard, recycledCard != null);
  }

  Future<void> restart() async {
    if (_choosing || state.isLoading) return;
    _choosing = true;
    final previous = state.gameState;
    try {
      state = GameControllerState.loading();
      _pendingDirection = null;
      await _progress.clearGame();
      await _startWithStatistics(const GameStatistics(),
          mode: previous.mode,
          promise: previous.promise,
          difficulty: previous.difficulty);
    } catch (error) {
      state = state.copyWith(
          isLoading: false,
          loadError: 'No se pudo reiniciar la partida: $error');
    } finally {
      _choosing = false;
    }
  }

  Future<void> dismissNewspaper() async {
    if (_choosing || state.isLoading) return;
    state =
        state.copyWith(gameState: state.gameState.copyWith(newspaperAct: 0));
    await _saveCurrentGame();
  }

  Future<void> selectProject(IslandProject project) async {
    final game = state.gameState;
    if (_choosing ||
        state.isLoading ||
        state.ending != null ||
        game.mode != GameMode.endless ||
        game.project != null ||
        game.turn < game.nextProjectTurn) {
      return;
    }
    _choosing = true;
    try {
      state = state.copyWith(
          gameState: game.copyWith(
              project: project,
              projectProgress: 0,
              projectDeadline: game.turn + 10));
      await _saveCurrentGame();
    } finally {
      _choosing = false;
    }
  }

  Map<String, dynamic>? savedMode(GameMode mode) =>
      _progress.savedGameForMode(mode.name);

  Future<void> resumeMode(GameMode mode) async {
    if (_choosing || state.isLoading) return;
    final saved = savedMode(mode);
    if (saved == null) return;
    _choosing = true;
    try {
      state = GameControllerState.loading();
      await _progress.saveGame(saved);
      await _start();
    } catch (error) {
      state = state.copyWith(
          isLoading: false,
          loadError: 'No se pudo recuperar la partida: $error');
    } finally {
      _choosing = false;
    }
  }

  Future<void> startNewGame(GameMode mode, GovernmentPromise promise,
      {GameDifficulty difficulty = GameDifficulty.normal}) async {
    if (_choosing || state.isLoading) return;
    _choosing = true;
    try {
      final previous = _progress.savedGame;
      if (previous != null) await _progress.saveGame(previous);
      state = GameControllerState.loading();
      _pendingDirection = null;
      await _startWithStatistics(const GameStatistics(),
          mode: mode, promise: promise, difficulty: difficulty);
    } catch (error) {
      state = state.copyWith(
          isLoading: false, loadError: 'No se pudo iniciar la partida: $error');
    } finally {
      _choosing = false;
    }
  }

  Future<void> _startWithStatistics(GameStatistics statistics,
      {GameMode mode = GameMode.endless,
      GovernmentPromise? promise,
      GameDifficulty difficulty = GameDifficulty.normal}) async {
    await EventRepository.loadEvents();
    await _repository.loadAll();
    await _progress.registerGameStarted();
    await _progress.markEraReached(GameState.initial().currentEra.index);
    final initialState =
        GameState.initial(mode: mode, promise: promise, difficulty: difficulty);
    final nextCard = _pickOpeningCard(initialState);
    final character = nextCard == null
        ? null
        : _repository.characterById(nextCard.characterId);
    final characterBelongsToEra =
        nextCard != null && nextCard.eraId == initialState.currentEra.name;
    final notifyCharacter = characterBelongsToEra &&
        character != null &&
        !_progress.unlockedCharacters.contains(character.id);
    if (notifyCharacter) await _progress.markCharacterUnlocked(character.id);
    final stateWithCharacter = !characterBelongsToEra || character == null
        ? initialState
        : initialState.copyWith(unlockedCharacterIds: {character.id});

    final isFirstGame =
        _progress.gamesPlayed == 1 && !_progress.hasCompletedTutorial;
    final isCreatorCard = nextCard?.characterId == 'el_creador';

    state = GameControllerState(
      gameState: stateWithCharacter,
      currentCard: nextCard,
      ending: null,
      isLoading: false,
      unlockedCharacter: notifyCharacter ? character : null,
      statistics: statistics,
      isTutorial: isFirstGame && isCreatorCard,
    );
    await _saveCurrentGame();
  }

  void acknowledgeCharacterUnlock() {
    state = state.copyWith(clearUnlockedCharacter: true);
  }

  bool canUseRescuePower(StatType type) {
    return state.gameState.availableRescuePowers.contains(type) &&
        !state.gameState.usedRescuePowers.contains(type) &&
        state.ending == null;
  }

  Future<void> useRescuePower(StatType type) async {
    if (_choosing || !canUseRescuePower(type)) return;
    if (state.rescueOpportunity != null && state.rescueOpportunity != type) {
      return;
    }
    _choosing = true;
    try {
      final stats = {...state.gameState.stats};
      final value = stats[type]!.value;
      stats[type] = stats[type]!.copyWithDelta(value >= 50 ? -22 : 22);
      final rescued = state.gameState.copyWith(
        stats: stats,
        usedRescuePowers: {...state.gameState.usedRescuePowers, type},
        availableRescuePowers: {...state.gameState.availableRescuePowers}
          ..remove(type),
      );
      final wasCollapsed = state.rescueOpportunity != null;
      state = state.copyWith(gameState: rescued, rescueOpportunity: null);
      if (wasCollapsed && rescued.hasCollapsed) {
        final nextCollapsed = rescued.collapsedStat!;
        if (canUseRescuePower(nextCollapsed)) {
          state = state.copyWith(rescueOpportunity: nextCollapsed);
          await _saveCurrentGame();
        } else {
          await _finishCollapsed(rescued);
        }
      } else if (wasCollapsed && state.currentCard != null) {
        // La decisión ya fue contabilizada; solo completar su progresión.
        await _advanceAfterChoice(rescued, state.statistics, state.currentCard!,
            _pendingDirection ?? SwipeDirection.left);
      } else {
        await _saveCurrentGame();
      }
    } finally {
      _choosing = false;
    }
  }

  Future<void> _finishCollapsed(GameState gameState) async {
    final ending = _endingResolver.resolve(
        state: gameState, availableEndings: _repository.endings);
    if (ending == null) return;
    state = state.copyWith(ending: ending, rescueOpportunity: null);
    await _progress.markEndingSeen(ending.id);
    await _progress.registerMandate(
      turns: state.statistics.totalTurns,
      left: state.statistics.leftSwipes,
      right: state.statistics.rightSwipes,
      eraIndex: gameState.currentEra.index,
      days: gameState.daysInPower,
      endingId: ending.id,
      endingTitle: ending.title,
      finalStats: {
        for (final entry in gameState.stats.entries)
          entry.key: entry.value.value
      },
    );
    await _saveCurrentGame();
  }

  Future<void> declineRescue() async {
    if (_choosing || state.rescueOpportunity == null) return;
    _choosing = true;
    try {
      await _finishCollapsed(state.gameState);
    } finally {
      _choosing = false;
    }
  }

  Future<void> _saveCurrentGame() async {
    final s = state.gameState;
    await _progress.saveGame({
      ...GameStateCodec.encode(s),
      'ending': state.ending?.id,
      'pendingDirection': _pendingDirection?.name,
      'rescueOpportunity': state.rescueOpportunity?.index,
      'card': state.currentCard?.id,
      'activeEvent': s.activeEventId,
      'eventPlayed': s.eventCardsPlayed,
      'eventCards': s.activeEventCardIds,
      'statistics': state.statistics.toJson(),
      'tutorialQuestion': state.tutorialQuestion,
      'tutorialOptionsQuestion': state.tutorialOptionsQuestion,
      'openOptionsRequested': state.openOptionsRequested,
      'securityCompromises': s.securityCompromises,
      'assassinationCountdown': s.assassinationCountdown,
      'isTutorial': state.isTutorial,
    });
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
