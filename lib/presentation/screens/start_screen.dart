import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/game_engine/game_controller.dart';
import 'game_screen.dart';
import 'options_screen.dart';
import 'modes_screen.dart';
import '../../services/audio/game_audio.dart';

class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final hasPendingGame =
        !game.isLoading && game.currentCard != null && game.ending == null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;

            return SingleChildScrollView(
              child: SizedBox(
                height: screenHeight < 560 ? 560 : screenHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo y título - ocupan la parte superior
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/logo/icon simply.png',
                              height: screenHeight < 560 ? 130 : 180,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.style_rounded,
                                color: AppTheme.accent,
                                size: 100,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'ZAFRA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.white,
                                fontSize: 34,
                                letterSpacing: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'El peso de gobernar una isla.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Color(0xFFEAE1D3),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Botones - con espacio extra abajo
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Contenedor centrado para botones del mismo ancho
                            Center(
                              child: SizedBox(
                                width: 280,
                                child: Column(
                                  children: [
                                    _MenuButton(
                                      label: hasPendingGame
                                          ? 'CONTINUAR GOBIERNO'
                                          : 'COMENZAR GOBIERNO',
                                      icon: hasPendingGame
                                          ? Icons.play_circle_fill_rounded
                                          : Icons.play_arrow_rounded,
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => hasPendingGame
                                                ? const GameScreen()
                                                : const ModesScreen()),
                                      ),
                                    ),
                                    if (hasPendingGame) ...[
                                      const SizedBox(height: 10),
                                      _MenuButton(
                                          label: 'ELEGIR MODO',
                                          icon: Icons.auto_stories,
                                          outlined: true,
                                          onPressed: () => Navigator.of(context)
                                              .push(MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ModesScreen()))),
                                    ],
                                    const SizedBox(height: 10),
                                    _MenuButton(
                                      label: 'OPCIONES',
                                      icon: Icons.tune_rounded,
                                      outlined: true,
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const OptionsScreen()),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'CADA DECISION DEJA COSECHA',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        color: AppTheme.accent,
                                        fontSize: 9,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    // ✅ MÁS ESPACIO ABAJO - Aumentado de 16 a 32
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 50,
        child: OutlinedButton.icon(
          onPressed: () {
            GameAudio.instance.click();
            onPressed();
          },
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: outlined ? AppTheme.accent : AppTheme.background,
            backgroundColor: outlined ? Colors.transparent : AppTheme.accent,
            side: const BorderSide(color: AppTheme.accent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      );
}
