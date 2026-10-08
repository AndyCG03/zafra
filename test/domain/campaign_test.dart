import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zafra/data/models/game_mode.dart';
import 'package:zafra/data/models/game_difficulty.dart';
import 'package:zafra/domain/game_engine/island_chronicle.dart';
import 'package:zafra/data/models/stat.dart';
import 'package:zafra/data/repositories/card_repository.dart';
import 'package:zafra/data/repositories/event_repository.dart';
import 'package:zafra/domain/game_engine/effect_applier.dart';
import 'package:zafra/domain/game_engine/ending_resolver.dart';
import 'package:zafra/domain/game_engine/game_controller.dart';
import 'package:zafra/domain/game_engine/game_state.dart';
import 'package:zafra/domain/game_engine/game_state_codec.dart';
import 'package:zafra/services/persistence/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repository = CardRepository();
  const applier = EffectApplier();
  late Directory directory;
  late ProgressService progress;
  final controllers = <GameController>[];
  setUpAll(() async {
    await repository.loadAll();
    await EventRepository.loadEvents();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('zafra_campaign_');
    Hive.init(directory.path);
    progress = ProgressService();
    await progress.init();
    await progress.markTutorialCompleted();
    // No creator tutorial in these campaign playthroughs.
    await progress.registerGameStarted();
  });
  tearDown(() async {
    for (final controller in controllers) {
      controller.dispose();
    }
    controllers.clear();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  Future<GameController> open() async {
    final controller =
        GameController(repository, progress: progress, random: Random(11));
    controllers.add(controller);
    await controller.ready;
    expect(controller.state.loadError, isNull);
    return controller;
  }

  GameState answer(GameState state, String id,
          [SwipeDirection direction = SwipeDirection.left]) =>
      applier.applyChoice(
          state: state, card: repository.cardById(id)!, direction: direction);

  test('dificultades completan campaña y conservan periódico al reabrir',
      () async {
    for (final difficulty in GameDifficulty.values) {
      final controller = await open();
      await controller.startNewGame(GameMode.campaign, GovernmentPromise.water,
          difficulty: difficulty);
      var editions = 0;
      while (controller.state.ending == null &&
          controller.state.gameState.turn < 45) {
        final state = controller.state.gameState;
        final id = controller.state.currentCard!.id;
        double score(SwipeDirection direction) {
          final next = answer(state, id, direction);
          if (next.hasCollapsed) return -100000;
          return -next.stats.values
              .fold<double>(0, (sum, stat) => sum + pow(stat.value - 50, 2));
        }

        await controller.choose(
            score(SwipeDirection.left) >= score(SwipeDirection.right)
                ? SwipeDirection.left
                : SwipeDirection.right);
        if (controller.state.gameState.newspaperAct > 0) {
          editions++;
          expect(GameStateCodec.decode(progress.savedGame!).newspaperAct,
              controller.state.gameState.newspaperAct);
          await controller.dismissNewspaper();
          expect(progress.savedGame!['newspaperAct'], 0);
        }
      }
      expect(controller.state.ending?.isStoryEnding, isTrue,
          reason: difficulty.label);
      expect(editions, 5);
      await controller.restart();
      expect(controller.state.gameState.difficulty, difficulty);
    }
  });

  test(
      'proyectos se seleccionan solo en ilimitado y conservan plazo al reabrir',
      () async {
    final controller = await open();
    await controller.startNewGame(GameMode.endless, GovernmentPromise.water);
    await controller.selectProject(IslandProject.trade);
    expect(controller.state.gameState.project, isNull);
    final saved = {...progress.savedGame!, 'turn': 12};
    await progress.saveGame(saved);
    final eligible = await open();
    await eligible.selectProject(IslandProject.trade);
    expect(eligible.state.gameState.projectDeadline, 22);
    await eligible.selectProject(IslandProject.rebuild);
    expect(eligible.state.gameState.project, IslandProject.trade);
    final restored = await open();
    expect(restored.state.gameState.project, IslandProject.trade);
    expect(restored.state.gameState.projectDeadline, 22);
    await restored.startNewGame(GameMode.campaign, GovernmentPromise.water);
    await restored.selectProject(IslandProject.trade);
    expect(restored.state.gameState.project, isNull);
  });

  test(
      'abrir el selector no cuenta un gobierno; modos guardan y restauran por separado',
      () async {
    final controller = await open();
    expect(controller.state.currentCard, isNull);
    expect(progress.gamesPlayed, 1);
    await controller.startNewGame(
        GameMode.endless, GovernmentPromise.sovereignty);
    await controller.choose(SwipeDirection.left);
    final endless = controller.state.gameState;
    final endlessCard = controller.state.currentCard!.id;
    await controller.startNewGame(GameMode.campaign, GovernmentPromise.water);
    await controller.choose(SwipeDirection.right);
    expect(controller.state.gameState.campaignIndex, 1);
    expect(controller.state.currentCard!.id, repository.campaignCardIds[1]);
    await controller.resumeMode(GameMode.endless);
    expect(controller.state.gameState.turn, endless.turn);
    expect(controller.state.currentCard!.id, endlessCard);
    expect(controller.state.gameState.promise, GovernmentPromise.sovereignty);
    await controller.resumeMode(GameMode.campaign);
    expect(controller.state.gameState.campaignIndex, 1);
    expect(controller.state.gameState.promise, GovernmentPromise.water);
    expect(controller.state.gameState.history.single.choice,
        repository.cardById(repository.campaignCardIds.first)!.right.text);
    final reopened = await open();
    expect(reopened.state.gameState.campaignIndex, 1);
    expect(reopened.state.currentCard!.id, repository.campaignCardIds[1]);
    await reopened.restart();
    expect(reopened.state.gameState.mode, GameMode.campaign);
    expect(progress.savedGameForMode('endless')!['turn'], endless.turn);
  });

  test(
      'campaña completa mantiene orden, decisiones y final sin crisis aleatorias',
      () async {
    final controller = await open();
    await controller.startNewGame(GameMode.campaign, GovernmentPromise.water);
    for (final baseId in repository.campaignCardIds) {
      final id = repository.campaignCardAt(controller.state.gameState)!.id;
      expect(
          repository.campaignCardIds[controller.state.gameState.campaignIndex],
          baseId);
      expect(controller.state.ending, isNull, reason: 'Cayó antes de $id');
      expect(controller.state.currentCard!.id, id);
      final state = controller.state.gameState;
      double score(SwipeDirection direction) {
        final next = answer(state, id, direction);
        if (next.hasCollapsed) return -100000;
        return -next.stats.values
            .fold<double>(0, (sum, stat) => sum + pow(stat.value - 50, 2));
      }

      final direction =
          score(SwipeDirection.left) >= score(SwipeDirection.right)
              ? SwipeDirection.left
              : SwipeDirection.right;
      await controller.choose(direction);
      expect(controller.state.gameState.activeEventId, isNull);
      expect(controller.state.gameState.pendingConsequences, isEmpty);
    }
    expect(controller.state.gameState.campaignIndex,
        repository.campaignCardIds.length);
    expect(controller.state.gameState.history.length,
        repository.campaignCardIds.length);
    expect(controller.state.ending!.isStoryEnding, isTrue);
    expect(progress.savedGame!['ending'], controller.state.ending!.id);
    final reopened = await open();
    expect(reopened.state.ending!.id, controller.state.ending!.id);
    final turn = reopened.state.gameState.turn;
    await reopened.choose(SwipeDirection.left);
    expect(reopened.state.gameState.turn, turn);
  });

  test(
      'cada operador deja pruebas distintas y solo pruebas verificadas revelan el desvío',
      () {
    for (final route in ['puerto_cooperativa', 'puerto_exclusiva']) {
      var state =
          GameState.initial(mode: GameMode.campaign).copyWith(flags: {route});
      for (var chapter = 1; chapter <= 6; chapter++) {
        state = answer(state.copyWith(stats: GameState.initial().stats),
            'cosecha_0$chapter');
      }
      final proof = route == 'puerto_cooperativa'
          ? 'prueba_desvio_escolta'
          : 'prueba_desvio_contrato';
      expect(state.flags, contains(proof));
      state = answer(state, 'cosecha_07');
      expect(state.flags, contains('misterio_revelado'));
      expect(state.flags, isNot(contains('misterio_incierto')));
    }
    final unproven = answer(GameState.initial(), 'cosecha_07');
    expect(unproven.flags, contains('misterio_incierto'));
    expect(unproven.flags, isNot(contains('misterio_revelado')));
    expect(unproven.history.last.notes, isNotEmpty);
    final covered =
        answer(GameState.initial(), 'cosecha_07', SwipeDirection.right);
    expect(covered.flags, contains('misterio_encubierto'));
  });

  test('confianza protege al negociar; rivalidad del General retira respaldo',
      () {
    final neutral = GameState.initial();
    final supported = neutral.copyWith(characterTrust: {'la_lider_vecinal': 3});
    final disputed = neutral.copyWith(characterTrust: {'el_general': -3});
    final portNeutral = answer(neutral, 'historia_puerto_04');
    final portSupported = answer(supported, 'historia_puerto_04');
    expect(portSupported.statOf(StatType.pueblo).value,
        greaterThan(portNeutral.statOf(StatType.pueblo).value));
    final withdrawn =
        answer(disputed, 'historia_puerto_04', SwipeDirection.right);
    expect(withdrawn.flags, contains('general_retiro_apoyo'));
    expect(
        withdrawn.statOf(StatType.aparatoDelEstado).value,
        lessThan(answer(neutral, 'historia_puerto_04', SwipeDirection.right)
            .statOf(StatType.aparatoDelEstado)
            .value));
    final protest = EventRepository.definitions
        .firstWhere((e) => e.id == 'rebelion')
        .cards
        .first;
    expect(
        protest.resolvedText(supported.flags, trust: supported.characterTrust),
        contains('Líder Vecinal'));
    expect(protest.resolvedText(disputed.flags, trust: disputed.characterTrust),
        contains('retira'));
  });

  test('agua de los barrios reaparece en el contrato de exportación', () {
    final basic = answer(GameState.initial(), 'cruce_contrato');
    final crossed = answer(
        GameState.initial().copyWith(flags: {'agua_barrios'}),
        'cruce_contrato');
    expect(crossed.statOf(StatType.economia).value,
        lessThan(basic.statOf(StatType.economia).value));
    expect(crossed.history.last.notes, isNotEmpty);
  });

  test('promesas y los cinco finales especiales dependen del legado', () {
    expect(GovernmentPromise.water.status({'agua_legado_comun'}),
        PromiseStatus.fulfilled);
    expect(GovernmentPromise.sovereignty.status({'puerto_legado_dependiente'}),
        PromiseStatus.broken);
    expect(
        GovernmentPromise.civilian
            .status({'agua_local', 'puerto_consulta', 'lider_pacto'}),
        PromiseStatus.fulfilled);
    expect(
        GovernmentPromise.civilian.status({
          'agua_local',
          'puerto_consulta',
          'lider_pacto',
          'general_privilegios'
        }),
        PromiseStatus.broken);
    final outcomes = <String, Set<String>>{
      'ending_transicion_pactada': {'sucesion_comunidad'},
      'ending_comunidad_autonoma': {
        'sucesion_comunidad',
        'agua_legado_comun',
        'agua_local',
        'puerto_abierto',
        'puerto_legado_autonomo'
      },
      'ending_isla_acreedores': {
        'puerto_legado_dependiente',
        'puerto_monopolio'
      },
      'ending_cosecha_silencio': {'misterio_encubierto'},
      'ending_gobierno_perpetuo': {'sucesion_perpetua'},
    };
    for (final entry in outcomes.entries) {
      expect(
          EndingResolver()
              .resolveStory(
                  state: GameState.initial().copyWith(flags: entry.value),
                  availableEndings: repository.endings)!
              .id,
          entry.key);
    }
  });

  test('los cinco desenlaces son alcanzables sin reiniciar los indicadores',
      () {
    final routes = <String, Map<String, SwipeDirection>>{
      'ending_gobierno_perpetuo': {'camp_transicion': SwipeDirection.right},
      'ending_transicion_pactada': {
        'historia_agua_07': SwipeDirection.right,
        'historia_puerto_08': SwipeDirection.left,
        'cosecha_08': SwipeDirection.left,
        'camp_transicion': SwipeDirection.left
      },
      'ending_comunidad_autonoma': {
        'historia_agua_07': SwipeDirection.left,
        'historia_agua_08': SwipeDirection.left,
        'historia_puerto_07': SwipeDirection.left,
        'historia_puerto_08': SwipeDirection.left,
        'cosecha_08': SwipeDirection.left,
        'camp_transicion': SwipeDirection.left
      },
      'ending_isla_acreedores': {
        'historia_puerto_07': SwipeDirection.right,
        'historia_puerto_08': SwipeDirection.right,
        'cosecha_08': SwipeDirection.left,
        'camp_transicion': SwipeDirection.left
      },
      'ending_cosecha_silencio': {
        'historia_puerto_08': SwipeDirection.left,
        'cosecha_08': SwipeDirection.right,
        'camp_transicion': SwipeDirection.left
      },
    };
    for (final route in routes.entries) {
      var state = GameState.initial(mode: GameMode.campaign);
      for (var index = 0; index < repository.campaignCardIds.length; index++) {
        state = state.copyWith(campaignIndex: index);
        final id = repository.campaignCardAt(state)!.id;
        double score(SwipeDirection direction) {
          final next = answer(state, id, direction);
          if (next.hasCollapsed) return -100000;
          return -next.stats.values
              .fold<double>(0, (sum, stat) => sum + pow(stat.value - 50, 2));
        }

        final direction = route.value[id] ??
            (score(SwipeDirection.left) >= score(SwipeDirection.right)
                ? SwipeDirection.left
                : SwipeDirection.right);
        state = answer(state, id, direction);
        expect(state.hasCollapsed, isFalse, reason: '${route.key}: $id');
      }
      expect(
          EndingResolver()
              .resolveStory(state: state, availableEndings: repository.endings)!
              .id,
          route.key);
    }
  });

  test('el primer tutorial conserva el modo y la promesa al terminar',
      () async {
    final box = Hive.box('zafra_progress');
    await box.put('app_statistics', {'games': 0});
    await box.put('tutorial_completed', false);
    final controller = await open();
    await controller.startNewGame(
        GameMode.campaign, GovernmentPromise.civilian);
    expect(controller.state.currentCard!.id, 'creador_001');
    await controller.choose(SwipeDirection.left);
    expect(controller.state.isTutorial, isTrue);
    // Omitir el recorrido y la configuración vuelve a la primera escena.
    await controller.choose(SwipeDirection.right);
    await controller.choose(SwipeDirection.right);
    expect(controller.state.isTutorial, isFalse);
    expect(controller.state.currentCard!.id, repository.campaignCardIds.first);
    expect(controller.state.gameState.mode, GameMode.campaign);
    expect(controller.state.gameState.promise, GovernmentPromise.civilian);
    expect(controller.state.gameState.campaignIndex, 0);
    expect(controller.state.gameState.turn, 0);
  });

  test('guardados antiguos migran a ilimitado y la crónica acota su tamaño',
      () {
    final old = GameStateCodec.decode({
      'turn': 107,
      'characterFavorCount': {'el_general': 12}
    });
    expect(old.mode, GameMode.endless);
    expect(old.promise, isNull);
    expect(old.characterTrust['el_general'], 5);
    var state = GameState.initial();
    for (var n = 0; n < 70; n++) {
      state = answer(
          state.copyWith(stats: GameState.initial().stats), 'humor_radio');
    }
    final restored = GameStateCodec.decode(GameStateCodec.encode(state));
    expect(restored.history.length, 60);
    expect(restored.history.first.turn, 11);
    expect(
        restored.characterTrust.values, everyElement(inInclusiveRange(-5, 5)));
  });
}
