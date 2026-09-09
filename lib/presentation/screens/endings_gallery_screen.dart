import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ending.dart';
import '../../domain/game_engine/game_controller.dart';
import '../../services/persistence/progress_service.dart';
import '../../services/audio/game_audio.dart'; // ✅ Agregar import

class EndingsGalleryScreen extends ConsumerStatefulWidget {
  const EndingsGalleryScreen({super.key});

  @override
  ConsumerState<EndingsGalleryScreen> createState() => _EndingsGalleryScreenState();
}

class _EndingsGalleryScreenState extends ConsumerState<EndingsGalleryScreen> {
  static const ink = Color(0xFF16211B);
  static const panel = Color(0xFF1F2E26);
  static const accent = Color(0xFFC79A3E);
  static const body = Color(0xFFEAE1D3);
  final ProgressService _progress = ProgressService();
  Set<String> _unlocked = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _progress.init();
    await ref.read(cardRepositoryProvider).loadAll();
    if (!mounted) return;
    setState(() {
      _unlocked = _progress.seenEndingIds;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final endings = ref.watch(cardRepositoryProvider).endings;
    return Scaffold(
      backgroundColor: body,
      appBar: AppBar(
        backgroundColor: ink,
        foregroundColor: accent,
        title: const Text('FINALES', style: TextStyle(fontFamily: 'monospace', fontSize: 15, letterSpacing: 2)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_unlocked.length} / ${endings.length} DESBLOQUEADOS', style: const TextStyle(fontFamily: 'monospace', color: ink, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: endings.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: .68,
                ),
                itemBuilder: (_, index) {
                  final ending = endings[index];
                  return _EndingCard(
                    ending: ending,
                    unlocked: _unlocked.contains(ending.id),
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

class _EndingCard extends StatefulWidget {
  const _EndingCard({required this.ending, required this.unlocked});
  final Ending ending;
  final bool unlocked;
  @override
  State<_EndingCard> createState() => _EndingCardState();
}

class _EndingCardState extends State<_EndingCard> with SingleTickerProviderStateMixin {
  static const _panelDark = Color(0xFF1F2E26);
  static const _accent = Color(0xFFC79A3E);
  static const _cream = Color(0xFFFFF8E7);
  static const _accentDim = Color(0x66C79A3E);

  late AnimationController _controller;
  bool _back = false;
  bool _flipSoundPlayed = false; // ✅ Control de sonido

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(_onFlipProgress);
  }

  void _onFlipProgress() {
    // ✅ Reproducir sonido en el rango 0.2 - 0.8
    if (_controller.value >= 0.2 && _controller.value <= 0.8 && !_flipSoundPlayed) {
      _flipSoundPlayed = true;
      GameAudio.instance.cardFlip();
    }

    // ✅ Resetear cuando la animación termina o vuelve
    if (_controller.value >= 0.99 || _controller.value <= 0.01) {
      _flipSoundPlayed = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onFlipProgress);
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!widget.unlocked) return;
    setState(() => _back = !_back);
    _flipSoundPlayed = false;
    _back ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.unlocked) {
      return _buildLockedCard();
    }

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final angle = _controller.value * math.pi;
          final front = angle < math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .0015)
              ..rotateY(angle),
            child: front
                ? _front()
                : Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(math.pi),
              child: _backFace(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLockedCard() {
    return Container(
      decoration: BoxDecoration(
        color: _panelDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentDim, width: 1.2),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.55,
          child: Image.asset(
            'assets/images/logo/icon card.png',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.flag_rounded,
              color: _accent,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _front() => _shell(
    Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            child: Image.asset(
              widget.ending.imageAsset,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: _panelDark,
                child: Center(
                  child: Image.asset(
                    'assets/images/logo/icon card.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.flag_rounded,
                      color: _accent,
                      size: 42,
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
          padding: const EdgeInsets.all(8),
          child: Text(
            widget.ending.title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _backFace() => _shell(
    Container(
      color: _panelDark,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.flag_rounded,
            color: _accent,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            widget.ending.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: _accent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                widget.ending.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _shell(Widget child) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _accent.withOpacity(.7), width: 1.3),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}