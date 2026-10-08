import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:zafra/data/repositories/card_repository.dart';
import 'package:zafra/data/models/game_mode.dart';
import 'package:zafra/domain/game_engine/effect_applier.dart';
import 'package:zafra/domain/game_engine/game_controller.dart';
import 'package:zafra/domain/game_engine/game_state.dart';
import 'package:zafra/services/persistence/progress_service.dart';

class MemoryProgress extends ProgressService {
  Map<String, dynamic>? saved;
  @override
  Future<void> init() async {}
  @override
  Future<void> markEraReached(int eraIndex) async {}
  @override
  bool get hasCompletedTutorial => true;
  @override
  int get gamesPlayed => 2;
  @override
  Map<String, dynamic>? get savedGame => saved;
  @override
  Future<void> saveGame(Map<String, dynamic> data) async {
    saved = data;
  }
}

double score(GameState state) {
  if (state.hasCollapsed) return -100000;
  return -state.stats.values
      .fold<double>(0, (sum, stat) => sum + pow(stat.value - 50, 2));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'simulación reproducible de partidas completas y alternativas de balance',
      () async {
    final repository = CardRepository();
    await repository.loadAll();
    for (final loss in [1.50, 1.45, 1.40]) {
      for (final strategic in [false, true]) {
        var turns = 0;
        var wins = 0;
        var future = 0;
        var completedArcs = 0;
        for (var seed = 0; seed < 100; seed++) {
          final applier = EffectApplier(lossMultiplier: loss);
          final controller = GameController(repository,
              progress: MemoryProgress(),
              random: Random(seed),
              effectApplier: applier);
          await controller.ready;
          await controller.startNewGame(
              GameMode.endless, GovernmentPromise.water);
          expect(controller.state.loadError, isNull);
          final decisions = Random(seed + 1000);
          while (controller.state.ending == null &&
              controller.state.gameState.turn < 100) {
            final state = controller.state.gameState;
            final rescue = controller.state.rescueOpportunity;
            if (rescue != null) {
              await controller.useRescuePower(rescue);
              continue;
            }
            final card = controller.state.currentCard!;
            var direction = decisions.nextBool()
                ? SwipeDirection.left
                : SwipeDirection.right;
            if (strategic) {
              final left = applier.applyChoice(
                  state: state, card: card, direction: SwipeDirection.left);
              final right = applier.applyChoice(
                  state: state, card: card, direction: SwipeDirection.right);
              direction = score(left) >= score(right)
                  ? SwipeDirection.left
                  : SwipeDirection.right;
              if (card.id.endsWith('guardaeaspalda_trampa')) {
                direction = SwipeDirection.right;
              }
              if (card.id == 'seguridad_alerta') {
                direction = SwipeDirection.left;
              }
            }
            await controller.choose(direction);
          }
          final end = controller.state;
          turns += end.gameState.turn;
          if (end.ending?.isSurvival == true) wins++;
          if (end.gameState.turn >= 78) future++;
          if (end.gameState.seenCardIds.contains('historia_puerto_08')) {
            completedArcs++;
          }
          controller.dispose();
        }
        // ignore: avoid_print
        print(
            'BALANCE loss=$loss strategic=$strategic n=100 meanTurns=${turns / 100} survival=$wins future=$future portCompleted=$completedArcs');
        expect(turns, greaterThan(0));
      }
    }
  });
}
