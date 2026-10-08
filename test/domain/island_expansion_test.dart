import 'package:flutter_test/flutter_test.dart';
import 'package:zafra/data/models/game_card.dart';
import 'package:zafra/data/models/game_difficulty.dart';
import 'package:zafra/data/models/game_mode.dart';
import 'package:zafra/data/models/stat.dart';
import 'package:zafra/domain/game_engine/effect_applier.dart';
import 'package:zafra/domain/game_engine/game_state.dart';
import 'package:zafra/domain/game_engine/game_state_codec.dart';
import 'package:zafra/domain/game_engine/island_chronicle.dart';

void main() {
  const applier = EffectApplier();
  GameCard card(Map<StatType, int> effects, {List<String> flags = const []}) =>
      GameCard(
          id: 'test',
          characterId: 'la_lider_vecinal',
          eraId: 'fundacional',
          text: 'Decisión de prueba',
          left: CardOption(text: 'Elegir', effects: effects, setFlags: flags),
          right: const CardOption(text: 'Esperar', effects: {}));
  GameState answer(GameState state, GameCard card) => applier.applyChoice(
      state: state, card: card, direction: SwipeDirection.left);

  test(
      'dificultad cambia presión, conserva efectos narrativos y migra a Normal',
      () {
    final decision = card({StatType.economia: -10, StatType.pueblo: 5},
        flags: ['agua_legado_comun']);
    final results = [
      for (final difficulty in GameDifficulty.values)
        answer(
            GameState.initial(
                mode: GameMode.campaign,
                promise: GovernmentPromise.water,
                difficulty: difficulty),
            decision)
    ];
    expect(results[0].statOf(StatType.economia).value,
        greaterThan(results[1].statOf(StatType.economia).value));
    expect(results[2].statOf(StatType.economia).value,
        lessThan(results[1].statOf(StatType.economia).value));
    for (final result in results) {
      expect(result.promiseStatus, PromiseStatus.fulfilled);
      expect(GameStateCodec.decode(GameStateCodec.encode(result)).difficulty,
          result.difficulty);
    }
    expect(GameStateCodec.decode({}).difficulty, GameDifficulty.normal);
  });
  test('encuentros exclusivos requieren operador, rivalidad o pruebas', () {
    final state = GameState.initial(mode: GameMode.campaign);
    expect(IslandChronicle.routeId(state, 'humor_sello'), isNull);
    expect(
        IslandChronicle.routeId(
            state.copyWith(flags: {'puerto_cooperativa'}), 'humor_sello'),
        'ruta_cooperativa');
    expect(
        IslandChronicle.routeId(
            state.copyWith(flags: {'puerto_exclusiva'}), 'humor_sello'),
        'ruta_acreedor');
    expect(
        IslandChronicle.routeId(
            state.copyWith(characterTrust: {'el_general': -3}), 'humor_colas'),
        'ruta_rival');
    expect(
        IslandChronicle.routeId(
            state.copyWith(flags: {'prueba_desvio_contrato'}), 'humor_estatua'),
        'ruta_testigo');
    expect(
        IslandChronicle.routeId(
            state.copyWith(characterTrust: {'el_general': -2}), 'humor_colas'),
        isNull);
  });
  test('periódico reconoce promesa y operador sin inventar pruebas', () {
    final state = GameState.initial(promise: GovernmentPromise.water).copyWith(
        flags: {'agua_legado_comun', 'puerto_cooperativa'}, newspaperAct: 2);
    final headlines = IslandChronicle.newspaper(state).join(' ');
    expect(headlines, contains('realidad'));
    expect(headlines, contains('trabajadores'));
    expect(headlines, contains('preguntas'));
    expect(GameStateCodec.decode(GameStateCodec.encode(state)).newspaperAct, 2);
  });
  test('proyectos se completan, vencen y preparan una nueva convocatoria', () {
    for (final project in IslandProject.values) {
      var state =
          GameState.initial().copyWith(project: project, projectDeadline: 10);
      for (var n = 0; n < 4; n++) {
        state = answer(state, card({project.stat: 1}));
      }
      expect(state.project, isNull);
      expect(state.projectsCompleted, 1);
      expect(state.nextProjectTurn, 10);
      expect(state.hasCollapsed, isFalse);
    }
    var expired = GameState.initial()
        .copyWith(project: IslandProject.rebuild, projectDeadline: 2);
    expired = answer(answer(expired, card({})), card({}));
    expect(expired.project, isNull);
    expect(expired.projectsCompleted, 0);
    expect(expired.history.last.notes.join(' '), contains('no llegó a tiempo'));
    expect(
        IslandProject.succession
            .advances({StatType.pueblo: 2, StatType.aparatoDelEstado: 1}),
        isFalse);
  });
  test(
      'guardar proyecto conserva plazo y progreso; recompensa no cruza el equilibrio',
      () {
    var state = GameState.initial().copyWith(
        project: IslandProject.trade, projectProgress: 3, projectDeadline: 10);
    state = GameStateCodec.decode(GameStateCodec.encode(state));
    expect(state.projectProgress, 3);
    expect(state.projectDeadline, 10);
    final result = answer(state, card({StatType.economia: 1}));
    expect(result.statOf(StatType.economia).value, 50);
  });
  test('decisiones decisivas sobreviven a más de sesenta turnos y al guardado',
      () {
    var state = answer(
        GameState.initial(),
        card({}, flags: [
          'agua_legado_comun',
          'lider_pacto',
          'prueba_desvio_contrato'
        ]));
    for (var n = 0; n < 70; n++) {
      state = answer(state, card({}));
    }
    expect(state.history.length, 60);
    final restored = GameStateCodec.decode(GameStateCodec.encode(state));
    expect(
        IslandChronicle.milestones(restored).any((r) => r.turn == 1), isTrue);
    expect(IslandChronicle.milestones(restored).length, 3);
  });
}
