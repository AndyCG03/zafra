import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zafra/data/models/era.dart';
import 'package:zafra/data/models/ending.dart';
import 'package:zafra/data/models/game_card.dart';
import 'package:zafra/data/models/stat.dart';
import 'package:zafra/data/repositories/card_repository.dart';
import 'package:zafra/data/repositories/event_repository.dart';
import 'package:zafra/domain/game_engine/effect_applier.dart';
import 'package:zafra/domain/game_engine/game_controller.dart';
import 'package:zafra/domain/game_engine/game_state.dart';
import 'package:zafra/domain/game_engine/game_state_codec.dart';
import 'package:zafra/services/persistence/progress_service.dart';

const fatal = GameCard(
    id: 'fatal',
    characterId: 'el_general',
    eraId: 'fundacional',
    text: 'Crisis',
    left: CardOption(text: 'Baja', effects: {StatType.pueblo: -100}),
    right: CardOption(text: 'Sube', effects: {StatType.pueblo: 100}));
const calm = GameCard(
    id: 'calm',
    characterId: 'el_general',
    eraId: 'fundacional',
    text: 'Calma',
    left: CardOption(text: 'Sí', effects: {}),
    right: CardOption(text: 'No', effects: {}));
const future = GameCard(
    id: 'future',
    characterId: 'el_general',
    eraId: 'futurista',
    text: 'Futuro',
    left: CardOption(text: 'Sí', effects: {}),
    right: CardOption(text: 'No', effects: {}));

