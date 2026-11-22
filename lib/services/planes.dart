import 'package:flutter/material.dart';

/// One buyable plane: color + a super power that changes how it plays.
class PlaneDef {
  final int id;
  final String name;
  final Color color;
  final int price; // in diamonds, 0 = free starter
  final String power; // short text shown in the store
  final double fireMul; // fire interval multiplier (smaller = faster)
  final int maxHp;
  final int shots; // 2 = twin guns, 3 = triple shot
  final int missiles; // missiles at the start of a level
  final int missileDmg;
  final int revives; // times it comes back to life after dying

  const PlaneDef({
    required this.id,
    required this.name,
    required this.color,
    required this.price,
    required this.power,
    this.fireMul = 1.0,
    this.maxHp = 100,
    this.shots = 2,
    this.missiles = 3,
    this.missileDmg = 12,
    this.revives = 0,
  });
}

/// The index in this list is the plane id.
const kPlanes = <PlaneDef>[
  PlaneDef(
    id: 0,
    name: 'Starter',
    color: Color(0xFF00B894),
    price: 0,
    power: 'No special power',
  ),
  PlaneDef(
    id: 1,
    name: 'Pink Comet',
    color: Color(0xFFFD79A8),
    price: 150,
    power: 'Rapid Fire: shoots 30% faster',
    fireMul: 0.7,
  ),
  PlaneDef(
    id: 2,
    name: 'Cyan Guard',
    color: Color(0xFF00CEC9),
    price: 300,
    power: 'Heavy Armor: 150 HP instead of 100',
    maxHp: 150,
  ),
  PlaneDef(
    id: 3,
    name: 'Golden Hawk',
    color: Color(0xFFFDCB6E),
    price: 500,
    power: 'Triple Shot: 3 bullets at once',
    shots: 3,
  ),
  PlaneDef(
    id: 4,
    name: 'Violet Ghost',
    color: Color(0xFF6C5CE7),
    price: 800,
    power: 'Missile Master: 6 missiles, stronger blast',
    missiles: 6,
    missileDmg: 20,
  ),
  PlaneDef(
    id: 5,
    name: 'Orange Phoenix',
    color: Color(0xFFFF6B00),
    price: 1200,
    power: 'Rebirth: revives once with half HP',
    revives: 1,
  ),
];

/// Draws a plane in a 100x100 design box centered at [c], scaled by [s].
/// [rot] = 0 points up, pi points down.
void drawPlane(Canvas canvas, Offset c, double s, Color color, double rot) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  if (rot != 0) canvas.rotate(rot);
  canvas.scale(s);
  canvas.translate(-50, -50);

  final fill = Paint()..color = color;
  final edge = Paint()
    ..color = Colors.black.withOpacity(0.18)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  final wings = Path()
    ..moveTo(46, 40)
    ..lineTo(6, 68)
    ..lineTo(6, 75)
    ..lineTo(46, 62)
    ..close()
    ..moveTo(54, 40)
    ..lineTo(94, 68)
    ..lineTo(94, 75)
    ..lineTo(54, 62)
    ..close();
  canvas.drawPath(wings, fill);
  canvas.drawPath(wings, edge);

  final tail = Path()
    ..moveTo(47, 80)
    ..lineTo(32, 92)
    ..lineTo(32, 97)
    ..lineTo(48, 92)
    ..close()
    ..moveTo(53, 80)
    ..lineTo(68, 92)
    ..lineTo(68, 97)
    ..lineTo(52, 92)
    ..close();
  canvas.drawPath(tail, fill);
  canvas.drawPath(tail, edge);

  final body = Path()
    ..moveTo(50, 2)
    ..cubicTo(57, 20, 57, 42, 55, 64)
    ..lineTo(55, 86)
    ..lineTo(45, 86)
    ..lineTo(45, 64)
    ..cubicTo(43, 42, 43, 20, 50, 2)
    ..close();
  canvas.drawPath(body, Paint()..color = Colors.white);
  canvas.drawPath(body, edge);

  canvas.drawOval(
    Rect.fromCenter(center: const Offset(50, 24), width: 9, height: 18),
    Paint()..color = const Color(0xFF74B9FF),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        const Rect.fromLTWH(47, 44, 6, 14), const Radius.circular(3)),
    fill,
  );
  canvas.restore();
}

/// Small widget that shows a plane (used in the store and on Home).
class PlaneIcon extends StatelessWidget {
  final Color color;
  final double size;
  const PlaneIcon({super.key, required this.color, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PlaneIconPainter(color)),
    );
  }
}

class _PlaneIconPainter extends CustomPainter {
  final Color color;
  _PlaneIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    drawPlane(canvas, Offset(size.width / 2, size.height / 2),
        size.width / 100, color, 0);
  }

  @override
  bool shouldRepaint(covariant _PlaneIconPainter old) => old.color != color;
}
