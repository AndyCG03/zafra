import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_mode.dart';
import '../../domain/game_engine/game_controller.dart';

class RelationshipsScreen extends ConsumerWidget {
  const RelationshipsScreen({super.key});
  static const expectations = {
    'la_lider_vecinal':
        'Espera agua accesible, reuniones públicas y protección para los barrios.',
    'el_general':
        'Busca estabilidad y respaldo para su brigada. Sus privilegios pueden chocar con tu promesa civil.',
    'la_cantinera':
        'Quiere proteger a su familia y a quienes cuentan lo que sucede en el puerto.',
    'la_economista':
        'Busca sostener la cosecha y las cuentas sin agotar las reservas.',
    'el_diplomatico':
        'Espera acuerdos comerciales y garantías que puedan cumplirse.',
    'la_periodista': 'Espera pruebas verificables y una respuesta pública.',
  };
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider).gameState;
    final repo = ref.watch(cardRepositoryProvider);
    final characters = repo.allCharacters
        .where((c) =>
            state.unlockedCharacterIds.contains(c.id) ||
            state.characterTrust.containsKey(c.id))
        .toList();
    return Scaffold(
        appBar: AppBar(title: const Text('RELACIONES')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text(
              'La confianza va de −5 a +5. Desde +3 hay confianza; desde −3, rivalidad. Las expectativas describen sus intereses, no una misión obligatoria.'),
          if (characters.isEmpty)
            const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                    'Conocerás a tus interlocutores al tomar decisiones.')),
          for (final c in characters)
            Card(
                child: ExpansionTile(
                    leading:
                        CircleAvatar(backgroundImage: AssetImage(c.imageAsset)),
                    title: Text(c.name),
                    subtitle: Text(
                        '${trustLabel(state.characterTrust[c.id] ?? 0)} · ${state.characterTrust[c.id] ?? 0}/5'),
                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                  Text(expectations[c.id] ?? c.bio ?? c.role),
                  if ((c.id == 'la_lider_vecinal' &&
                          state.promise == GovernmentPromise.water) ||
                      (c.id == 'el_general' &&
                          state.promise == GovernmentPromise.civilian) ||
                      (c.id == 'el_diplomatico' &&
                          state.promise == GovernmentPromise.sovereignty))
                    Text(
                        'Tu compromiso: ${state.promise!.label} · ${switch (state.promiseStatus) {
                      PromiseStatus.fulfilled => 'Cumplido',
                      PromiseStatus.broken => 'Roto',
                      _ => 'Pendiente',
                    }}'),
                  if (c.id == 'la_cantinera' &&
                      state.flags.contains('aprendices_puerto'))
                    const Text(
                        'Acuerdo cumplido: financiaste aprendices sin impedir que su hija saliera de la isla.'),
                  if (c.id == 'la_cantinera' &&
                      state.flags.contains('beca_hija'))
                    const Text(
                        'Acuerdo cumplido: financiaste una beca para su hija fuera de la isla.'),
                  if (c.id == 'la_lider_vecinal')
                    Text(state.flags.contains('lider_pacto')
                        ? 'Acuerdo: pacto público con los barrios firmado.'
                        : 'Acuerdo: todavía no hay un pacto público con los barrios.'),
                  if (c.id == 'el_general')
                    Text(state.flags.contains('general_privilegios')
                        ? 'Acuerdo: concediste excepciones a sus auditorías.'
                        : state.flags.contains('general_auditado')
                            ? 'Acuerdo: sometiste sus cuentas a auditoría.'
                            : 'No hay acuerdo de auditoría registrado.'),
                  if (c.id == 'el_general' &&
                      state.flags.contains('general_retiro_apoyo'))
                    const Text('Ruptura: retiró su apoyo al gobierno.'),
                  const SizedBox(height: 10),
                  const Text('TUS DECISIONES CON ESTE PERSONAJE',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  for (final record in state.history
                      .where(
                          (r) => repo.cardById(r.cardId)?.characterId == c.id)
                      .toList()
                      .reversed
                      .take(4))
                    ListTile(
                        title: Text(record.choice),
                        subtitle: Text(
                            'Decisión ${record.turn}${record.notes.isEmpty ? '' : ' · ${record.notes.join(' ')}'}')),
                ])),
        ]));
  }
}
