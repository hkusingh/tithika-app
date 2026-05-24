import 'package:flutter/material.dart';

/// Full-screen background that adapts to the current theme brightness.
/// Dark mode: dark navy gradient with scattered stars.
/// Light mode: warm dawn sky gradient with faint dark speckles.
class StarfieldBackground extends StatelessWidget {
  const StarfieldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: isDark ? _StarfieldPainter() : _DawnSkyPainter(),
      child: const SizedBox.expand(),
    );
  }
}

// ── Dark mode: starfield ───────────────────────────────────────────────────────

class _StarfieldPainter extends CustomPainter {
  static final List<_Particle> _stars = _buildStars();

  static List<_Particle> _buildStars() {
    final rng = _Lcg(seed: 42);
    return List.generate(180, (_) {
      final x       = rng.nextDouble();
      final y       = rng.nextDouble();
      final radius  = rng.nextDouble() * 1.1 + 0.3;   // 0.3 – 1.4 px
      final opacity = rng.nextDouble() * 0.30 + 0.06;  // 0.06 – 0.36
      return _Particle(x, y, radius, opacity);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
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

    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      paint.color = Color.fromRGBO(220, 225, 255, s.opacity);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => false;
}

// ── Light mode: dawn sky ──────────────────────────────────────────────────────

class _DawnSkyPainter extends CustomPainter {
  static final List<_Particle> _speckles = _buildSpeckles();

  static List<_Particle> _buildSpeckles() {
    final rng = _Lcg(seed: 99);
    return List.generate(120, (_) {
      final x       = rng.nextDouble();
      final y       = rng.nextDouble();
      final radius  = rng.nextDouble() * 0.6 + 0.2;   // 0.2 – 0.8 px
      final opacity = rng.nextDouble() * 0.05 + 0.02;  // 0.02 – 0.07
      return _Particle(x, y, radius, opacity);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Warm dawn gradient: amber at top fading to parchment
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0DFB8), Color(0xFFF3E8CE), Color(0xFFF5EEE2), Color(0xFFF5F0E8)],
          stops: [0.0, 0.25, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    // Very faint dark speckles for parchment texture
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in _speckles) {
      paint.color = Color.fromRGBO(26, 31, 60, s.opacity);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_DawnSkyPainter old) => false;
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _Particle {
  const _Particle(this.x, this.y, this.radius, this.opacity);
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
