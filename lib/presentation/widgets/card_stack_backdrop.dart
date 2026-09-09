import 'package:flutter/material.dart';

class CardStackBackdrop extends StatelessWidget {
  const CardStackBackdrop({super.key});

  static const _cardColor = Color(0xFF1F2E26);
  static const _borderColor = Color(0x33C79A3E);
  static const _iconColor = Color(0x66C79A3E);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        final reducedSize = Size(
          size.width * 0.97,
          size.height * 0.97,
        );

        return Stack(
          alignment: Alignment.center,
          children: [
            // Logo de Zafra en fondo (más transparente)
            const IgnorePointer(
              child: Opacity(
                opacity: 0.12,
                child: Image(
                  image: AssetImage('assets/images/logo/icon simply.png'),
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Tercera carta del mazo (la más al fondo)
            Transform.translate(
              offset: const Offset(0, 8),
              child: _backCard(size: reducedSize),
            ),
            // Segunda carta del mazo (intermedia), con el logo
            Transform.translate(
              offset: const Offset(0, 4),
              child: _backCard(size: reducedSize, showIcon: true),
            ),
          ],
        );
      },
    );
  }

  Widget _backCard({required Size size, bool showIcon = false}) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: showIcon
          ? Center(
        child: Opacity(
          opacity: 0.25,
          child: Image.asset(
            'assets/images/logo/icon card.png',
            width: 90,
            height: 90,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.style_rounded,
              color: _iconColor,
              size: 42,
            ),
          ),
        ),
      )
          : null,
    );
  }
}