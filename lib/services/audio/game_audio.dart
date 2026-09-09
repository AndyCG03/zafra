import 'package:audioplayers/audioplayers.dart';

class GameAudio {
  GameAudio._();
  static final instance = GameAudio._();
  final _ambient = AudioPlayer();
  final _effects = AudioPlayer();
  final _dragPlayer = AudioPlayer();

  // ✅ Reproductor exclusivo para cardReturn
  final _cardReturnPlayer = AudioPlayer();

  bool soundEnabled = true;
  bool hapticsEnabled = true;
  double ambientVolume = .12;
  double effectsVolume = .8;
  bool _configured = false;
  bool _ambientStarted = false;

  // ✅ Control para evitar reproducción múltiple del drag
  bool _isDragPlaying = false;

  Future<void> stopAmbient() async { await _ambient.stop(); _ambientStarted = false; }
  Future<void> setAmbientLevel(double value) => _ambient.setVolume(value);
  Future<void> setEffectsLevel(double value) async {
    await _effects.setVolume(value);
    await _dragPlayer.setVolume(value);
    await _cardReturnPlayer.setVolume(value * 0.2);
  }
  Future<void> pauseAmbient() => _ambient.pause();
  Future<void> resumeAmbient() async {
    if (!soundEnabled) return;
    try { await _ambient.resume(); } catch (_) { await startAmbient(); }
  }

  Future<void> startAmbient() async {
    try {
      if (_ambientStarted) { await _ambient.setVolume(ambientVolume); return; }
      if (!_configured) {
        final context = AudioContext(
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
          android: AudioContextAndroid(audioFocus: AndroidAudioFocus.gainTransientMayDuck),
        );
        await _ambient.setAudioContext(context);
        await _effects.setAudioContext(context);
        await _dragPlayer.setAudioContext(context);
        await _cardReturnPlayer.setAudioContext(context);
        _configured = true;
      }
      await _ambient.setReleaseMode(ReleaseMode.loop);
      await _ambient.setVolume(ambientVolume);
      await _ambient.play(AssetSource('music/ambient music.mp3'), volume: ambientVolume);
      _ambientStarted = true;
    } catch (_) {}
  }

  // ✅ Sonido de repartir cartas
  Future<void> dealCards() async {
    if (!soundEnabled) return;
    try {
      await _effects.play(AssetSource('music/repartir cartas.mp3'), volume: effectsVolume);
    } catch (_) {}
  }

  // ✅ Iniciar arrastre (solo se reproduce UNA VEZ)
  Future<void> drag() async {
    if (!soundEnabled) return;
    if (_isDragPlaying) return;
    try {
      _isDragPlaying = true;
      await _dragPlayer.setReleaseMode(ReleaseMode.release);
      await _dragPlayer.play(AssetSource('music/al arrastrar.mp3'), volume: effectsVolume);
    } catch (_) {
      _isDragPlaying = false;
    }
  }

  // ✅ Detener arrastre
  Future<void> stopDrag() async {
    try {
      await _dragPlayer.stop();
    } catch (_) {}
    _isDragPlaying = false;
  }

  // ✅ Sonido de swipe (deslizar)
  Future<void> swipe() => _play('music/swipe card.mp3');

  // ✅ Sonido de soltar carta (volumen al 20%)
  Future<void> cardReturn() async {
    if (!soundEnabled) return;
    try {
      await _cardReturnPlayer.setVolume(effectsVolume * 0.2);
      await _cardReturnPlayer.play(AssetSource('music/put card.mp3'));
    } catch (_) {}
  }

  // ✅ NUEVO: Sonido de girar/voltear carta
  Future<void> cardFlip() async {
    if (!soundEnabled) return;
    try {
      await _effects.play(AssetSource('music/card_flip.mp3'), volume: effectsVolume);
    } catch (_) {}
  }

  // ✅ Sonido de nuevo personaje
  Future<void> newCharacter() => _play('music/nuevo personaje.mp3');

  // ✅ Sonido de click
  Future<void> click() => _play('music/click.mp3');

  // ✅ Sonido de notificación
  Future<void> notification() => _play('music/notification.mp3');

  Future<void> _play(String asset) async {
    if (!soundEnabled) return;
    try {
      await _effects.play(AssetSource(asset), volume: effectsVolume);
    } catch (_) {}
  }

  bool get isDragPlaying => _isDragPlaying;
}