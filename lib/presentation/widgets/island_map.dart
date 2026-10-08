import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show setEquals;
import '../../domain/game_engine/island_snapshot.dart';

class IslandMap extends StatelessWidget {
  final IslandSnapshot island;
  final IslandDistrict selected;
  final ValueChanged<IslandDistrict> onSelect;
  const IslandMap(
      {super.key,
      required this.island,
      required this.selected,
      required this.onSelect});
  static const positions = {
    IslandDistrict.water: Offset(.46, .22),
    IslandDistrict.neighborhoods: Offset(.24, .45),
    IslandDistrict.mill: Offset(.72, .43),
    IslandDistrict.port: Offset(.73, .79),
    IslandDistrict.palace: Offset(.34, .74),
  };
  @override
  Widget build(BuildContext context) => AspectRatio(
      aspectRatio: 1.15,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: LayoutBuilder(
              builder: (context, constraints) => Stack(children: [
                    Positioned.fill(
                        child: RepaintBoundary(
                            child:
                                CustomPaint(painter: _IslandPainter(island)))),
                    for (final district in IslandDistrict.values)
                      Positioned(
                          left: positions[district]!.dx * constraints.maxWidth -
                              43,
                          top: positions[district]!.dy * constraints.maxHeight +
                              10,
                          width: 86,
                          child: Semantics(
                              selected: selected == district,
                              child: Material(
                                  color: selected == district
                                      ? const Color(0xFFC79A3E)
                                      : const Color(0xFFFFF8E7),
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => onSelect(district),
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 2),
                                          child: Text(district.label,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: Color(0xFF16211B),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11))))))),
                  ]))));
}

