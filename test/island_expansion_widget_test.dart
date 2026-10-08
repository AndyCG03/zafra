import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zafra/data/models/game_mode.dart';
import 'package:zafra/data/repositories/card_repository.dart';
import 'package:zafra/domain/game_engine/game_controller.dart';
import 'package:zafra/domain/game_engine/game_state.dart';
import 'package:zafra/domain/game_engine/game_state_codec.dart';
import 'package:zafra/presentation/screens/island_news_screen.dart';
import 'package:zafra/presentation/screens/relationships_screen.dart';
import 'package:zafra/presentation/screens/agenda_screen.dart';
import 'domain/balance_simulation_test.dart' show MemoryProgress;

void main() {
  Future<GameController> mount(
      WidgetTester tester, GameState state, Widget screen) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = CardRepository();
    final progress = MemoryProgress()
      ..saved = {...GameStateCodec.encode(state), 'card': 'historia_agua_04'};
    late GameController controller;
    await tester.runAsync(() async {
      await repo.loadAll();
      controller = GameController(repo, progress: progress);
      await controller.ready;
    });
    await tester.pumpWidget(ProviderScope(overrides: [
      cardRepositoryProvider.overrideWithValue(repo),
      gameControllerProvider.overrideWith((ref) => controller),
    ], child: MaterialApp(home: screen)));
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('periódico móvil se lee y se cierra sin consumir una decisión',
      (tester) async {
    final controller = await mount(
        tester,
        GameState.initial(mode: GameMode.campaign)
            .copyWith(turn: 7, campaignIndex: 7, newspaperAct: 2),
        const IslandNewsScreen());
    expect(find.text('EL FARO DE LA ISLA'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('CONTINUAR LA HISTORIA'), 250);
    await tester.tap(find.text('CONTINUAR LA HISTORIA'));
    await tester.pumpAndSettle();
    expect(controller.state.gameState.newspaperAct, 0);
    expect(controller.state.gameState.turn, 7);
    expect(tester.takeException(), isNull);
  });
  testWidgets('ficha permite leer confianza y acuerdo sin desbordar móvil',
      (tester) async {
    await mount(
        tester,
        GameState.initial().copyWith(
            characterTrust: {'la_lider_vecinal': 3}, flags: {'lider_pacto'}),
        const RelationshipsScreen());
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    expect(find.textContaining('pacto público con los barrios firmado'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('agenda permite elegir un proyecto y muestra plazo y progreso',
      (tester) async {
    final controller = await mount(
        tester, GameState.initial().copyWith(turn: 12), const AgendaScreen());
    await tester.drag(find.byType(ListView).first, const Offset(0, -380));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reconstruir los barrios'));
    await tester.pumpAndSettle();
    expect(controller.state.gameState.project, isNotNull);
    expect(find.textContaining('0/4 avances'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
