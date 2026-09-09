import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/character.dart';
import '../../data/repositories/card_repository.dart';
import '../../domain/game_engine/game_controller.dart';
import '../../services/persistence/progress_service.dart';
import '../../services/audio/game_audio.dart';

/// Pantalla de galería: muestra TODOS los personajes del juego en una
/// grilla tipo mazo de cartas.
class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  static const _ink = Color(0xFF16211B);
  static const _accent = Color(0xFFC79A3E);
  static const _body = Color(0xFFEAE1D3);

  final ProgressService _progress = ProgressService();
  Set<String> _unlockedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _progress.init();
    await ref.read(cardRepositoryProvider).loadAll();
    final ids = _progress.unlockedCharacters;
    if (!mounted) return;
    setState(() {
      _unlockedIds = ids;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(cardRepositoryProvider);
    final characters = repository.allCharacters;

    return Scaffold(
      backgroundColor: _body,
      appBar: AppBar(
        backgroundColor: _ink,
        foregroundColor: _accent,
        title: const Text(
          'PERSONAJES',
          style: TextStyle(
            fontFamily: 'monospace',
            letterSpacing: 2,
            fontSize: 15,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_unlockedIds.length} / ${characters.length} DESCUBIERTOS',
              style: const TextStyle(
                fontFamily: 'monospace',
                color: _ink,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: characters.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) {
                  final character = characters[index];
                  final unlocked = _unlockedIds.contains(character.id);
                  return _FlipCharacterCard(
                    character: character,
                    unlocked: unlocked,
                    repository: repository,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una carta individual con animación de volteo (flip 3D en el eje Y).
class _FlipCharacterCard extends StatefulWidget {
  const _FlipCharacterCard({
    required this.character,
    required this.unlocked,
    required this.repository,
  });

  final Character character;
  final bool unlocked;
  final CardRepository repository;

  @override
  State<_FlipCharacterCard> createState() => _FlipCharacterCardState();
}

class _FlipCharacterCardState extends State<_FlipCharacterCard>
    with SingleTickerProviderStateMixin {
  static const _panelDark = Color(0xFF1F2E26);
  static const _accent = Color(0xFFC79A3E);
  static const _cream = Color(0xFFFFF8E7);

  late final AnimationController _controller;
  bool _showingBack = false;
  bool _flipSoundPlayed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(_onFlipProgress);
  }

  void _onFlipProgress() {
    // ✅ DEBUG: Imprimir el valor para ver si llega al rango
    // print('🔄 Flip progress: ${_controller.value}');

    // ✅ Reproducir sonido en el rango 0.3 - 0.7 (más amplio)
    if (_controller.value >= 0.3 && _controller.value <= 0.7 && !_flipSoundPlayed) {
      _flipSoundPlayed = true;
      debugPrint('🎵 Reproduciendo cardFlip() en value: ${_controller.value}');
      GameAudio.instance.cardFlip();
    }

    // ✅ Resetear cuando la animación termina
    if (_controller.value >= 0.99 || _controller.value <= 0.01) {
      if (_flipSoundPlayed) {
        debugPrint('🔄 Reset flip sound flag');
      }
      _flipSoundPlayed = false;
    }
  }

  void _toggle() {
    if (!widget.unlocked) return;

    debugPrint('🔄 Toggle carta: ${widget.character.name}');
    setState(() => _showingBack = !_showingBack);
    _flipSoundPlayed = false;

    if (_showingBack) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onFlipProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.unlocked) {
      return const _LockedCard();
    }

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * math.pi;
          final showFront = angle < math.pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            child: showFront
                ? _CardFront(
              character: widget.character,
              repository: widget.repository,
            )
                : Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(math.pi),
              child: _CardBack(character: widget.character),
            ),
          );
        },
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({
    required this.character,
    required this.repository,
  });

  final Character character;
  final CardRepository repository;

  static const _panelDark = Color(0xFF1F2E26);
  static const _accent = Color(0xFFC79A3E);
  static const _cream = Color(0xFFFFF8E7);

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
              child: Image.asset(
                repository.imageAssetForCharacter(character.id),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: _panelDark,
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo/icon card.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: _accent,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: _panelDark,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              character.name.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: _cream,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.character});
  final Character character;

  static const _panelDark = Color(0xFF1F2E26);
  static const _accent = Color(0xFFC79A3E);
  static const _cream = Color(0xFFFFF8E7);

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Container(
        width: double.infinity,
        color: _panelDark,
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.badge_rounded,
              color: _accent,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              character.name.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: _cream,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              character.role,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: _accent,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 30,
              height: 1,
              color: _accent.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  character.bio ?? _fallbackBio(character),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: _cream,
                    fontSize: 9.5,
                    height: 1.3,
                  ),
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fallbackBio(Character c) {
    return 'Voz de "${c.role}" dentro del gobierno. Sus decisiones influyen en cómo se equilibra esta parte del país.';
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  static const _accent = Color(0xFFC79A3E);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accent.withOpacity(0.6), width: 1.4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard();

  static const _panelDark = Color(0xFF1F2E26);
  static const _accent = Color(0x66C79A3E);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _panelDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accent, width: 1.2),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.55,
          child: Image.asset(
            'assets/images/logo/icon card.png',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.eco_rounded, color: _accent, size: 40),
          ),
        ),
      ),
    );
  }
}