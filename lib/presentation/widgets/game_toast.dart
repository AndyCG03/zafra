import 'package:flutter/material.dart';
import '../../services/audio/game_audio.dart'; // Ajusta la ruta según tu proyecto

class GameToast {
  static GlobalKey<ScaffoldMessengerState>? _scaffoldKey;

  static void init(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldKey = key;
  }

  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
    bool playSound = true, // ✅ Nuevo parámetro
  }) {
    // ✅ Reproducir sonido de notificación
    if (playSound) {
      GameAudio.instance.notification();
    }

    final messenger = _scaffoldKey?.currentState ?? ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        _buildSnackBar(message, duration, icon),
      );
  }

  static SnackBar _buildSnackBar(String message, Duration duration, IconData? icon) {
    return SnackBar(
      content: _ToastContent(message: message, icon: icon),
      behavior: SnackBarBehavior.floating,
      duration: duration,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      padding: EdgeInsets.zero,
    );
  }
}

/// Widget interno del toast con estilo Zafra
class _ToastContent extends StatelessWidget {
  const _ToastContent({
    required this.message,
    this.icon,
  });

  final String message;
  final IconData? icon;

  static const _ink = Color(0xFF16211B);
  static const _accent = Color(0xFFC79A3E);
  static const _cream = Color(0xFFFFF8E7);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _accent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: _accent,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: _cream,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}