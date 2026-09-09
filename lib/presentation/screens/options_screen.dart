import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/audio/game_audio.dart';
import '../../services/persistence/progress_service.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});
  @override State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  double _music = .12;
  double _effects = .8;
  bool _haptics = true;
  bool _notifications = true;
  final _progress = ProgressService();

  @override
  void initState() {
    super.initState();
    _progress.init().then((_) {
      if (!mounted) return;
      setState(() {
        _music = _progress.ambientVolume;
        _effects = _progress.effectsVolume;
        _haptics = _progress.hapticsEnabled;
        _notifications = _progress.characterNotificationsEnabled;
      });
      GameAudio.instance.ambientVolume = _music;
      GameAudio.instance.effectsVolume = _effects;
      GameAudio.instance.setAmbientLevel(_music);
      GameAudio.instance.setEffectsLevel(_effects);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.container,
    appBar: AppBar(
      title: const Text('OPCIONES', style: TextStyle(fontFamily: 'monospace', letterSpacing: 2, fontWeight: FontWeight.bold)),
      backgroundColor: AppTheme.background,
      foregroundColor: AppTheme.accent,
      elevation: 0,
      centerTitle: true,
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('PREFERENCIAS DEL GOBIERNO', style: TextStyle(fontFamily: 'monospace', color: AppTheme.background, letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 18),
        _VolumeRow(
          label: 'VOLUMEN MÚSICA',
          value: _music,
          onChanged: (value) {
            setState(() => _music = value);
            GameAudio.instance.ambientVolume = value;
            GameAudio.instance.setAmbientLevel(value);
            _progress.setAmbientVolume(value);
          },
          onChangeEnd: (value) {
            GameAudio.instance.click(); // ✅ Suena SOLO al soltar
          },
        ),
        const SizedBox(height: 8),
        _VolumeRow(
          label: 'VOLUMEN EFECTOS',
          value: _effects,
          onChanged: (value) {
            setState(() => _effects = value);
            GameAudio.instance.effectsVolume = value;
            GameAudio.instance.setEffectsLevel(value);
            _progress.setEffectsVolume(value);
          },
          onChangeEnd: (value) {
            GameAudio.instance.click(); // ✅ Suena SOLO al soltar
          },
        ),
        const SizedBox(height: 8),
        _SwitchRow(
          title: 'VIBRACIÓN',
          value: _haptics,
          onChanged: (value) {
            GameAudio.instance.click();
            setState(() => _haptics = value);
            GameAudio.instance.hapticsEnabled = value;
            _progress.setHapticsEnabled(value);
          },
        ),
        _SwitchRow(
          title: 'AVISOS DE NUEVOS PERSONAJES',
          value: _notifications,
          onChanged: (value) {
            GameAudio.instance.click();
            setState(() => _notifications = value);
            _progress.setCharacterNotificationsEnabled(value);
          },
        ),
        const SizedBox(height: 20),
        _HelpTile(),
      ],
    ),
  );
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white54,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.background.withOpacity(.1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'monospace', color: AppTheme.background, fontSize: 12, fontWeight: FontWeight.bold)),
        Slider(
          value: value,
          min: 0,
          max: 1,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd, // ✅ Solo suena al soltar el slider
          activeColor: AppTheme.accent,
          inactiveColor: AppTheme.background.withOpacity(.2),
        ),
      ],
    ),
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.value, required this.onChanged});
  final String title; final bool value; final ValueChanged<bool> onChanged;

  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white54,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.background.withOpacity(.1)),
    ),
    child: SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontFamily: 'monospace', color: AppTheme.background, fontSize: 13, fontWeight: FontWeight.w600)),
      value: value,
      activeColor: AppTheme.accent,
      activeTrackColor: AppTheme.accent.withOpacity(.3),
      onChanged: onChanged,
    ),
  );
}

/// ✅ NUEVO: Widget de Ayuda / Acerca de con estilo consistente
class _HelpTile extends StatelessWidget {
  const _HelpTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.background.withOpacity(.1)),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.info_outline_rounded,
          color: AppTheme.accent,
        ),
        title: const Text(
          'AYUDA / ACERCA DE',
          style: TextStyle(
            fontFamily: 'monospace',
            color: AppTheme.background,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.background,
          size: 20,
        ),
        onTap: () {
          GameAudio.instance.click();
          _showAboutDialog(context);
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.accent.withOpacity(0.4), width: 1.5),
        ),
        title: Column(
          children: [
            Image.asset(
              'assets/images/logo/icon card.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.eco_rounded,
                color: AppTheme.accent,
                size: 42,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ZAFRA',
              style: TextStyle(
                fontFamily: 'monospace',
                color: AppTheme.accent,
                fontSize: 22,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Versión 0.1.0',
              style: TextStyle(
                fontFamily: 'monospace',
                color: AppTheme.container,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Toma el gobierno de una isla que acaba de salir de una crisis. '
                  'Las instituciones están frágiles, las reservas son escasas y '
                  'cada decisión tendrá un precio.',
              style: TextStyle(
                fontFamily: 'monospace',
                color: AppTheme.container,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Equilibra al pueblo, la economía, las relaciones exteriores y el '
                  'aparato del Estado para mantenerte en el poder. Cada carta que '
                  'deslices cambiará el rumbo de la isla.',
              style: TextStyle(
                fontFamily: 'monospace',
                color: AppTheme.container,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.accent.withOpacity(0.15),
                  width: 0.8,
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cada decisión deja cosecha.',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () {
              GameAudio.instance.click();
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'ENTENDIDO',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}