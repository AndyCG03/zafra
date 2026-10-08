import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:zafra/data/models/era.dart';
import 'package:zafra/data/models/game_card.dart';
import 'package:zafra/domain/game_engine/card_selector.dart';
import 'package:zafra/domain/game_engine/effect_applier.dart';
import 'package:zafra/domain/game_engine/game_state.dart';
import 'package:zafra/domain/game_engine/game_state_codec.dart';

GameCard card(
        {String id = 'test',
        String era = 'fundacional',
        int weight = 1,
        CardCondition condition = const CardCondition(),
        CardOption? option}) =>
    GameCard(
      id: id,
      characterId: 'el_general',
      eraId: era,
      text: 'Normal',
      weight: weight,
      condition: condition,
      left: option ?? const CardOption(text: 'Sí', effects: {}),
      right: const CardOption(text: 'No', effects: {}),
      memoryVariants: const [
        MemoryVariant(
            requiresFlags: {'promesa', 'cumplida'}, text: 'Cumpliste.'),
        MemoryVariant(requiresFlags: {'promesa'}, text: 'Lo prometiste.'),
      ],
    );

void main() {
  final selector = CardSelector(random: Random(7));
  GameCard? select(GameState state, List<GameCard> cards) =>
      selector.selectNext(
        state: state,
        availableCards: cards,
        findById: (id) {
          for (final c in cards) {
            if (c.id == id) return c;
          }
          return null;
        },
      );
  test('decisiones guardan memoria y favor sin mutar el estado anterior', () {
    final before = GameState.initial().copyWith(turn: 4);
    final choice = card(
        option: const CardOption(
            text: 'Prometer',
            effects: {},
            setFlags: ['promesa'],
            favorsCharacter: 'el_general'));
    final after = const EffectApplier().applyChoice(
        state: before, card: choice, direction: SwipeDirection.left);
    expect(after.flags, {'promesa'});
    expect(after.flagSetAtTurn, {'promesa': 5});
    expect(after.characterFavorCount, {'el_general': 1});
    expect(before.flags, isEmpty);
    final repeated = const EffectApplier().applyChoice(
        state: after, card: choice, direction: SwipeDirection.left);
    expect(repeated.flagSetAtTurn['promesa'], 5);
    expect(repeated.characterFavorCount['el_general'], 2);
  });
  test('resolver una promesa elimina su flag y fecha', () {
    final before = GameState.initial()
        .copyWith(flags: {'promesa'}, flagSetAtTurn: {'promesa': 1});
    final after = const EffectApplier().applyChoice(
        state: before,
        card: card(
            option: const CardOption(
                text: 'Resolver', effects: {}, clearFlags: ['promesa'])),
        direction: SwipeDirection.left);
    expect(after.flags, isEmpty);
    expect(after.flagSetAtTurn, isEmpty);
  });
  test('las consecuencias esperan el número de turnos requerido', () {
    final consequence =
        card(condition: const CardCondition(minTurnsAfterFlag: {'promesa': 3}));
    final state = GameState.initial()
        .copyWith(flags: {'promesa'}, flagSetAtTurn: {'promesa': 5}, turn: 7);
    expect(select(state, [consequence]), isNull);
    expect(select(state.copyWith(turn: 8), [consequence]), consequence);
    expect(select(state.copyWith(turn: 8, flagSetAtTurn: {}), [consequence]),
        isNull);
  });
  test('las agendas requieren favor acumulado', () {
    final agenda =
        card(condition: const CardCondition(minFavorCount: {'el_general': 3}));
    expect(select(GameState.initial(), [agenda]), isNull);
    expect(
        select(
            GameState.initial()
                .copyWith(characterFavorCount: {'el_general': 3}),
            [agenda]),
        agenda);
  });
  test('texto usa la primera variante compatible y tiene fallback', () {
    expect(card().resolvedText({}), 'Normal');
    expect(card().resolvedText({'promesa'}), 'Lo prometiste.');
    expect(card().resolvedText({'promesa', 'cumplida'}), 'Cumpliste.');
  });
  test('un personaje conocido no adelanta contenido futuro', () {
    final future = card(era: 'futurista');
    final state =
        GameState.initial().copyWith(unlockedCharacterIds: {'el_general'});
    expect(select(state, [future]), isNull);
    expect(select(state.copyWith(currentEra: Era.futurista), [future]), future);
  });
  test('ramas respetan condiciones y cartas vistas', () {
    final branch =
        card(condition: const CardCondition(requiresFlags: {'promesa'}));
    final fallback = card(id: 'fallback');
    final state = GameState.initial().copyWith(pendingNextCardId: 'test');
    expect(select(state, [branch, fallback]), fallback);
    expect(
        select(state.copyWith(flags: {'promesa'}), [branch, fallback]), branch);
    expect(
        select(state.copyWith(flags: {'promesa'}, seenCardIds: {'test'}),
            [branch, fallback]),
        fallback);
  });
  test('pesos no positivos no provocan nextInt(0)', () {
    expect(
        select(GameState.initial(),
            [card(weight: 0), card(id: 'negative', weight: -2)]),
        isNull);
  });
  test('guardado conserva memoria, ramas y eventos', () {
    final state = GameState.initial().copyWith(
        turn: 8,
        flags: {'promesa'},
        flagSetAtTurn: {'promesa': 5},
        characterFavorCount: {'el_general': 3},
        pendingNextCardId: 'branch',
        activeEventId: 'huracan',
        eventCardsPlayed: 2,
        activeEventCardIds: ['a', 'b', 'c']);
    expect(
        GameStateCodec.encode(
            GameStateCodec.decode(GameStateCodec.encode(state))),
        GameStateCodec.encode(state));
  });
  test('partidas antiguas y enums inválidos usan valores seguros', () {
    final state = GameStateCodec.decode({
      'era': 100,
      'rescue': [-1, 99],
      'turn': -5
    });
    expect(state.currentEra, Era.futurista);
    expect(state.usedRescuePowers, isEmpty);
    expect(state.turn, 0);
    expect(state.flagSetAtTurn, isEmpty);
  });
}
