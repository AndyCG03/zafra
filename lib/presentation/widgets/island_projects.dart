import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/game_engine/game_controller.dart';
import '../../domain/game_engine/island_chronicle.dart';

class IslandProjects extends ConsumerWidget {
  const IslandProjects({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final state = game.gameState;
    final project = state.project;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PROYECTOS DE LA ISLA',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${state.projectsCompleted} proyectos completados'),
              if (project != null) ...[
                Text(project.label),
                Text(project.description),
                LinearProgressIndicator(value: state.projectProgress / 4),
                Text(
                    '${state.projectProgress}/4 avances · ${state.projectDeadline - state.turn} decisiones restantes'),
              ] else if (state.turn >= state.nextProjectTurn &&
                  game.ending == null) ...[
                const Text(
                    'Elige un proyecto. Dispones de diez decisiones para lograr cuatro avances. No consume un turno. Completarlo acerca los indicadores tres puntos al equilibrio; vencer el plazo no elimina tu partida.'),
                for (final p in IslandProject.values)
                  ListTile(
                      title: Text(p.label),
                      subtitle: Text(p.description),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => ref
                          .read(gameControllerProvider.notifier)
                          .selectProject(p)),
              ] else
                Text(
                    'Próxima convocatoria dentro de ${(state.nextProjectTurn - state.turn).clamp(0, 100000)} decisiones.'),
              const Text(
                  'Tras terminar un proyecto habrá seis decisiones de descanso antes de la siguiente convocatoria.'),
            ])));
  }
}
