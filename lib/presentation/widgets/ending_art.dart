import 'package:flutter/material.dart';
import '../../data/models/ending.dart';

/// Original vector illustrations: five political endings, five distinct scenes.
class EndingArt extends StatelessWidget {
  final Ending ending;
  const EndingArt({super.key, required this.ending});
  @override
  Widget build(BuildContext context) => ending.isStoryEnding
      ? Semantics(
          image: true,
          label: 'Ilustración: ${ending.title}',
          child: RepaintBoundary(
              child: CustomPaint(
                  painter: _EndingPainter(ending.id), size: Size.infinite)))
      : Image.asset(ending.imageAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.flag_rounded, size: 48)));
}

class _EndingPainter extends CustomPainter {
  final String id;
  _EndingPainter(this.id);
  static const ink = Color(0xFF263D30);
  static const sand = Color(0xFFEADBB8);
  static const gold = Color(0xFFC79A3E);
  static const brick = Color(0xFFAA6044);
  static const sea = Color(0xFF547F7D);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Center a 400 x 260 storybook scene for portrait gallery cards too.
    final scale = size.width / 400 > size.height / 260
        ? size.width / 400
        : size.height / 260;
    canvas.translate(
        (size.width - 400 * scale) / 2, (size.height - 260 * scale) / 2);
    canvas.scale(scale);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 260), Paint()..color = sand);
    canvas.drawCircle(
        const Offset(286, 65), 35, Paint()..color = gold.withValues(alpha: .6));
    canvas.drawPath(
        Path()
          ..moveTo(0, 155)
          ..quadraticBezierTo(96, 92, 163, 152)
          ..quadraticBezierTo(276, 100, 400, 151)
          ..lineTo(400, 260)
          ..lineTo(0, 260)
          ..close(),
        Paint()..color = const Color(0xFF8C9B75));
    canvas.drawRect(const Rect.fromLTWH(0, 201, 400, 59), Paint()..color = ink);
    if (id == 'ending_comunidad_autonoma') {
      // Shared reservoir, houses and neighbors around a table.
      _house(canvas, 82, 119, 39);
      _house(canvas, 134, 105, 35);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(246, 137, 68, 40), const Radius.circular(7)),
          Paint()..color = ink);
      canvas.drawRect(
          const Rect.fromLTWH(251, 143, 58, 27), Paint()..color = sea);
      canvas.drawOval(
          const Rect.fromLTWH(161, 181, 81, 18), Paint()..color = gold);
      _person(canvas, 160, 193, brick);
      _person(canvas, 247, 193, ink);
      _person(canvas, 202, 176, ink);
      canvas.drawPath(
          Path()
            ..moveTo(276, 174)
            ..lineTo(276, 188)
            ..lineTo(238, 188),
          Paint()
            ..color = sea
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5);
    } else if (id == 'ending_isla_acreedores') {
      // Port crane, a cargo ship and the contract hanging over the dock.
      canvas.drawRect(
          const Rect.fromLTWH(0, 181, 400, 20), Paint()..color = sea);
      canvas.drawPath(
          Path()
            ..moveTo(97, 170)
            ..lineTo(285, 170)
            ..lineTo(269, 193)
            ..lineTo(118, 193)
            ..close(),
          Paint()..color = brick);
      for (var i = 0; i < 4; i++) {
        canvas.drawRect(Rect.fromLTWH(132.0 + i * 32, 147, 27, 20),
            Paint()..color = i.isEven ? ink : gold);
      }
      canvas.drawLine(
          const Offset(101, 183),
          const Offset(101, 89),
          Paint()
            ..color = ink
            ..strokeWidth = 7);
      canvas.drawLine(
          const Offset(101, 89),
          const Offset(249, 89),
          Paint()
            ..color = ink
            ..strokeWidth = 7);
      canvas.drawLine(
          const Offset(216, 90),
          const Offset(216, 111),
          Paint()
            ..color = ink
            ..strokeWidth = 2);
      canvas.drawRect(
          const Rect.fromLTWH(199, 110, 36, 32), Paint()..color = sand);
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
            Offset(206, 119.0 + i * 7),
            Offset(228, 119.0 + i * 7),
            Paint()
              ..color = brick
              ..strokeWidth = 2);
      }
    } else if (id == 'ending_cosecha_silencio') {
      // A sealed archive above the sacks, with a boat disappearing offshore.
      canvas.drawRect(
          const Rect.fromLTWH(103, 106, 196, 95), Paint()..color = brick);
      canvas.drawPath(
          Path()
            ..moveTo(87, 107)
            ..lineTo(201, 73)
            ..lineTo(315, 107)
            ..close(),
          Paint()..color = ink);
      canvas.drawRect(
          const Rect.fromLTWH(178, 127, 48, 73), Paint()..color = ink);
      for (var i = 0; i < 3; i++) {
        canvas.drawOval(
            Rect.fromLTWH(115.0 + i * 22, 170, 19, 27), Paint()..color = gold);
      }
      canvas.drawRect(
          const Rect.fromLTWH(187, 144, 31, 29), Paint()..color = sand);
      canvas.drawCircle(const Offset(203, 160), 8, Paint()..color = brick);
      canvas.drawLine(
          const Offset(203, 168),
          const Offset(203, 186),
          Paint()
            ..color = brick
            ..strokeWidth = 4);
    } else if (id == 'ending_gobierno_perpetuo') {
      // Palace window and a chair whose shadow reaches the square.
      canvas.drawRect(
          const Rect.fromLTWH(106, 77, 185, 124), Paint()..color = sand);
      canvas.drawPath(
          Path()
            ..moveTo(92, 78)
            ..lineTo(200, 41)
            ..lineTo(304, 78)
            ..close(),
          Paint()..color = brick);
      for (var i = 0; i < 4; i++) {
        canvas.drawRect(
            Rect.fromLTWH(124.0 + i * 43, 86, 12, 102), Paint()..color = gold);
      }
      canvas.drawRect(
          const Rect.fromLTWH(177, 100, 48, 76), Paint()..color = ink);
      canvas.drawRect(
          const Rect.fromLTWH(189, 122, 24, 30), Paint()..color = gold);
      canvas.drawRect(
          const Rect.fromLTWH(185, 151, 32, 6), Paint()..color = gold);
      canvas.drawPath(
          Path()
            ..moveTo(189, 177)
            ..lineTo(213, 177)
            ..lineTo(253, 231)
            ..lineTo(154, 231)
            ..close(),
          Paint()..color = ink.withValues(alpha: .45));
    } else {
      // A public handover: two people, open accounts and an empty chair.
      _house(canvas, 266, 134, 39);
      canvas.drawRect(
          const Rect.fromLTWH(145, 167, 104, 9), Paint()..color = brick);
      canvas.drawRect(
          const Rect.fromLTWH(152, 176, 6, 24), Paint()..color = brick);
      canvas.drawRect(
          const Rect.fromLTWH(237, 176, 6, 24), Paint()..color = brick);
      canvas.drawRect(
          const Rect.fromLTWH(172, 150, 50, 14), Paint()..color = sand);
      canvas.drawLine(
          const Offset(197, 151),
          const Offset(197, 163),
          Paint()
            ..color = brick
            ..strokeWidth = 2);
      _person(canvas, 134, 194, ink);
      _person(canvas, 259, 194, brick);
      canvas.drawRect(
          const Rect.fromLTWH(190, 109, 21, 30), Paint()..color = gold);
      canvas.drawRect(
          const Rect.fromLTWH(186, 139, 29, 5), Paint()..color = gold);
      canvas.drawLine(
          const Offset(192, 144),
          const Offset(192, 164),
          Paint()
            ..color = gold
            ..strokeWidth = 4);
      canvas.drawLine(
          const Offset(209, 144),
          const Offset(209, 164),
          Paint()
            ..color = gold
            ..strokeWidth = 4);
    }
    // A fine border and waves give every illustration the same visual identity.
    canvas.drawRect(
        const Rect.fromLTWH(12, 12, 376, 236),
        Paint()
          ..color = gold.withValues(alpha: .5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    for (var i = 0; i < 7; i++) {
      canvas.drawArc(
          Rect.fromLTWH(41.0 + i * 46, 227, 24, 7),
          0,
          3.14,
          false,
          Paint()
            ..color = sea
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
    canvas.restore();
  }

  void _house(Canvas c, double x, double y, double w) {
    c.drawRect(Rect.fromLTWH(x, y, w, w * .7), Paint()..color = sand);
    c.drawPath(
        Path()
          ..moveTo(x - 4, y)
          ..lineTo(x + w / 2, y - 21)
          ..lineTo(x + w + 4, y)
          ..close(),
        Paint()..color = brick);
    c.drawRect(
        Rect.fromLTWH(x + w * .4, y + 9, w * .2, w * .5), Paint()..color = ink);
  }

  void _person(Canvas c, double x, double y, Color color) {
    c.drawCircle(Offset(x, y - 38), 8, Paint()..color = color);
    c.drawPath(
        Path()
          ..moveTo(x - 5, y - 27)
          ..lineTo(x + 5, y - 27)
          ..lineTo(x + 13, y)
          ..lineTo(x - 13, y)
          ..close(),
        Paint()..color = color);
  }

  @override
  bool shouldRepaint(_EndingPainter oldDelegate) => id != oldDelegate.id;
}
