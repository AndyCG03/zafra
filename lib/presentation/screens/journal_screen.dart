import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/game_engine/game_controller.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider).gameState;
    final records = state.history.reversed.toList();
    const evidence = {
      'pista_escolta': 'Autorización de la escolta',
      'pista_contrato': 'Cláusula de compensación',
      'pista_barco': 'Nombre del barco',
      'sello_judicial': 'Orden judicial de inspección',
      'prueba_desvio_escolta': 'Cadena de pruebas: depósito de la escolta',
      'prueba_desvio_contrato': 'Cadena de pruebas: compensación del operador',
      'misterio_incierto': 'Expediente publicado sin pruebas suficientes',
      'misterio_encubierto': 'Expediente reservado',
      'misterio_reparado': 'Archivo abierto y reparación aprobada',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('CRÓNICA DE LA ISLA')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (state.flags.any(evidence.containsKey)) ...[
          const Text('EXPEDIENTE DE LA COSECHA',
              style: TextStyle(fontWeight: FontWeight.bold)),
          for (final entry
              in evidence.entries.where((e) => state.flags.contains(e.key)))
            ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(entry.value)),
          const Divider(),
        ],
        const Text('TUS ÚLTIMAS 60 DECISIONES',
            style: TextStyle(fontWeight: FontWeight.bold)),
        if (records.isEmpty)
          const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Tu gobierno aún no ha tomado su primera decisión.')),
        for (final record in records)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DECISIÓN ${record.turn}',
                            style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 8),
                        Text(record.scene),
                        const SizedBox(height: 10),
                        Text('Elegiste: ${record.choice}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        for (final note in record.notes)
                          Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(note)),
                      ]))),
      ]),
    );
  }
}
