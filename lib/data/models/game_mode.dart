enum GameMode {
  endless('Ilimitado',
      'Gobierna sin límite de turnos. Las crisis y los asuntos de la isla siguen mientras resistas.'),
  campaign('Campaña',
      'Una historia de seis actos. Cada decisión cambia las relaciones, la investigación y el desenlace.');

  final String label;
  final String description;
  const GameMode(this.label, this.description);
}

enum PromiseStatus { pending, fulfilled, broken }

enum GovernmentPromise {
  water('Agua para todos', 'Construir una red común de agua.',
      'agua_legado_comun'),
  sovereignty(
      'Un puerto soberano',
      'Conservar las claves y el control del puerto.',
      'puerto_legado_autonomo'),
  civilian(
      'Un gobierno civil',
      'Abrir las decisiones a la isla sin militarizar el agua ni el muelle.',
      'gobierno_civil');

  final String label;
  final String description;
  final String fulfillmentFlag;
  const GovernmentPromise(this.label, this.description, this.fulfillmentFlag);
  PromiseStatus status(Set<String> flags) {
    final broken = switch (this) {
      GovernmentPromise.water => flags.contains('agua_legado_privado'),
      GovernmentPromise.sovereignty =>
        flags.contains('puerto_legado_dependiente'),
      GovernmentPromise.civilian => flags.contains('agua_control') ||
          flags.contains('puerto_militar') ||
          flags.contains('general_privilegios'),
    };
    if (broken) return PromiseStatus.broken;
    final fulfilled = this == GovernmentPromise.civilian
        ? flags.contains('agua_local') &&
            flags.contains('puerto_consulta') &&
            flags.contains('lider_pacto')
        : flags.contains(fulfillmentFlag);
    return fulfilled ? PromiseStatus.fulfilled : PromiseStatus.pending;
  }
}

String trustLabel(int value) => value >= 3
    ? 'Confianza'
    : value <= -3
        ? 'Rivalidad'
        : value < 0
            ? 'Recelo'
            : value > 0
                ? 'Cercanía'
                : 'Neutral';
