import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/era.dart';
import '../../data/repositories/event_repository.dart';
import '../../services/persistence/progress_service.dart';
import '../../services/audio/game_audio.dart'; // ✅ Agregar import

class EventsErasScreen extends StatefulWidget {
  const EventsErasScreen({super.key, required this.reachedEra});

  final Era reachedEra;

  @override
  State<EventsErasScreen> createState() => _EventsErasScreenState();
}

class _EventsErasScreenState extends State<EventsErasScreen> {
  static const ink = Color(0xFF16211B);
  static const panel = Color(0xFF1F2E26);
  static const accent = Color(0xFFC79A3E);
  static const body = Color(0xFFEAE1D3);
  static const cream = Color(0xFFFFF8E7);
  final ProgressService _progress = ProgressService();
  Set<String> _discoveredEventIds = {};
  int _maxEraIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    if (!EventRepository.isLoaded) {
      EventRepository.loadEvents().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _loadProgress() async {
    await _progress.init();
    if (!mounted) return;
    setState(() {
      _discoveredEventIds = _progress.discoveredEventIds;
      _maxEraIndex = _progress.maxEraReached;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = EventRepository.definitions;

    return Scaffold(
      backgroundColor: body,
      appBar: AppBar(
        backgroundColor: ink,
        foregroundColor: accent,
        title: const Text('EVENTOS Y ERAS', style: TextStyle(fontFamily: 'monospace', fontSize: 15, letterSpacing: 1.5)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          _sectionTitle('ERAS'),
          const SizedBox(height: 10),
          for (final era in Era.values) _EraRow(era: era, unlocked: era.index <= _maxEraIndex),
          const SizedBox(height: 26),
          _sectionTitle('EVENTOS'),
          const SizedBox(height: 10),
          if (allEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No hay eventos disponibles.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'monospace', color: ink)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allEvents.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (_, index) {
                final event = allEvents[index];
                final isUnlocked = _discoveredEventIds.contains(event.id);
                return _EventCard(
                  event: event,
                  unlocked: isUnlocked,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: const TextStyle(fontFamily: 'monospace', color: ink, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12));
}

class _EraRow extends StatelessWidget {
  const _EraRow({required this.era, required this.unlocked});
  final Era era;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: unlocked ? _EventsErasScreenState.panel : _EventsErasScreenState.panel.withOpacity(.55),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: unlocked ? _EventsErasScreenState.accent.withOpacity(.7) : Colors.black12),
    ),
    child: Row(children: [
      if (!unlocked) ...[
        const Icon(Icons.lock_rounded, color: Colors.black38, size: 20),
        const SizedBox(width: 12),
      ],
      Expanded(child: Text(unlocked ? era.label.toUpperCase() : 'ERA BLOQUEADA', style: TextStyle(fontFamily: 'monospace', color: unlocked ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
    ]),
  );
}

class _EventCard extends StatefulWidget {
  const _EventCard({required this.event, required this.unlocked});
  final EventDefinition event;
  final bool unlocked;

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> with SingleTickerProviderStateMixin {
  static const _panelDark = Color(0xFF1F2E26);
  static const _accent = Color(0xFFC79A3E);
  static const _cream = Color(0xFFFFF8E7);

  late final AnimationController _controller;
  bool _showingBack = false;
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

  void _toggle() {
    if (!widget.unlocked) return;
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
      return const _LockedEventCard();
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
                ? _CardFront(event: widget.event)
                : Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(math.pi),
              child: _CardBack(event: widget.event),
            ),
          );
        },
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({required this.event});
  final EventDefinition event;

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
                event.image,
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
                        Icons.warning_amber_rounded,
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
              event.title,
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
  const _CardBack({required this.event});
  final EventDefinition event;

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
              Icons.warning_amber_rounded,
              color: _accent,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              event.title,
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
              '${event.prompts.length} DECISIONES',
              textAlign: TextAlign.center,
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
                  event.bio ?? _fallbackBio(event),
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

  String _fallbackBio(EventDefinition e) {
    return 'Un evento que afecta el rumbo de la isla. Las decisiones que tomes cambiarán el equilibrio de poder.';
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

class _LockedEventCard extends StatelessWidget {
  const _LockedEventCard();

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