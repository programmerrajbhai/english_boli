import 'dart:math' as math;
import 'package:flutter/material.dart';

class MagicalBackground extends StatelessWidget {
  final Widget child;

  const MagicalBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Magical Bubble System Painter
        Positioned.fill(
          child: CustomPaint(
            painter: _BubbleSystemPainter(),
          ),
        ),
        // The actual screen content goes here
        child,
      ],
    );
  }
}

class _BubbleSystemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final bgGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF070C0A),
          const Color(0xFF0F1F1B),
          const Color(0xFF0A1412)
        ]
    );

    canvas.drawRect(rect, Paint()..shader = bgGradient.createShader(rect));

    _drawGlow(canvas, Offset(size.width * 0.2, size.height * 0.2), 200, const Color(0xFF00E0B8).withValues(alpha: 0.08));
    _drawGlow(canvas, Offset(size.width * 0.8, size.height * 0.7), 250, const Color(0xFFFFC928).withValues(alpha: 0.05));

    final random = math.Random(42);
    for (int i = 0; i < 20; i++) {
      _drawGlassBubble(
          canvas,
          Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
          random.nextDouble() * 30 + 10
      );
    }
  }

  void _drawGlow(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()..color = color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80));
  }

  void _drawGlassBubble(Canvas canvas, Offset center, double radius) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final fillGradient = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent],
        stops: const [0.0, 1.0]
    );
    canvas.drawCircle(center, radius, Paint()..shader = fillGradient.createShader(rect));

    final borderGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withValues(alpha: 0.3), Colors.transparent]
    );
    canvas.drawCircle(
        center,
        radius,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1..shader = borderGradient.createShader(rect)
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}