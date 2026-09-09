import 'package:flutter/material.dart';
import '../../data/models/game_card.dart';
import '../../data/models/stat.dart';
import '../../domain/game_engine/effect_applier.dart';
import '../../services/audio/game_audio.dart';
import 'package:flutter/services.dart';

class SwipeableCard extends StatefulWidget {
  const SwipeableCard({
    super.key,
    required this.card,
    required this.characterName,
    required this.imageAsset,
    required this.onSwiped,
    this.onHighlightChange,
  });

  final GameCard card;
  final String characterName;
  final String imageAsset;
  final void Function(SwipeDirection direction) onSwiped;
  final void Function(Map<StatType, bool> highlights)? onHighlightChange;

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with TickerProviderStateMixin {
  late final AnimationController _dragController = AnimationController(
    vsync: this,
  );

  late final AnimationController _enterController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  late Animation<double> _enterScale = CurvedAnimation(
    parent: _enterController,
    curve: Curves.easeOutCubic,
  );
  late Animation<double> _enterOpacity = CurvedAnimation(
    parent: _enterController,
    curve: Curves.easeOut,
  );

  Offset _offset = Offset.zero;
  bool _isDragging = false;
  bool _isAnimating = false;

  // ✅ Flag local para controlar el sonido por carta/arrastre
  bool _dragSoundPlayed = false;

  static const double _commitThreshold = 64;

  static const Duration _throwDuration = Duration(milliseconds: 380);
  static const Duration _snapBackDuration = Duration(milliseconds: 220);

  Map<StatType, int>? _currentEffects;

  @override
  void didUpdateWidget(covariant SwipeableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id) {
      _offset = Offset.zero;
      _isDragging = false;
      _isAnimating = false;
      _currentEffects = null;
      _dragSoundPlayed = false; // ✅ Resetear al cambiar de carta
      _enterController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _dragController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    final wasDragging = _isDragging;
    setState(() {
      _offset += details.delta;
      _isDragging = true;
    });

    // ✅ Solo reproducir si NO se ha reproducido antes en este arrastre
    if (!wasDragging && !_dragSoundPlayed) {
      _dragSoundPlayed = true;
      GameAudio.instance.drag();
      if (GameAudio.instance.hapticsEnabled) HapticFeedback.selectionClick();
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isAnimating) return;

    // ✅ Detener sonido y resetear flag
    _dragSoundPlayed = false;
    GameAudio.instance.stopDrag();

    final swipeDistance = _offset.dx.abs();

    if (swipeDistance > _commitThreshold) {
      final direction = _offset.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
      _animateCardOffScreen(direction);
    } else {
      _animateCardBack();
    }
  }

  void _animateCardOffScreen(SwipeDirection direction) {
    _dragSoundPlayed = false; // ✅ Resetear
    GameAudio.instance.swipe();
    setState(() => _isAnimating = true);

    if (widget.onHighlightChange != null) {
      widget.onHighlightChange!({});
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = direction == SwipeDirection.right
        ? screenWidth + 250
        : -screenWidth - 250;

    final startOffset = _offset;

    _dragController
      ..duration = _throwDuration
      ..reset();

    final animation = CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeInCubic,
    );

    void listener() {
      final progress = animation.value;
      final currentX = startOffset.dx + (targetX - startOffset.dx) * progress;
      final currentY = startOffset.dy - (startOffset.dy.abs() * 0.15 + 80) * progress;
      setState(() => _offset = Offset(currentX, currentY));
    }

    void statusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        animation.removeListener(listener);
        animation.removeStatusListener(statusListener);
        widget.onSwiped(direction);
        setState(() {
          _isDragging = false;
          _isAnimating = false;
        });
      }
    }

    animation.addListener(listener);
    animation.addStatusListener(statusListener);
    _dragController.forward();
  }

  void _animateCardBack() {
    _dragSoundPlayed = false; // ✅ Resetear

    if (_offset == Offset.zero) {
      setState(() => _isDragging = false);
      if (widget.onHighlightChange != null) {
        widget.onHighlightChange!({});
      }
      return;
    }

    setState(() => _isAnimating = true);

    final startOffset = _offset;

    _dragController
      ..duration = _snapBackDuration
      ..reset();

    final animation = CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeOutBack,
    );

    void listener() {
      final progress = animation.value;
      setState(() => _offset = startOffset * (1 - progress));
    }

    void statusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        animation.removeListener(listener);
        animation.removeStatusListener(statusListener);
        GameAudio.instance.cardReturn();
        setState(() {
          _offset = Offset.zero;
          _isDragging = false;
          _isAnimating = false;
        });
        if (widget.onHighlightChange != null) {
          widget.onHighlightChange!({});
        }
      }
    }

    animation.addListener(listener);
    animation.addStatusListener(statusListener);
    _dragController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final rotation = _offset.dx / 900;
    final isSwipingRight = _offset.dx > 20;
    final isSwipingLeft = _offset.dx < -20;

    Map<StatType, int>? activeEffects;
    if (isSwipingLeft) {
      activeEffects = widget.card.left.effects;
    } else if (isSwipingRight) {
      activeEffects = widget.card.right.effects;
    }

    if (activeEffects != _currentEffects) {
      _currentEffects = activeEffects;
      if (widget.onHighlightChange != null) {
        final Map<StatType, bool> highlights = {};
        if (activeEffects != null) {
          for (final StatType type in activeEffects!.keys) {
            highlights[type] = true;
          }
        }
        widget.onHighlightChange!(highlights);
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final maxTextWidth = screenWidth * 0.45;

    return GestureDetector(
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onPanCancel: () {
        _dragSoundPlayed = false;
        GameAudio.instance.stopDrag();
        if (mounted) setState(() => _isDragging = false);
      },
      child: AnimatedBuilder(
        animation: _enterController,
        builder: (context, child) {
          return Opacity(
            opacity: _enterOpacity.value,
            child: Transform.scale(
              scale: 0.94 + (0.06 * _enterScale.value),
              child: child,
            ),
          );
        },
        child: Transform.translate(
          offset: _offset,
          child: Transform.rotate(
            angle: rotation,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2E26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSwipingRight || isSwipingLeft
                          ? const Color(0xFFC79A3E)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    widget.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/logo/icon card.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.style_rounded,
                            color: Color(0xFFC79A3E), size: 100),
                      ),
                    ),
                  ),
                ),
                if (isSwipingLeft)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: maxTextWidth,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16211B).withOpacity(0.88),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.card.left.text,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFFFFF8E7),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ),
                if (isSwipingRight)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: maxTextWidth,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16211B).withOpacity(0.88),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.card.right.text,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFFFFF8E7),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
