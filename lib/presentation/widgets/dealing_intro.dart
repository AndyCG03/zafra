import 'package:flutter/material.dart';
import '../../services/audio/game_audio.dart';

/// Se reproduce UNA VEZ, justo cuando la pantalla de carga termina y
/// aparece la primera carta: simula que 3 cartas "se reparten" desde
/// un mazo (ícono central) hacia la posición final de la carta,
/// entrando escalonadas con fade + slide + scale.
///
/// Al terminar, llama a [onComplete] para que el padre muestre el
/// contenido real (CardStackBackdrop + SwipeableCard).
class DealingIntro extends StatefulWidget {
  const DealingIntro({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<DealingIntro> createState() => _DealingIntroState();
}

class _DealingIntroState extends State<DealingIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  static const _cardColor = Color(0xFF1F2E26);
  static const _accent = Color(0xFFC79A3E);

  @override
  void initState() {
    super.initState();

    // ✅ Reproducir sonido de repartir cartas al inicio
    GameAudio.instance.dealCards();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // ✅ Cuando termina la animación, suena el sonido de "poner carta"
        GameAudio.instance.cardReturn();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Cada una de las 3 cartas repartidas tiene su propio intervalo,
  /// para que entren de forma escalonada (dealing clásico de naipes).
  Animation<double> _slot(int index) {
    final start = index * 0.09;
    final end = (start + 0.32).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Logo de Zafra en el centro, se desvanece a medida que se reparten las cartas
            Opacity(
              opacity: (1 - _controller.value).clamp(0.0, 1.0),
              child: Image.asset(
                'assets/images/logo/icon card.png',
                width: 56,
                height: 56,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.style_rounded,
                  color: _accent,
                  size: 48,
                ),
              ),
            ),
            // ✅ Cambiado de 8 a 6 cartas
            for (var i = 0; i < 6; i++) _dealtCard(i),
          ],
        );
      },
    );
  }

  Widget _dealtCard(int index) {
    final anim = _slot(index);
    final depth = 5 - index; // ✅ Cambiar de 7 a 5 porque ahora son 6 cartas
    final depthOffset = depth * 3.0;
    final depthScale = 1.0 - depth * 0.012;

    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final entrance = anim.value;
        return Opacity(
          opacity: entrance,
          child: Transform.translate(
            offset: Offset(0, depthOffset + (1 - entrance) * 60),
            child: Transform.scale(
              scale: depthScale * (0.85 + 0.15 * entrance),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _accent.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.15,
                    child: Image.asset(
                      'assets/images/logo/icon card.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.style_rounded,
                        color: _accent,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}