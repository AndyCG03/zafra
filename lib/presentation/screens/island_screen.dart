import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/game_engine/game_controller.dart';
import '../../domain/game_engine/island_snapshot.dart';
import '../widgets/island_map.dart';

class IslandScreen extends ConsumerStatefulWidget {
  const IslandScreen({super.key});
  @override
  ConsumerState<IslandScreen> createState() => _IslandScreenState();
}

class _IslandScreenState extends ConsumerState<IslandScreen> {
  IslandDistrict selected = IslandDistrict.water;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider).gameState;
    final island = IslandSnapshot(state);
    final report = island.report(selected);
    return Scaffold(
        appBar: AppBar(title: const Text('LA ISLA QUE CONSTRUYES')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('DECISIÓN ${state.turn} · ${state.mode.label.toUpperCase()}',
              style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 8),
          const Text(
              'Toca una zona para conocer lo que cambió con tu gobierno.'),
          const SizedBox(height: 16),
          IslandMap(
              island: island,
              selected: selected,
              onSelect: (district) => setState(() => selected = district)),
          const SizedBox(height: 16),
          Text(selected.label.toUpperCase(),
              style: const TextStyle(color: Color(0xFFC79A3E), fontSize: 12)),
          const SizedBox(height: 8),
          Text(report.title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
          const SizedBox(height: 8),
          Text(report.detail, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 20),
          FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('VOLVER A LA DECISIÓN')),
        ]));
  }
}
