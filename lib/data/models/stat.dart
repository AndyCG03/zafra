/// Las cuatro estadísticas centrales del juego.
///
/// Cada partida se pierde cuando alguna estadística llega a [Stat.min]
/// o a [Stat.max]. El diseño de cartas debe mantenerlas, en promedio,
/// dentro del rango "seguro" (ver docs/DISEÑO_JUEGO.md).
enum StatType {
  pueblo,
  economia,
  relacionesExteriores,
  aparatoDelEstado,
}

extension StatTypeLabel on StatType {
  String get label {
    switch (this) {
      case StatType.pueblo:
        return 'Pueblo';
      case StatType.economia:
        return 'Economía';
      case StatType.relacionesExteriores:
        return 'Relaciones Exteriores';
      case StatType.aparatoDelEstado:
        return 'Aparato del Estado';
    }
  }
}

/// Valor de una estadística, siempre acotado entre [min] y [max].
class Stat {
  static const int min = 0;
  static const int max = 100;
  static const int initial = 50;

  final StatType type;
  final int value;

  const Stat(this.type, this.value);

  Stat copyWithDelta(int delta) {
    final newValue = (value + delta).clamp(min, max);
    return Stat(type, newValue);
  }

  bool get isAtMin => value <= min;
  bool get isAtMax => value >= max;
  bool get isCollapsed => isAtMin || isAtMax;

  /// Zona de peligro para dar feedback visual/narrativo progresivo.
  bool get isInDanger => value <= 15 || value >= 85;
}
