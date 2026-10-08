import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/game_engine/game_controller.dart';
import '../../domain/game_engine/island_chronicle.dart';

class IslandNewsScreen extends ConsumerWidget {
  const IslandNewsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider).gameState;
    final repository = ref.watch(cardRepositoryProvider);
    return Scaffold(
        backgroundColor: const Color(0xFFEAE1D3),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(24), children: [
          const Text('EL FARO DE LA ISLA',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF16211B),
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          Text('EDICIÓN ${state.newspaperAct - 1} · DÍA ${state.daysInPower}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF16211B))),
          const Divider(),
          for (final headline in IslandChronicle.newspaper(state))
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(headline,
                    style: const TextStyle(
                        color: Color(0xFF16211B), fontSize: 18, height: 1.5))),
          const Divider(),
          Text(repository.campaignActTitle(state.campaignIndex),
              style: const TextStyle(color: Color(0xFF16211B))),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: () =>
                  ref.read(gameControllerProvider.notifier).dismissNewspaper(),
              child: const Text('CONTINUAR LA HISTORIA')),
        ])));
  }
}
