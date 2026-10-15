import 'package:flutter/material.dart';

/// 🌳 Icône Baobab pour les accusés de lecture (comme les ✓ WhatsApp)
class BaobabCheckIcon extends StatelessWidget {
  final double size;
  final Color color;
  final int count; // 1 = envoyé, 2 = livré/lu

  const BaobabCheckIcon({
    super.key,
    this.size = 14,
    required this.color,
    this.count = 1,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: count == 2 ? size * 1.7 : size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: CustomPaint(
              size: Size(size, size),
              painter: _BaobabPainter(color: color),
            ),
          ),
          if (count == 2)
            Positioned(
              left: size * 0.7,
              child: CustomPaint(
                size: Size(size, size),
                painter: _BaobabPainter(color: color),
              ),
            ),
        ],
      ),
    );
  }
}

class _BaobabPainter extends CustomPainter {
  final Color color;
  _BaobabPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Canopée (feuillage) : ellipse en haut
    canvas.drawOval(
      Rect.fromLTWH(0, 0, w, h * 0.6),
      paint,
    );

    // Tronc épais
    canvas.drawRect(
      Rect.fromLTWH(w * 0.35, h * 0.45, w * 0.3, h * 0.55),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BaobabPainter old) => old.color != color;
}