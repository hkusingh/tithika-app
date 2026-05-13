import 'package:flutter/material.dart';

/// Full-screen dark sky gradient with randomly scattered stars.
/// Uses a fixed seed so the star pattern is stable across repaints and
/// navigation transitions.
class StarfieldBackground extends StatelessWidget {
  const StarfieldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarfieldPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  static final List<_Star> _stars = _buildStars();

  static List<_Star> _buildStars() {
    final rng = _Lcg(seed: 42);
    return List.generate(180, (_) {
      final x       = rng.nextDouble();
      final y       = rng.nextDouble();
      final radius  = rng.nextDouble() * 1.1 + 0.3;   // 0.3 – 1.4 px
      final opacity = rng.nextDouble() * 0.30 + 0.06;  // 0.06 – 0.36
      return _Star(x, y, radius, opacity);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050714), Color(0xFF0B1130), Color(0xFF08091A)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    // Stars
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      paint.color = Color.fromRGBO(220, 225, 255, s.opacity);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => false;
}

class _Star {
  const _Star(this.x, this.y, this.radius, this.opacity);
  final double x, y, radius, opacity;
}

// Lightweight LCG — avoids dart:math dependency.
class _Lcg {
  _Lcg({required int seed}) : _state = seed;
  int _state;

  double nextDouble() {
    _state = (_state * 1664525 + 1013904223) & 0xFFFFFFFF;
    return _state / 0xFFFFFFFF;
  }
}
