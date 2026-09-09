import 'package:flutter/material.dart';

class StatIndicator extends StatefulWidget {
  const StatIndicator({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isInDanger = false,
    this.size = 34,
    this.showValue = true,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String label;
  final int value;
  final bool isInDanger;
  final double size;
  final bool showValue;
  final bool isHighlighted;

  @override
  State<StatIndicator> createState() => _StatIndicatorState();
}

class _StatIndicatorState extends State<StatIndicator>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFFC79A3E);
  static const Color _danger = Color(0xFFB6402A);
  static const Color _success = Color(0xFF3C7A5B);
  static const Color _dim = Color(0x33FFFFFF);
  static const Color _cream = Color(0xFFFFF8E7);

  late int _previousValue = widget.value;
  int? _delta;

  late final AnimationController _popController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(covariant StatIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _previousValue) {
      final int change = widget.value - _previousValue;
      _previousValue = widget.value;
      setState(() => _delta = change);
      _popController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determinar el color base del icono
    Color baseColor;
    baseColor = widget.isHighlighted ? _accent : _cream;

    final double fillFraction = (widget.value / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: widget.size + 28,
      height: widget.showValue ? widget.size + 48 : widget.size + 26,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              children: [
                Icon(widget.icon, color: _dim, size: widget.size),
                ClipRect(
                  clipper: _BottomFillClipper(fillFraction),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    child: Icon(widget.icon, color: baseColor, size: widget.size),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showValue)
            Positioned(
              top: widget.size + 2,
              child: Text(widget.label.toUpperCase(), style: TextStyle(
                fontFamily: 'monospace', fontSize: 7,
                color: widget.isHighlighted ? _accent : _cream,
              )),
            ),
          if (widget.showValue)
            Positioned(
              top: widget.size + 14,
              child: Text(
                '${widget.value}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: widget.isHighlighted ? _accent : _cream,
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _popController,
            builder: (BuildContext context, Widget? child) {
              if (_delta == null || _popController.isDismissed) {
                return const SizedBox.shrink();
              }
              final double fade = 1 - _popController.value;
              final double riseOffset = -14.0 * _popController.value;
              final bool positive = _delta! > 0;
              final double deltaTop = widget.showValue
                  ? widget.size + 28 + riseOffset
                  : widget.size + 2 + riseOffset;
              return Positioned(
                top: deltaTop,
                child: Opacity(
                  opacity: fade.clamp(0.0, 1.0),
                  child: Text(
                    positive ? '+${_delta!}' : '${_delta!}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: positive ? _success : _danger,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BottomFillClipper extends CustomClipper<Rect> {
  final double fraction;
  const _BottomFillClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    final double top = size.height * (1 - fraction);
    return Rect.fromLTWH(0, top, size.width, size.height * fraction);
  }

  @override
  bool shouldReclip(covariant _BottomFillClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
