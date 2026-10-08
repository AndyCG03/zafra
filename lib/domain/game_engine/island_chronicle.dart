import '../../data/models/game_card.dart';
import '../../data/models/decision_record.dart';
import '../../data/models/game_mode.dart';
import '../../data/models/stat.dart';
import 'game_state.dart';

/// Escenas opcionales que sustituyen una audiencia cotidiana del acto.
class IslandChronicle {
  static GameCard route(String id, String character, String text, String left,
          String right, String flag,
          {String era = 'fundacional'}) =>
      GameCard(
        id: id,
        characterId: character,
        eraId: era,
        text: text,
        storyArc: 'rutas',
        drawFromDeck: false,
        left: CardOption(
            text: left,
            effects: const {StatType.economia: -2, StatType.pueblo: 2},
            setFlags: ['${flag}_publico'],
            trustChanges: {character: 1}),
        right: CardOption(
            text: right,
            effects: const {StatType.economia: 2, StatType.pueblo: -2},
            setFlags: ['${flag}_reservado'],
            trustChanges: {character: -1}),
      );
  static final routes = [
    route(
        'ruta_cooperativa',
        'la_lider_vecinal',
        'La cooperativa que elegiste abre el muelle. Dos barrios disputan el primer turno de carga; tu aliada pide un reparto público, aunque retrase la exportación.',
        'Financiar un turno compartido',
        'Dar prioridad al cargamento rentable',
        'ruta_muelle'),
    route(
        'ruta_acreedor',
        'el_diplomatico',
        'El operador exclusivo invita a una cena privada. Ofrece adelantar el pago si nadie publica las condiciones. La Cantinera ya está vendiendo entradas para la “cena del secreto”.',
        'Publicar el contrato y pagar la revisión',
        'Aceptar el adelanto reservado',
        'ruta_cena'),
    route(
        'ruta_rival',
        'el_general',
        'El General desconfía de ti y se niega a compartir su lista de escoltas. Un oficial joven ofrece declarar en una audiencia civil, si proteges a su familia.',
        'Proteger al oficial y abrir la audiencia',
        'Negociar la lista a puerta cerrada',
        'ruta_oficial',
        era: 'crisis'),
    route(
        'ruta_testigo',
        'la_cantinera',
        'Tus documentos permiten seguir la carga desviada. El testigo reconoce un almacén, pero teme perder su trabajo. La Cantinera exige que la verdad no cueste otra familia.',
        'Financiar su protección y publicar el testimonio',
        'Guardar su nombre y negociar la devolución',
        'ruta_testigo',
        era: 'contemporanea'),
  ];
  static String? routeId(GameState state, String baseId) {
    final f = state.flags;
    if (baseId == 'humor_sello') {
      if (f.contains('puerto_cooperativa')) return 'ruta_cooperativa';
      if (f.contains('puerto_exclusiva')) return 'ruta_acreedor';
    }
    if (baseId == 'humor_colas' &&
        (state.characterTrust['el_general'] ?? 0) <= -3) {
      return 'ruta_rival';
    }
    if (baseId == 'humor_estatua' &&
        (f.contains('prueba_desvio_escolta') ||
            f.contains('prueba_desvio_contrato'))) {
      return 'ruta_testigo';
    }
    return null;
  }

  static List<String> newspaper(GameState state) => [
        if (state.flags.contains('ruta_muelle_publico'))
          'Los barrios comparten el primer turno de carga: el pacto del muelle pasa su primera prueba.',
        if (state.flags.contains('ruta_muelle_reservado'))
          'La prioridad al cargamento rentable deja a los barrios esperando su turno.',
        if (state.flags.contains('ruta_cena_publico'))
          'La cena terminó con un contrato sobre la mesa de la plaza.',
        if (state.flags.contains('ruta_cena_reservado'))
          'El adelanto de la cena privada vuelve a abrir preguntas sobre las garantías.',
        if (state.flags.contains('ruta_oficial_publico'))
          'Un oficial declara ante los vecinos con protección para su familia.',
        if (state.flags.contains('ruta_oficial_reservado'))
          'La lista de escoltas se negocia sin audiencia pública.',
        if (state.flags.contains('ruta_testigo_publico'))
          'El testigo del almacén puede contar su historia sin quedar desprotegido.',
        if (state.flags.contains('ruta_testigo_reservado'))
          'Una devolución negociada conserva en reserva el nombre del testigo.',
        state.promiseStatus == PromiseStatus.fulfilled
            ? 'La promesa empieza a ser realidad: los barrios reclaman que dure.'
            : state.promiseStatus == PromiseStatus.broken
                ? 'La plaza pide explicaciones por la promesa rota.'
                : 'La isla sigue esperando resultados de tu promesa.',
        if (state.flags.contains('puerto_cooperativa'))
          'El muelle reparte sus llaves entre trabajadores.'
        else if (state.flags.contains('puerto_exclusiva'))
          'Un operador concentra las licencias del puerto.'
        else
          'El puerto busca un acuerdo para volver a trabajar.',
        if (state.flags.contains('prueba_desvio_escolta') ||
            state.flags.contains('prueba_desvio_contrato'))
          'La cosecha deja un rastro documental: ahora falta decidir quién responderá.'
        else
          'El almacén sigue lleno de preguntas sobre la cosecha.',
        'Radio de la Cantinera: “El gobierno afirma que tiene todo bajo control. Hemos encargado una mesa más grande para ese todo”.',
        state.statOf(StatType.pueblo).value < 30
            ? 'Vida cotidiana: los vecinos organizan una olla común mientras esperan respuestas.'
            : 'Vida cotidiana: la plaza recupera el concurso de dominó. Nadie acepta al ministro como árbitro.',
      ];

  static List<DecisionRecord> milestones(GameState state) {
    final ranked = [
      ...(state.definingDecisions.isEmpty
          ? state.history
          : state.definingDecisions)
    ]..sort((a, b) => importance(b).compareTo(importance(a)));
    return (ranked.take(3).toList()..sort((a, b) => a.turn.compareTo(b.turn)));
  }

  static int importance(DecisionRecord record) => record.importance;
  static List<String> hints(GameState state) => [
        if (!state.flags.contains('agua_local'))
          'Una comunidad capaz de decidir sobre sus servicios puede cambiar el legado.'
        else
          'La autonomía del agua necesita aliados también fuera de los barrios.',
        if (!state.flags.contains('misterio_revelado'))
          'Un expediente completo abre caminos que una sospecha sola no puede abrir.'
        else
          'Después de revelar la verdad, importa cómo reparas sus consecuencias.',
        'La forma de entregar el gobierno puede pesar tanto como el tiempo que permaneces en él.',
      ];
}

enum IslandProject {
  rebuild('Reconstruir los barrios',
      'Consigue cuatro decisiones que mejoren al Pueblo.', StatType.pueblo),
  trade('Resolver la huelga del ingenio',
      'Consigue cuatro decisiones que mejoren la Economía.', StatType.economia),
  succession(
      'Preparar una sucesión civil',
      'Consigue cuatro decisiones que favorezcan al Pueblo sin aumentar el aparato del Estado.',
      StatType.pueblo);

  final String label;
  final String description;
  final StatType stat;
  const IslandProject(this.label, this.description, this.stat);
  bool advances(Map<StatType, int> effects) =>
      (effects[stat] ?? 0) > 0 &&
      (this != IslandProject.succession ||
          (effects[StatType.aparatoDelEstado] ?? 0) <= 0);
}