class _IslandPainter extends CustomPainter {
  final IslandSnapshot island;
  _IslandPainter(this.island);
  static const sea = Color(0xFF254F53);
  static const land = Color(0xFFD5BE88);
  static const dark = Color(0xFF263D30);
  static const roof = Color(0xFFA15339);
  static const water = Color(0xFF79B6B0);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 348);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 348), Paint()..color = sea);
    final wave = Paint()
      ..color = water.withValues(alpha: .25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var row = 0; row < 10; row++) {
      for (var col = 0; col < 7; col++) {
        final x = col * 65.0 + (row.isOdd ? 18 : 0);
        final y = row * 36.0 + 18;
        canvas.drawArc(Rect.fromLTWH(x, y, 26, 8), 0, 3.14, false, wave);
      }
    }
    final shore = Path()
      ..moveTo(47, 87)
      ..cubicTo(48, 35, 139, 29, 174, 47)
      ..cubicTo(205, 6, 281, 26, 303, 63)
      ..cubicTo(363, 63, 374, 139, 336, 176)
      ..cubicTo(365, 232, 315, 292, 264, 283)
      ..cubicTo(218, 326, 146, 296, 124, 274)
      ..cubicTo(60, 302, 28, 243, 53, 200)
      ..cubicTo(10, 168, 16, 103, 47, 87)
      ..close();
    canvas.drawPath(
        shore,
        Paint()
          ..color = land
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        shore,
        Paint()
          ..color = const Color(0xFFEBD79D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9);
    canvas.drawOval(const Rect.fromLTWH(122, 118, 156, 94),
        Paint()..color = const Color(0xFF849164));
    final road = Path()
      ..moveTo(93, 160)
      ..quadraticBezierTo(147, 170, 184, 90)
      ..moveTo(93, 160)
      ..quadraticBezierTo(193, 222, 287, 149)
      ..moveTo(136, 258)
      ..quadraticBezierTo(220, 221, 293, 273);
    canvas.drawPath(
        road,
        Paint()
          ..color = const Color(0xFFAC986B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);
    // Reservoir and channel, visibly broken until repaired.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(163, 56, 47, 24), const Radius.circular(5)),
        Paint()..color = dark);
    canvas.drawRect(
        const Rect.fromLTWH(167, 60, 39, 16),
        Paint()
          ..color = island.waterRepaired ? water : const Color(0xFFAC986B));
    final channel = Path()
      ..moveTo(184, 81)
      ..lineTo(178, 106);
    if (island.waterRepaired) {
      channel.lineTo(150, 127);
      channel.lineTo(119, 145);
    } else {
      channel.moveTo(156, 124);
      channel.lineTo(120, 145);
    }
    canvas.drawPath(
        channel,
        Paint()
          ..color = water
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
    if (island.commonWater) _flag(canvas, 209, 50, const Color(0xFF477760));
    // Houses and a refuge; local councils add a shared table.
    for (final p in [
      const Offset(67, 118),
      const Offset(102, 120),
      const Offset(82, 145)
    ]) {
      _house(canvas, p.dx, p.dy, 25);
    }
    if (island.has('refugios_vecinales')) {
      canvas.drawRect(
          const Rect.fromLTWH(53, 156, 13, 3), Paint()..color = water);
      canvas.drawRect(
          const Rect.fromLTWH(58, 151, 3, 13), Paint()..color = water);
    }
    if (island.localCouncils) {
      canvas.drawOval(
          const Rect.fromLTWH(112, 154, 24, 10), Paint()..color = dark);
    }
    if (island.has('agua_control')) {
      _person(canvas, 146, 112);
      _flag(canvas, 139, 89, dark);
    }
    final count = island.simplifiedQueues
        ? 2
        : island.queues
            ? 7
            : 0;
    for (var i = 0; i < count; i++) {
      _person(canvas, 49.0 + i * 8, 202);
    }
    // Ingenio, recirculation loop and apprenticeship workshop.
    canvas.drawRect(
        const Rect.fromLTWH(261, 120, 45, 26), Paint()..color = roof);
    canvas.drawRect(const Rect.fromLTWH(296, 94, 9, 28), Paint()..color = dark);
    if (island.has('agua_recirculada')) {
      canvas.drawArc(
          const Rect.fromLTWH(244, 107, 70, 42),
          .4,
          5.4,
          false,
          Paint()
            ..color = water
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
    if (island.has('aprendices_puerto')) _house(canvas, 313, 130, 18);
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(
          Offset(245.0 + i * 12, 204),
          Offset(253.0 + i * 12, 177),
          Paint()
            ..color = dark
            ..strokeWidth = 3);
    }
    // Plaza: library, statue or palace, never all at once.
    _house(canvas, 117, 231, 36);
    if (island.has('biblioteca_publica')) {
      canvas.drawRect(
          const Rect.fromLTWH(124, 236, 24, 3), Paint()..color = water);
      for (var i = 0; i < 3; i++) {
        canvas.drawRect(
            Rect.fromLTWH(126.0 + i * 8, 241, 3, 9), Paint()..color = dark);
      }
    } else if (island.has('estatua_local')) {
      canvas.drawRect(
          const Rect.fromLTWH(153, 235, 12, 5), Paint()..color = dark);
      _person(canvas, 159, 232, color: const Color(0xFFC79A3E));
    }
    // Dock, cranes and operators. Broken dock has a visible gap.
    canvas.drawRect(
        const Rect.fromLTWH(279, 239, 57, 9), Paint()..color = dark);
    if (island.portRepaired) {
      canvas.drawRect(const Rect.fromLTWH(324, 239, 14, 48),
          Paint()..color = const Color(0xFFAE8250));
    } else {
      canvas.drawRect(const Rect.fromLTWH(324, 255, 14, 16),
          Paint()..color = const Color(0xFFAE8250));
    }
    if (island.portRepaired) {
      canvas.drawLine(
          const Offset(311, 239),
          const Offset(311, 209),
          Paint()
            ..color = dark
            ..strokeWidth = 3);
      canvas.drawLine(
          const Offset(311, 209),
          const Offset(339, 209),
          Paint()
            ..color = dark
            ..strokeWidth = 3);
      final boat = Path()
        ..moveTo(343, 262)
        ..lineTo(377, 262)
        ..lineTo(369, 273)
        ..lineTo(349, 273)
        ..close();
      canvas.drawPath(boat, Paint()..color = roof);
      if (island.sharedPort) {
        canvas.drawPath(
            boat.shift(const Offset(-2, 24)), Paint()..color = land);
      }
    }
    if (island.autonomousPort || island.dependentPort) {
      _flag(canvas, 337, 232,
          island.autonomousPort ? const Color(0xFFC79A3E) : roof);
    }
    if (island.has('puerto_militar')) {
      _person(canvas, 263, 231);
      _flag(canvas, 267, 215, dark);
    }
    if (island.has('misterio_encubierto')) {
      canvas.drawRect(
          const Rect.fromLTWH(287, 231, 9, 7), Paint()..color = dark);
    }
    canvas.restore();
  }

  void _house(Canvas c, double x, double y, double w) {
    c.drawRect(Rect.fromLTWH(x, y, w, w * .6),
        Paint()..color = const Color(0xFFF4E4B8));
    c.drawPath(
        Path()
          ..moveTo(x - 2, y)
          ..lineTo(x + w / 2, y - w * .35)
          ..lineTo(x + w + 2, y)
          ..close(),
        Paint()..color = roof);
    c.drawRect(Rect.fromLTWH(x + w * .4, y + w * .2, w * .2, w * .4),
        Paint()..color = dark);
  }

  void _person(Canvas c, double x, double y, {Color color = dark}) {
    c.drawCircle(Offset(x, y - 9), 3, Paint()..color = color);
    c.drawRect(Rect.fromLTWH(x - 2, y - 5, 4, 8), Paint()..color = color);
  }

  void _flag(Canvas c, double x, double y, Color color) {
    c.drawLine(
        Offset(x, y),
        Offset(x, y + 19),
        Paint()
          ..color = dark
          ..strokeWidth = 2);
    c.drawPath(
        Path()
          ..moveTo(x, y)
          ..lineTo(x + 12, y + 2)
          ..lineTo(x + 12, y + 9)
          ..lineTo(x, y + 7)
          ..close(),
        Paint()..color = color);
  }

  @override
  bool shouldRepaint(_IslandPainter oldDelegate) =>
      !setEquals(oldDelegate.island.flags, island.flags) ||
      oldDelegate.island.poverty != island.poverty;
}
