import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ending.dart';
import '../../domain/game_engine/game_controller.dart';

/// Pantalla de fin de partida, con la misma identidad visual del resto
/// de la app: bloques verde oscuro arriba/abajo, cuerpo en tono piedra,
/// tipografía monoespaciada, acento dorado.
class EndingScreen extends ConsumerStatefulWidget {
  const EndingScreen({super.key, required this.ending});

  final Ending ending;

  @override
  ConsumerState<EndingScreen> createState() => _EndingScreenState();
}

class _EndingScreenState extends ConsumerState<EndingScreen>
    with SingleTickerProviderStateMixin {
  static const _ink = Color(0xFF16211B);
  static const _body = Color(0xFFEAE1D3);
  static const _accent = Color(0xFFC79A3E);
  static const _cream = Color(0xFFFFF8E7);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _rise = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ending = widget.ending;

    return Scaffold(
      backgroundColor: _body,
      body: Column(
        children: [
          // ---- Bloque superior
          Expanded(
            flex: 18,
            child: Container(
              width: double.infinity,
              color: _ink,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.flag_circle_rounded, color: _accent, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'FIN DEL GOBIERNO',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: _accent,
                      fontSize: 12,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---- Cuerpo: centrado verticalmente
          Expanded(
            flex: 62,
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _rise,
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ✅ Imagen del ending
                          Container(
                            width: double.infinity,
                            height: 200,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: _ink.withOpacity(0.08),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                ending.imageAsset,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                                errorBuilder: (_, __, ___) => Container(
                                  color: _ink.withOpacity(0.15),
                                  child: const Icon(
                                    Icons.broken_image_rounded,
                                    color: _accent,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // ✅ Título
                          Text(
                            ending.title.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: _ink,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // ✅ Línea decorativa
                          Container(
                            width: 50,
                            height: 2,
                            color: _accent,
                          ),
                          const SizedBox(height: 14),
                          // ✅ Descripción
                          Text(
                            ending.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: _ink,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ---- Bloque inferior: botón de reinicio
          Expanded(
            flex: 20,
            child: Container(
              width: double.infinity,
              color: _ink,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: _RestartButton(
                  onPressed: () =>
                      ref.read(gameControllerProvider.notifier).restart(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestartButton extends StatelessWidget {
  const _RestartButton({required this.onPressed});
  final VoidCallback onPressed;

  static const _accent = Color(0xFFC79A3E);
  static const _ink = Color(0xFF16211B);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'JUGAR DE NUEVO',
            style: TextStyle(
              fontFamily: 'monospace',
              color: _ink,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}