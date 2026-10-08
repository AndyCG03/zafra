import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zafra/presentation/screens/loading_screen.dart';
import 'package:zafra/presentation/widgets/stat_bar.dart';
import 'package:zafra/presentation/widgets/island_map.dart';
import 'package:zafra/presentation/widgets/ending_art.dart';
import 'package:zafra/domain/game_engine/island_snapshot.dart';
import 'package:zafra/domain/game_engine/game_state.dart';
import 'package:zafra/data/repositories/card_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zafra/domain/game_engine/game_controller.dart';
import 'package:zafra/presentation/screens/epilogue_screen.dart';

void main() {
  testWidgets('epílogo se lee completo con desplazamiento en móvil',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = CardRepository();
    await tester.runAsync(repository.loadAll);
    await tester.pumpWidget(ProviderScope(
        overrides: [cardRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
            home: EpilogueScreen(
                government: GameState.initial().copyWith(flags: {
                  'agua_legado_comun',
                  'agua_local',
                  'memoria_puente',
                  'general_relevo_civil',
                  'taller_retorno'
                }),
                ending: repository.endings
                    .firstWhere((e) => e.id == 'ending_comunidad_autonoma')))));
    await tester.pumpAndSettle();
    expect(find.text('CINCO AÑOS DESPUÉS'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('VOLVER AL DESENLACE'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('VOLVER AL DESENLACE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('mapa permite seleccionar zonas en una pantalla pequeña',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = IslandDistrict.water;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(20),
                child: StatefulBuilder(
                    builder: (context, setState) => IslandMap(
                        island: IslandSnapshot(GameState.initial()),
                        selected: selected,
                        onSelect: (district) =>
                            setState(() => selected = district)))))));
    for (final district in IslandDistrict.values) {
      await tester.tap(find.text(district.label));
      await tester.pumpAndSettle();
      expect(selected, district);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
      'las cinco ilustraciones se dibujan en final y galería sin errores',
      (tester) async {
    final repository = CardRepository();
    await tester.runAsync(repository.loadAll);
    for (final ending in repository.endings.where((e) => e.isStoryEnding)) {
      for (final size in [const Size(280, 200), const Size(132, 175)]) {
        await tester.pumpWidget(MaterialApp(
            home: Center(
                child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: EndingArt(ending: ending)))));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: ending.id);
      }
    }
  });
  testWidgets('carga muestra Zafra y su indicador', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoadingScreen()));
    expect(find.text('ZAFRA'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
  testWidgets('estadísticas comunican valor y peligro', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: StatIndicator(
                icon: Icons.groups,
                label: 'Pueblo',
                value: 10,
                isInDanger: true))));
    expect(find.bySemanticsLabel('Pueblo'), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel('Pueblo')).value,
        '10 de 100, en peligro');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
