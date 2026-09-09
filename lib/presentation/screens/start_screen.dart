import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/game_engine/game_controller.dart';
import 'game_screen.dart';
import 'options_screen.dart';
import '../../services/audio/game_audio.dart';
import '../../services/persistence/progress_service.dart';

class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final hasPendingGame = !game.isLoading && game.currentCard != null && game.ending == null && game.gameState.turn > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;

            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                height: screenHeight,
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
                              height: 180,
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
                                      label: hasPendingGame ? 'CONTINUAR GOBIERNO' : 'COMENZAR GOBIERNO',
                                      icon: hasPendingGame ? Icons.play_circle_fill_rounded : Icons.play_arrow_rounded,
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const GameScreen()),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _MenuButton(
                                      label: 'OPCIONES',
                                      icon: Icons.tune_rounded,
                                      outlined: true,
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const OptionsScreen()),
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
                                    const SizedBox(height: 60),
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

Future<void> _showCreatorConversation(BuildContext context) async {
  final progress = ProgressService();
  await progress.init();
  final count = progress.gamesPlayed;
  List<dynamic> messages = [];
  try {
    final raw = await rootBundle.loadString('assets/cards/el_creador.json');
    messages = jsonDecode(raw) as List<dynamic>;
  } catch (_) {}
  final seen = progress.seenCreatorMessageIds;
  final eligible = <Map<String, dynamic>>[];
  for (var index = 0; index < messages.length; index++) {
    final item = messages[index];
    if (item is! Map) continue;
    final id = item['id']?.toString() ?? 'creador_$index';
    final minGames = (item['minGames'] as num?)?.toInt() ?? index;
    if (count >= minGames && !seen.contains(id)) {
      eligible.add({...item.cast<String, dynamic>(), 'id': id});
    }
  }
  if (eligible.isEmpty) return;
  final selected = eligible.first;
  final message = (selected['message'] ?? selected['text'] ?? '').toString();
  final messageId = selected['id'].toString();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialog) => AlertDialog(
      backgroundColor: AppTheme.container,
      title: const Text(
        'EL CREADOR',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'monospace',
          color: AppTheme.accent,
          letterSpacing: 1.5,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/characters/el_creador.png',
            height: 150,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.person,
              color: AppTheme.accent,
              size: 80,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () {
            GameAudio.instance.click();
            Navigator.pop(dialog);
          },
          child: const Text('CONTINUAR'),
        ),
      ],
    ),
  );
  await progress.markCreatorMessageSeen(messageId);
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