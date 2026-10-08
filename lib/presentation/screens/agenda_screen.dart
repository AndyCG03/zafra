import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/era.dart';
import '../../data/models/game_mode.dart';
import '../../domain/game_engine/game_controller.dart';
import 'journal_screen.dart';
import 'island_screen.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider).gameState;
    final repository = ref.watch(cardRepositoryProvider);
    final pending = [...state.pendingConsequences]
      ..sort((a, b) => a.dueTurn.compareTo(b.dueTurn));
    final allies = state.characterTrust.entries
        .where((e) => e.value != 0)
        .toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    return Scaffold(
      appBar: AppBar(title: const Text('AGENDA')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        OutlinedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const IslandScreen())),
            icon: const Icon(Icons.map_outlined),
            label: const Text('VER LA ISLA')),
        Text(state.mode.label.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        if (state.mode == GameMode.campaign) ...[
          Text(repository.campaignActTitle(state.campaignIndex)),
          Text(
              '${state.campaignIndex} de ${repository.campaignCardIds.length} escenas completadas'),
          const SizedBox(height: 12),
        ],
        if (state.promise != null)
          Card(
              child: ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(state.promise!.label),
            subtitle: Text(switch (state.promiseStatus) {
              PromiseStatus.fulfilled => 'Promesa cumplida',
              PromiseStatus.broken => 'Promesa incumplida',
              _ => 'Promesa pendiente: ${state.promise!.description}',
            }),
          )),
        OutlinedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const JournalScreen())),
            icon: const Icon(Icons.history_edu),
            label: const Text('CRÓNICA Y PRUEBAS')),
        const SizedBox(height: 12),
        Text(
            state.mode == GameMode.campaign
                ? 'Tu historia avanza en seis actos. Las decisiones de cada capítulo cambian los diálogos, los aliados y las pruebas de los siguientes.'
                : 'Las decisiones dejan compromisos. Estos asuntos volverán cuando llegue su momento; las crisis en curso pueden retrasarlos.',
            style: const TextStyle(height: 1.5)),
        const SizedBox(height: 20),
        if (pending.isEmpty)
          Text(state.mode == GameMode.campaign
              ? 'Cada escena recupera las decisiones de los capítulos anteriores.'
              : 'No hay compromisos pendientes.'),
        for (final entry in pending)
          Builder(builder: (context) {
            final card = repository.cardById(entry.cardId);
            final era =
                Era.values.where((e) => e.name == card?.eraId).firstOrNull;
            final remaining = entry.dueTurn - state.turn;
            final status = era != null && era.index > state.currentEra.index
                ? 'A partir de la era ${era.label}'
                : remaining > 0
                    ? remaining == 1
                        ? 'Después de una decisión como mínimo'
                        : 'Dentro de $remaining decisiones como mínimo'
                    : 'Pendiente de audiencia';
            return Card(
                child: ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: Text(entry.title),
              subtitle: Text(status),
              contentPadding: const EdgeInsets.all(16),
            ));
          }),
        if (allies.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('CONFIANZA Y RIVALIDADES',
              style: TextStyle(fontWeight: FontWeight.bold)),
          for (final ally in allies)
            ListTile(
              title: Text(repository.characterById(ally.key)?.name ??
                  'Representante de la isla'),
              subtitle: Text(
                  '${trustLabel(ally.value)} · ${ally.value > 0 ? '+' : ''}${ally.value}'),
            ),
        ],
        if (state.assassinationCountdown != null)
          Card(
              child: ListTile(
            leading: const Icon(Icons.warning_amber),
            title: const Text('Tu seguridad está en riesgo'),
            subtitle: Text(
                'Quedan ${state.assassinationCountdown} decisiones. Refuerza la escolta cuando el Guardaespaldas te lo proponga.'),
          )),
      ]),
    );
  }
}
