import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:zafra/data/models/game_mode.dart';
import 'package:zafra/data/models/stat.dart';
import 'package:zafra/data/repositories/card_repository.dart';
import 'package:zafra/domain/game_engine/effect_applier.dart';
import 'package:zafra/domain/game_engine/future_epilogue.dart';
import 'package:zafra/domain/game_engine/game_state.dart';
import 'package:zafra/domain/game_engine/game_state_codec.dart';
import 'package:zafra/domain/game_engine/island_snapshot.dart';
import 'package:zafra/domain/game_engine/game_controller.dart';
import 'balance_simulation_test.dart' show MemoryProgress;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repository = CardRepository();
  const applier = EffectApplier();
  setUpAll(repository.loadAll);
  GameState choose(GameState state, String id, SwipeDirection direction) =>
      applier.applyChoice(
          state: state, card: repository.cardById(id)!, direction: direction);

  test('las decisiones cambian zonas concretas y el mapa no consume turnos',
      () {
    final original = GameState.initial();
    expect(IslandSnapshot(original).waterRepaired, isFalse);
    final improved = original.copyWith(flags: {
      'agua_legado_comun',
      'agua_resuelta',
      'agua_local',
      'puerto_legado_autonomo',
      'puerto_resuelto',
      'tramites_unificados',
      'biblioteca_publica'
    });
    final map = IslandSnapshot(improved);
    expect(map.waterRepaired, isTrue);
    expect(map.commonWater, isTrue);
    expect(map.autonomousPort, isTrue);
    expect(map.dependentPort, isFalse);
    expect(map.simplifiedQueues, isTrue);
    expect(map.report(IslandDistrict.neighborhoods).detail,
        contains('cola se acortó'));
    expect(map.report(IslandDistrict.palace).title, contains('biblioteca'));
    for (final district in IslandDistrict.values) {
      expect(map.report(district).detail, isNotEmpty);
    }
    expect(improved.turn, original.turn);
    expect(original.flags, isEmpty);
    final privatized = IslandSnapshot(original.copyWith(flags: {
      'agua_legado_privado',
      'puerto_legado_dependiente',
      'registro_provisional'
    }));
    expect(privatized.report(IslandDistrict.water).title,
        contains('concesionario'));
    expect(privatized.report(IslandDistrict.port).title, contains('fuera'));
    expect(privatized.report(IslandDistrict.neighborhoods).detail,
        contains('cola que vuelve'));
  });

  test(
      'las historias personales regresan, cambian el epílogo y tienen efectos posteriores',
      () {
    final ending = repository.endings
        .firstWhere((e) => e.id == 'ending_transicion_pactada');
    for (final direction in SwipeDirection.values) {
      var state = GameState.initial(mode: GameMode.campaign);
      for (final character in ['lider', 'general', 'cantinera']) {
        state = choose(state, 'personal_${character}_01', direction);
        final later = repository.cardById('personal_${character}_02')!;
        expect(later.resolvedText(state.flags, trust: state.characterTrust),
            isNot(later.text));
        state = choose(state, later.id, direction);
      }
      final epilogue = FutureEpilogue.build(
          GameStateCodec.decode(GameStateCodec.encode(state)), ending);
      expect(epilogue.map((e) => e.title),
          ['Los barrios', 'La Líder Vecinal', 'El General', 'La Cantinera']);
      expect(
          epilogue[1].text,
          contains(direction == SwipeDirection.left
              ? 'testimonios del puente'
              : 'mismo banco'));
      expect(
          epilogue[2].text,
          contains(direction == SwipeDirection.left
              ? 'Entregó las herramientas'
              : 'servicio mixto'));
      expect(
          epilogue[3].text,
          contains(
              direction == SwipeDirection.left ? 'regresó' : 'dos puertos'));
    }
    final withTraining =
        GameState.initial().copyWith(flags: {'aprendices_puerto'});
    expect(
        choose(withTraining, 'cruce_contrato', SwipeDirection.left)
            .statOf(StatType.economia)
            .value,
        greaterThan(
            choose(GameState.initial(), 'cruce_contrato', SwipeDirection.left)
                .statOf(StatType.economia)
                .value));
    final pact =
        choose(GameState.initial(), 'personal_lider_02', SwipeDirection.right);
    expect(
        choose(pact, 'audiencia_pueblo', SwipeDirection.left)
            .history
            .last
            .notes
            .join(' '),
        contains('acta común'));
  });

  test('los recuerdos no inventan desenlaces personales en partidas antiguas',
      () {
    final collapsed =
        repository.endings.firstWhere((e) => !e.isStoryEnding && !e.isSurvival);
    final old = GameStateCodec.decode({'turn': 19});
    final entries = FutureEpilogue.build(old, collapsed);
    expect(entries.first.text, contains('Después de la caída'));
    expect(entries.last.text, contains('vive fuera'));
    expect(entries.last.text, isNot(contains('regresó')));
    expect(entries[2].text, contains('conserva la llave'));
  });

  test('una campaña de 34 escenas conserva su decisión al ampliar el guion',
      () async {
    final progress = MemoryProgress();
    progress.saved = {
      ...GameStateCodec.encode(GameState.initial(mode: GameMode.campaign)
          .copyWith(campaignIndex: 12, turn: 12)),
      'card': 'general_disputa'
    };
    final controller =
        GameController(repository, progress: progress, random: Random(8));
    addTearDown(controller.dispose);
    await controller.ready;
    expect(controller.state.currentCard!.id, 'general_disputa');
    final index = repository.campaignCardIds.indexOf('general_disputa');
    expect(controller.state.gameState.campaignIndex, index);
    await controller.choose(SwipeDirection.left);
    expect(controller.state.currentCard!.id,
        repository.campaignCardIds[index + 1]);
    expect(controller.state.gameState.turn, 13);
  });
}
