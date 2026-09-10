/// Las eras narrativas del juego. Cada una tiene su propio archivo
/// JSON de cartas en assets/cards/ y puede tener reglas especiales
/// (ver docs/DISEÑO_JUEGO.md, sección "Estructura narrativa temporal").
///
/// IMPORTANTE: el orden de este enum define el orden de progresión.
/// GameController avanza a la siguiente era cuando la actual se queda
/// sin cartas nuevas por mostrar (ver game_controller.dart).
enum Era {
  fundacional,
  consolidacion,
  crisis,
  apertura,
  contemporanea,
  futurista,
}

extension EraAssets on Era {
  String get cardsFileName {
    switch (this) {
      case Era.fundacional:
        return 'era_fundacional.json';
      case Era.consolidacion:
        return 'era_consolidacion.json';
      case Era.crisis:
        return 'era_crisis.json';
      case Era.apertura:
        return 'era_apertura.json';
      case Era.contemporanea:
        return 'era_contemporanea.json';
      case Era.futurista:
        return 'era_futurista.json';
    }
  }

  String get label {
    switch (this) {
      case Era.fundacional:
        return 'Era Fundacional';
      case Era.consolidacion:
        return 'Era de Consolidación';
      case Era.crisis:
        return 'Era de Crisis';
      case Era.apertura:
        return 'Era de Apertura';
      case Era.contemporanea:
        return 'Era Contemporánea';
      case Era.futurista:
        return 'Era Futurista';
    }
  }

  /// Siguiente era en la progresión, o null si ya es la última.
  Era? get next {
    final values = Era.values;
    final currentIndex = values.indexOf(this);
    if (currentIndex == values.length - 1) return null;
    return values[currentIndex + 1];
  }

  bool get isLast => this == Era.values.last;

  /// Turno a partir del cual esta etapa entra al mazo.
  int get unlockAtTurn {
    switch (this) {
      case Era.fundacional: return 0;
      case Era.consolidacion: return 12;
      case Era.crisis: return 26;
      case Era.apertura: return 42;
      case Era.contemporanea: return 60;
      case Era.futurista: return 78;
    }
  }
}