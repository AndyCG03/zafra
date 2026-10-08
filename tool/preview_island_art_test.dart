// Run: flutter test --no-pub tool/preview_island_art_test.dart
// Exports the game's original vector drawings for visual review, without a browser.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zafra/data/repositories/card_repository.dart';
import 'package:zafra/domain/game_engine/game_state.dart';
import 'package:zafra/domain/game_engine/island_snapshot.dart';
import 'package:zafra/presentation/widgets/ending_art.dart';
import 'package:zafra/presentation/widgets/island_map.dart';

void main() {
  testWidgets('exportar mapa y láminas de los finales', (tester) async {
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = CardRepository();
    await tester.runAsync(repository.loadAll);
    final key = GlobalKey();
    Future<void> save(String name, Widget child) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              backgroundColor: const Color(0xFF16211B),
              body: Align(
                  alignment: Alignment.topCenter,
                  child: RepaintBoundary(key: key, child: child)))));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/visual_review/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    await save(
        'mapa',
        SizedBox(
            width: 450,
            child: IslandMap(
                island: IslandSnapshot(GameState.initial().copyWith(flags: {
                  'agua_resuelta',
                  'agua_legado_comun',
                  'agua_local',
                  'puerto_resuelto',
                  'puerto_legado_autonomo',
                  'puerto_abierto',
                  'biblioteca_publica',
                  'aprendices_puerto',
                  'tramites_unificados'
                })),
                selected: IslandDistrict.water,
                onSelect: (_) {})));
    await save(
        'finales',
        SizedBox(
            width: 660,
            child: ColoredBox(
                color: const Color(0xFF16211B),
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(spacing: 12, runSpacing: 16, children: [
                      for (final ending
                          in repository.endings.where((e) => e.isStoryEnding))
                        SizedBox(
                            width: 312,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                      height: 203,
                                      child: EndingArt(ending: ending)),
                                  Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(ending.title,
                                          style: const TextStyle(
                                              color: Colors.white))),
                                ]))
                    ])))));
  });
}
