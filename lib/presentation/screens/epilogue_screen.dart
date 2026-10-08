import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ending.dart';
import '../../domain/game_engine/game_state.dart';
import '../../domain/game_engine/game_controller.dart';
import '../../domain/game_engine/future_epilogue.dart';
import '../widgets/ending_art.dart';

class EpilogueScreen extends ConsumerWidget {
  final GameState government;
  final Ending ending;
  const EpilogueScreen(
      {super.key, required this.government, required this.ending});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = FutureEpilogue.build(government, ending);
    final repository = ref.watch(cardRepositoryProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('CINCO AÑOS DESPUÉS')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(height: 210, child: EndingArt(ending: ending))),
          const SizedBox(height: 16),
          Text(ending.title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
          const SizedBox(height: 8),
          const Text(
              'La vida continúa con lo que construiste, lo que callaste y las personas que quedaron aquí.'),
          const SizedBox(height: 16),
          for (final entry in entries)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            if (entry.characterId != null) ...[
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                      repository.imageAssetForCharacter(
                                          entry.characterId!),
                                      height: 54,
                                      width: 54,
                                      fit: BoxFit.cover)),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                                child: Text(entry.title,
                                    style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold))),
                          ]),
                          const SizedBox(height: 12),
                          Text(entry.text.trim(),
                              style: const TextStyle(height: 1.5)),
                        ]))),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('VOLVER AL DESENLACE')),
        ]));
  }
}
