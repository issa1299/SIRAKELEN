import 'package:flutter/material.dart';

/// Logo Google "G" officiel en 4 couleurs, dessiné en vectoriel.
class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GooglePainter(),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final stroke = w * 0.2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, w - stroke, w - stroke);

    // Ordre : les arcs suivants recouvrent les jointures des précédents.
    // Jaune : bas + gauche
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 1.6, 2.6, false, paint);
    // Vert : bas-droit
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.35, 1.5, false, paint);
    // Rouge : haut (recouvre les deux jointures)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.9, 3.45, false, paint);
    // Bleu : barre horizontale du centre au bord droit du cercle
    final cy = w / 2;
    canvas.drawRect(
      Rect.fromLTWH(w / 2, cy - stroke / 2, w / 2 - stroke / 2, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
