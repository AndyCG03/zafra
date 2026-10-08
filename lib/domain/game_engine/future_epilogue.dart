import '../../data/models/ending.dart';
import 'game_state.dart';

class EpilogueEntry {
  final String title;
  final String text;
  final String? characterId;
  const EpilogueEntry(this.title, this.text, {this.characterId});
}

class FutureEpilogue {
  static List<EpilogueEntry> build(GameState state, Ending ending) {
    bool has(String flag) => state.flags.contains(flag);
    final collapsed = !ending.isStoryEnding && !ending.isSurvival;
    return [
      EpilogueEntry(
          'Los barrios',
          '${collapsed ? 'Después de la caída, los barrios tuvieron que reconstruir también los acuerdos del gobierno. ' : has('sucesion_perpetua') ? 'Cinco años después, palacio sigue esperando tu firma. ' : 'Cinco años después de tu salida, la isla volvió a discutir sus prioridades. '}${has('agua_legado_comun') && has('agua_local') ? 'Los consejos mantienen los depósitos comunes; cambiar de gobernante ya no detiene el reparto.' : has('agua_legado_privado') ? 'La red funciona, pero cada revisión de tarifas reúne a los vecinos frente al concesionario.' : has('agua_obra') ? 'La acequia reparada sigue en pie. Su mantenimiento continúa esperando un acuerdo duradero.' : 'Las familias todavía organizan turnos para el agua: las obras que quedaron pendientes no se terminaron solas.'} ${has('tramites_unificados') ? 'La oficina necesita una sola fila y el Vagabundo presume de haberla inventado.' : has('registro_provisional') ? 'El registro provisional cumplió cinco años. Nadie se atreve a cambiarle el nombre.' : ''}'),
      EpilogueEntry(
          'La Líder Vecinal',
          '${has('memoria_puente') ? 'La escuela conserva los testimonios del puente y ensaya cada año el protocolo que escribieron.' : has('mediacion_puente') ? 'La Líder y el General vuelven al mismo banco para revisar las rutas de evacuación. No se hicieron amigos: aprendieron a responder juntos.' : has('refugios_vecinales') ? 'La Líder abre la escuela cuando anuncian una tormenta. Las llaves del refugio siguen en el barrio.' : 'La marca de la inundación permanece en la pared de la escuela. La Líder sigue pidiendo que nadie vuelva a quedarse atrás.'} ${(state.characterTrust['la_lider_vecinal'] ?? 0) >= 3 ? 'Recuerda tu gobierno como un aliado al que hubo que exigirle cuentas.' : (state.characterTrust['la_lider_vecinal'] ?? 0) <= -3 ? 'Tus acuerdos se estudian en el barrio como advertencias, junto a sus promesas incumplidas.' : 'Su juicio sobre tu gobierno cambia según a qué vecino le pregunten.'}',
          characterId: 'la_lider_vecinal'),
      EpilogueEntry(
          'El General',
          has('general_privilegios')
              ? 'La excepción que concediste se convirtió en una costumbre. El General conserva respaldo, pero su brigada continúa negociando las auditorías del nuevo gobierno.'
              : has('general_relevo_civil')
                  ? 'Entregó las herramientas a los vecinos y dejó la llave de su madre junto al inventario. La antigua brigada es ahora un taller de reparación civil.'
                  : has('general_servicio_mixto')
                      ? 'El servicio mixto publica sus gastos y repara techos cuando hay temporal. La casa de su madre es una oficina de guardia, con una silla para civiles.'
                      : has('brigada_compartida')
                          ? 'La brigada compartida aún reúne a soldados y vecinos. El General conserva la llave de la casa que repararon juntos.'
                          : 'El General conserva la llave en el bolsillo. La próxima tormenta vuelve a abrir la discusión sobre quién protege a la isla y quién da las órdenes.',
          characterId: 'el_general'),
      EpilogueEntry(
          'La Cantinera',
          '${has('taller_retorno') ? 'Su hija regresó y comparte un taller con quienes aprendieron en el puerto. La mesa reservada quedó pequeña: ahora se sientan seis aprendices.' : has('intercambio_hija') ? 'Su hija vive entre dos puertos y envía piezas, cartas y malas bromas. La Cantinera las lee en la radio como si fueran decretos.' : has('beca_hija') ? 'La hija aprendió a reparar motores fuera de la isla. Sus cartas siguen llegando; la madre guarda una mesa sin exigirle que vuelva.' : has('aprendices_puerto') ? 'Los aprendices mantienen el taller abierto. La hija pregunta de nuevo cuándo podrá regresar; su madre guarda el billete para recordarle que siempre pudo elegir.' : 'La hija vive fuera de la isla. La Cantinera guarda sus cartas bajo la caja y dice que el océano es solo una calle demasiado larga.'} ${has('biblioteca_publica') ? 'Los sábados leen esas cartas en la biblioteca que elegiste construir.' : has('estatua_local') ? 'La estatua tiene un apodo nuevo cada semana. La Cantinera insiste en cobrar derechos de autor.' : ''}',
          characterId: 'la_cantinera'),
    ];
  }
}