class FixtureRepository extends CardRepository {
  final List<Ending> catalog;
  final List<GameCard> cards;
  FixtureRepository(this.catalog, {this.cards = const [fatal, calm, future]});
  @override
  Future<void> loadAll() async {}
  @override
  List<GameCard> get allCards => cards;
  @override
  List<Ending> get endings => catalog;
  @override
  GameCard? cardById(String id) {
    for (final card in allCards) {
      if (card.id == id) return card;
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProgressService progress;
  late FixtureRepository repository;
  final controllers = <GameController>[];
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('zafra_test_');
    Hive.init(directory.path);
    progress = ProgressService();
    await progress.init();
    await progress.markTutorialCompleted();
    final catalog = CardRepository();
    await catalog.loadAll();
    repository = FixtureRepository(catalog.endings);
  });
  tearDown(() async {
    for (final controller in controllers) {
      controller.dispose();
    }
    controllers.clear();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  Future<GameController> restore(GameState state,
      {String cardId = 'fatal', Map<String, dynamic> extra = const {}}) async {
    await progress
        .saveGame({...GameStateCodec.encode(state), 'card': cardId, ...extra});
    final controller =
        GameController(repository, progress: progress, random: Random(7));
    controllers.add(controller);
    await controller.ready;
    expect(controller.state.loadError, isNull);
    return controller;
  }

  test('doble decisión simultánea solo cuenta una vez y el final se restaura',
      () async {
    final controller = await restore(GameState.initial());
    await Future.wait([
      controller.choose(SwipeDirection.left),
      controller.choose(SwipeDirection.left)
    ]);
    expect(controller.state.gameState.turn, 1);
    expect(progress.totalTurnsPlayed, 1);
    final restored = GameController(repository, progress: progress);
    controllers.add(restored);
    await restored.ready;
    expect(restored.state.ending!.id, controller.state.ending!.id);
    expect(progress.totalTurnsPlayed, 1);
  });
  test('rescate superior baja el valor y no repite la decisión', () async {
    final controller = await restore(
        GameState.initial().copyWith(availableRescuePowers: {StatType.pueblo}));
    await controller.choose(SwipeDirection.right);
    expect(controller.state.rescueOpportunity, StatType.pueblo);
    await controller.choose(SwipeDirection.left);
    expect(controller.state.gameState.turn, 1);
    await controller.useRescuePower(StatType.pueblo);
    expect(controller.state.gameState.statOf(StatType.pueblo).value, 78);
    expect(controller.state.gameState.turn, 1);
    expect(controller.state.currentCard!.id, 'calm');
    expect(controller.canUseRescuePower(StatType.pueblo), isFalse);
    await controller.useRescuePower(StatType.pueblo);
    expect(controller.state.gameState.statOf(StatType.pueblo).value, 78);
  });
  test('rechazar el rescate persiste el final y registra una sola derrota',
      () async {
    final controller = await restore(
        GameState.initial().copyWith(availableRescuePowers: {StatType.pueblo}));
    await controller.choose(SwipeDirection.left);
    await controller.declineRescue();
    await controller.declineRescue();
    expect(progress.savedGame!['ending'], controller.state.ending!.id);
    expect(progress.totalTurnsPlayed, 1);
  });
  test('rescate conserva la posición del evento', () async {
    await EventRepository.loadEvents();
    final initial = GameState.initial();
    final controller = await restore(
        initial.copyWith(
            stats: {
              ...initial.stats,
              StatType.pueblo: const Stat(StatType.pueblo, 1)
            },
            availableRescuePowers: {StatType.pueblo},
            activeEventId: 'huracan',
            activeEventCardIds: ['event_huracan_1', 'event_huracan_2']),
        cardId: 'event_huracan_1');
    await controller.choose(SwipeDirection.left);
    await controller.useRescuePower(StatType.pueblo);
    expect(controller.state.gameState.eventCardsPlayed, 1);
    expect(controller.state.currentCard!.id, 'event_huracan_2');
  });
  test(
      'el modo ilimitado atraviesa la era futurista y continúa tras el turno 96',
      () async {
    final controller = await restore(
        GameState.initial().copyWith(
            turn: 77,
            currentEra: Era.contemporanea,
            seenCardIds: {'fatal', 'calm'}),
        cardId: 'calm');
    await controller.choose(SwipeDirection.left);
    expect(controller.state.gameState.currentEra, Era.futurista);
    expect(controller.state.ending, isNull);
    expect(controller.state.currentCard!.id, 'future');
    final last = await restore(
        GameState.initial().copyWith(turn: 95, currentEra: Era.futurista),
        cardId: 'future');
    await last.choose(SwipeDirection.left);
    expect(last.state.gameState.turn, 96);
    expect(last.state.ending, isNull);
    expect(last.state.currentCard, isNotNull);
    expect(progress.savedGame!['ending'], isNull);
  });
  test('tutorial esperando opciones no recibe una carta al restaurar',
      () async {
    final controller = await restore(GameState.initial(), extra: {
      'card': null,
      'openOptionsRequested': true,
      'isTutorial': true
    });
    expect(controller.state.currentCard, isNull);
    expect(controller.state.openOptionsRequested, isTrue);
  });
  test('una carta eliminada del catálogo tiene fallback al restaurar',
      () async {
    final controller = await restore(GameState.initial(), cardId: 'missing');
    expect(controller.state.currentCard, isNotNull);
  });

  test('dos colapsos se rescatan antes de continuar', () async {
    const doubleCrisis = GameCard(
        id: 'double',
        characterId: 'el_general',
        eraId: 'fundacional',
        text: 'Dos crisis',
        left: CardOption(
            text: 'Decidir',
            effects: {StatType.pueblo: -100, StatType.economia: -100}),
        right: CardOption(text: 'Esperar', effects: {}));
    repository =
        FixtureRepository(repository.catalog, cards: [doubleCrisis, calm]);
    final controller = await restore(
        GameState.initial().copyWith(
            availableRescuePowers: {StatType.pueblo, StatType.economia}),
        cardId: 'double');
    await controller.choose(SwipeDirection.left);
    await controller.useRescuePower(StatType.pueblo);
    expect(controller.state.rescueOpportunity, StatType.economia);
    await controller.useRescuePower(StatType.economia);
    expect(controller.state.rescueOpportunity, isNull);
    expect(controller.state.gameState.hasCollapsed, isFalse);
    expect(controller.state.currentCard!.id, 'calm');
    expect(controller.state.gameState.turn, 1);
  });

  test('rescatar tras reabrir conserva la opcion y prioriza su rama', () async {
    const branched = GameCard(
        id: 'branch',
        characterId: 'el_general',
        eraId: 'fundacional',
        text: 'Rama',
        left: CardOption(text: 'Izquierda', effects: {}),
        right: CardOption(
            text: 'Derecha',
            effects: {StatType.pueblo: 100},
            nextCardId: 'calm',
            startsEvent: 'huracan'));
    repository = FixtureRepository(repository.catalog, cards: [branched, calm]);
    final controller = await restore(
        GameState.initial().copyWith(availableRescuePowers: {StatType.pueblo}),
        cardId: 'branch');
    await controller.choose(SwipeDirection.right);
    final reopened =
        GameController(repository, progress: progress, random: Random(7));
    controllers.add(reopened);
    await reopened.ready;
    await reopened.useRescuePower(StatType.pueblo);
    expect(reopened.state.currentCard!.id, 'calm');
    expect(reopened.state.gameState.activeEventId, isNull);
    expect(reopened.state.gameState.turn, 1);
  });

  test('cambios de interfaz conservan una crisis pendiente', () {
    final state = GameControllerState(
        gameState: GameState.initial(),
        currentCard: fatal,
        ending: null,
        isLoading: false,
        rescueOpportunity: StatType.pueblo);
    expect(state.copyWith(clearUnlockedCharacter: true).rescueOpportunity,
        StatType.pueblo);
    expect(state.copyWith(rescueOpportunity: null).rescueOpportunity, isNull);
  });

  test('personajes desbloqueados usan su propio catálogo de progreso',
      () async {
    await progress.markCharacterUnlocked('el_general');
    await progress.addDiscoveredCard('era1_001');
    expect(await progress.unlockedCharacterIds(), {'el_general'});
  });

  test(
      'segunda renuncia a la escolta ofrece una salida y renovar cancela el atentado',
      () async {
    final catalog = CardRepository();
    await catalog.loadAll();
    const trap = GameCard(
        id: 'era2_guardaeaspalda_trampa',
        characterId: 'el_guardaeaspalda',
        eraId: 'fundacional',
        text: 'Escolta',
        left: CardOption(text: 'Reducir', effects: {}),
        right: CardOption(text: 'Mantener', effects: {}));
    repository = FixtureRepository(repository.catalog,
        cards: [trap, catalog.cardById('seguridad_alerta')!, calm]);
    final controller = await restore(
        GameState.initial().copyWith(securityCompromises: 1),
        cardId: trap.id);
    await controller.choose(SwipeDirection.left);
    expect(controller.state.currentCard!.id, 'seguridad_alerta');
    expect(controller.state.gameState.assassinationCountdown, 4);
    final reopened =
        GameController(repository, progress: progress, random: Random(7));
    controllers.add(reopened);
    await reopened.ready;
    await reopened.choose(SwipeDirection.left);
    expect(reopened.state.gameState.assassinationCountdown, isNull);
    expect(reopened.state.gameState.securityCompromises, 0);
    expect(
        reopened.state.gameState.statOf(StatType.economia).value, lessThan(50));
    expect(reopened.state.ending, isNull);
  });
  test(
      'rechazar la advertencia mantiene el plazo y el atentado ocurre una sola vez',
      () async {
    final catalog = CardRepository();
    await catalog.loadAll();
    repository = FixtureRepository(repository.catalog,
        cards: [catalog.cardById('seguridad_alerta')!, calm]);
    final controller = await restore(
        GameState.initial()
            .copyWith(assassinationCountdown: 4, securityCompromises: 2),
        cardId: 'seguridad_alerta');
    await controller.choose(SwipeDirection.right);
    expect(controller.state.gameState.assassinationCountdown, 3);
    for (var i = 0; i < 3; i++) {
      await controller.choose(SwipeDirection.left);
    }
    expect(controller.state.ending!.id, 'ending_aparato_min_asesinato');
    final turn = controller.state.gameState.turn;
    await controller.choose(SwipeDirection.left);
    expect(controller.state.gameState.turn, turn);
    expect(progress.totalTurnsPlayed, turn);
  });

  test('cerrar un evento conserva su pausa antes de nuevas crisis aleatorias',
      () async {
    final event = EventRepository.definitions.first;
    final controller = await restore(
        GameState.initial().copyWith(
            turn: 5,
            activeEventId: event.id,
            eventCardsPlayed: 0,
            activeEventCardIds: [event.cards.last.id]),
        cardId: event.cards.last.id);
    await controller.choose(SwipeDirection.left);
    expect(controller.state.gameState.activeEventId, isNull);
    expect(controller.state.gameState.lastEventEndedTurn, 6);
    expect(GameStateCodec.decode(progress.savedGame!).lastEventEndedTurn, 6);
  });
}
