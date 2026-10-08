import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_mode.dart';
import '../../domain/game_engine/game_controller.dart';
import 'game_screen.dart';

class ModesScreen extends ConsumerStatefulWidget {
  const ModesScreen({super.key});
  @override
  ConsumerState<ModesScreen> createState() => _ModesScreenState();
}

class _ModesScreenState extends ConsumerState<ModesScreen> {
  GameMode _mode = GameMode.campaign;
  GovernmentPromise _promise = GovernmentPromise.water;
  bool _busy = false;
  Future<void> _play(bool resume) async {
    final controller = ref.read(gameControllerProvider.notifier);
    if (!resume && controller.savedMode(_mode) != null) {
      final replace = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
                title: Text('¿Nueva partida de ${_mode.label.toLowerCase()}?'),
                content: const Text(
                    'Se reemplazará el guardado de este modo. La partida del otro modo se conserva.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('CANCELAR')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('NUEVA PARTIDA'))
                ],
              ));
      if (replace != true || !mounted) return;
    }
    setState(() => _busy = true);
    if (resume) {
      await controller.resumeMode(_mode);
    } else {
      await controller.startNewGame(_mode, _promise);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (ref.read(gameControllerProvider).loadError != null) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    final saved = ref.read(gameControllerProvider.notifier).savedMode(_mode);
    final canResume = saved != null && saved['ending'] == null;
    return Scaffold(
      appBar: AppBar(title: const Text('MODOS DE JUEGO')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        for (final mode in [GameMode.campaign, GameMode.endless])
          Card(
              color: _mode == mode ? const Color(0xFF354434) : null,
              child: ListTile(
                  selected: _mode == mode,
                  selectedColor: const Color(0xFFFFF8E7),
                  leading: Icon(mode == GameMode.campaign
                      ? Icons.auto_stories
                      : Icons.all_inclusive),
                  title: Text(mode.label.toUpperCase()),
                  subtitle: Text(mode.description),
                  trailing: Icon(_mode == mode
                      ? Icons.check_circle
                      : Icons.circle_outlined),
                  onTap: _busy ? null : () => setState(() => _mode = mode))),
        const SizedBox(height: 20),
        const Text('TU PROMESA DE GOBIERNO',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
            'Elige una prioridad para una partida nueva. La agenda mostrará si la cumples o la rompes.'),
        for (final promise in GovernmentPromise.values)
          ListTile(
              title: Text(promise.label),
              subtitle: Text(promise.description),
              leading: Icon(_promise == promise
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
              onTap: _busy ? null : () => setState(() => _promise = promise)),
        if (canResume)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilledButton.icon(
                  onPressed: _busy ? null : () => _play(true),
                  icon: const Icon(Icons.play_arrow),
                  label: Text('CONTINUAR ${_mode.label.toUpperCase()}'))),
        OutlinedButton(
            onPressed: _busy || game.isLoading ? null : () => _play(false),
            child: Text(_busy
                ? 'PREPARANDO LA ISLA…'
                : 'INICIAR ${_mode.label.toUpperCase()}')),
        if (game.loadError != null)
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(game.loadError!,
                  style: const TextStyle(color: Colors.orangeAccent))),
      ]),
    );
  }
}
