import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:zafra/data/models/era.dart';
import 'package:zafra/data/models/game_card.dart';
import 'package:zafra/data/repositories/card_repository.dart';
import 'package:zafra/data/repositories/event_repository.dart';
import 'package:zafra/domain/game_engine/card_selector.dart';
import 'package:zafra/domain/game_engine/effect_applier.dart';
import 'package:zafra/domain/game_engine/game_state.dart';
import 'package:zafra/domain/game_engine/game_state_codec.dart';
import 'package:zafra/domain/game_engine/legacy_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repository = CardRepository();
  setUpAll(() async {
    await repository.loadAll();
    await EventRepository.loadEvents();
  });
  test(
      'agenda persiste, respeta plazos y eras; responder elimina el compromiso',
      () {
    final opening = repository.cardById('historia_agua_01')!;
    final before = GameState.initial();
    final applied = const EffectApplier().applyChoice(
        state: before, card: opening, direction: SwipeDirection.left);
    expect(before.pendingConsequences, isEmpty);
    expect(applied.pendingConsequences.length, 3);
    final restored = GameStateCodec.decode(GameStateCodec.encode(applied));
    expect(restored.pendingConsequences.map((e) => e.dueTurn), [4, 2, 3]);
    final selector = CardSelector(random: Random(1));
    expect(selector.selectConsequence(restored, repository.cardById), isNull);
    final port = selector.selectConsequence(
        restored.copyWith(turn: 3), repository.cardById)!;
    expect(port.id, 'historia_puerto_01');
    final resolved = const EffectApplier().applyChoice(
        state: restored.copyWith(turn: 3),
        card: port,
        direction: SwipeDirection.right);
    expect(resolved.pendingConsequences.map((e) => e.cardId),
        ['historia_agua_02', 'humor_radio', 'historia_puerto_02']);
    final future = restored.copyWith(turn: 20, pendingConsequences: const [
      PendingConsequence(
          cardId: 'historia_puerto_08', title: 'Claves', dueTurn: 2)
    ]);
    expect(selector.selectConsequence(future, repository.cardById), isNull);
    expect(
        selector
            .selectConsequence(
                future.copyWith(currentEra: Era.futurista), repository.cardById)
            ?.id,
        'historia_puerto_08');
  });
  test('todos los capítulos se completan en ambas rutas y cambian el legado',
      () {
    for (final direction in SwipeDirection.values) {
      var state = GameState.initial();
      for (var n = 1; n <= 8; n++) {
        for (final arc in ['agua', 'puerto']) {
          final card = repository
              .cardById('historia_${arc}_${n.toString().padLeft(2, '0')}')!;
          if (n > 1) {
            expect(card.resolvedText(state.flags), isNot(card.text),
                reason: card.id);
            expect(state.pendingConsequences.map((e) => e.cardId),
                contains(card.id));
          }
          state = const EffectApplier()
              .applyChoice(state: state, card: card, direction: direction);
          // La prueba recorre el contenido; el balance se verifica en partidas completas aparte.
          state = state.copyWith(stats: GameState.initial().stats);
        }
      }
      expect(
          state.pendingConsequences
              .where((e) => e.cardId.startsWith('historia_')),
          isEmpty);
      expect(
          state.flags,
          contains(direction == SwipeDirection.left
              ? 'agua_legado_comun'
              : 'agua_legado_privado'));
      expect(
          state.flags,
          contains(direction == SwipeDirection.left
              ? 'puerto_legado_autonomo'
              : 'puerto_legado_dependiente'));
      expect(LegacySummary.paragraphs(state).length, greaterThanOrEqualTo(2));
    }
  });
  test('capítulos futuros no entran por azar ni se repiten al agotar el mazo',
      () {
    final selector = CardSelector(random: Random(1));
    expect(
        selector.selectNext(
            state: GameState.initial().copyWith(currentEra: Era.futurista),
            availableCards:
                repository.allCards.where((c) => c.storyArc != null).toList(),
            findById: repository.cardById),
        isNull);
  });
  test(
      'crisis tienen inicio, desarrollo ordenado y cierre en cuatro decisiones',
      () {
    for (final event in EventRepository.definitions) {
      for (var seed = 0; seed < 20; seed++) {
        final sequence = event.sequence(Random(seed));
        expect(sequence.length, 4);
        expect(sequence.first, event.cards.first.id);
        expect(sequence.last, event.cards.last.id);
        final indices = sequence
            .map((id) => event.cards.indexWhere((c) => c.id == id))
            .toList();
        expect(indices, orderedEquals([...indices]..sort()));
        expect(indices.toSet().length, 4);
      }
    }
  });
  test('agenda antigua sigue cargando sin compromisos inventados', () {
    expect(GameStateCodec.decode({'turn': 10}).pendingConsequences, isEmpty);
  });
}
