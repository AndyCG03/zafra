import 'package:flutter/material.dart';

/// Paleta y tema centralizados. Ver docs/DISEÑO_JUEGO.md para la
/// paleta sugerida por era (esto es solo el tema base de la UI general).
class AppTheme {
  static const Color background = Color(0xFF121E16);
  static const Color surface = Color(0xFF1F2E26);
  static const Color accent = Color(0xFFCB9840); // dorado/caña
  static const Color danger = Color(0xFFB6402A);
  static const Color success = Color(0xFF3C7A5B);
  static const Color container = Color(0xFFEAE1D3);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
        error: danger,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 18, height: 1.3),
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      useMaterial3: true,
    );
  }
}
