import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

class MoonPhaseWidget extends StatelessWidget {
  final int tithiNumber; // 1–30
  final Color glowColor;
  final double size;

  const MoonPhaseWidget({
    required this.tithiNumber,
    required this.glowColor,
    this.size = 100,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TithikaColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.moonDark,
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 18, spreadRadius: 2),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          painter: _MoonPhasePainter(tithiNumber, colors.moonLight),
        ),
      ),
    );
  }
}

class _MoonPhasePainter extends CustomPainter {
  final int tithiNumber;
  final Color litColor;

  const _MoonPhasePainter(this.tithiNumber, this.litColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Elongation at the midpoint of this tithi (each tithi = 12° of elongation).
    final elongRad = (tithiNumber - 0.5) * 12.0 * pi / 180.0;

    // factor > 0 → crescent terminator (curving inward on the lit side)
    // factor = 0 → quarter (straight vertical terminator)
    // factor < 0 → gibbous terminator (curving outward on the lit side)
    final factor = cos(elongRad);

    final litPaint = Paint()
      ..color = litColor
      ..style = PaintingStyle.fill;

    final isWaxing = tithiNumber <= 15;

    if (isWaxing) {
      _drawPhase(canvas, cx, cy, r, factor, litPaint);
    } else {
      // Mirror horizontally: waning moon is lit on the left.
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(-1, 1);
      canvas.translate(-cx, -cy);
      _drawPhase(canvas, cx, cy, r, factor, litPaint);
      canvas.restore();
    }
  }

  // Draws the lit portion with the lit side on the RIGHT.
  // Waning phases call this inside a horizontal mirror transform.
  void _drawPhase(
      Canvas canvas, double cx, double cy, double r, double factor, Paint paint) {
    final path = Path();
    final circleRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Right semicircle: top → right → bottom (clockwise).
    path.moveTo(cx, cy - r);
    path.arcTo(circleRect, -pi / 2, pi, false);

    if (factor.abs() < 0.02) {
      // Near-quarter: close with a vertical line.
      path.lineTo(cx, cy - r);
    } else if (factor > 0) {
      // Crescent: right side of terminator ellipse, counter-clockwise.
      path.arcTo(
        Rect.fromCenter(
            center: Offset(cx, cy), width: 2 * r * factor, height: 2 * r),
        pi / 2,
        -pi,
        false,
      );
    } else {
      // Gibbous: left side of terminator ellipse, clockwise.
      path.arcTo(
        Rect.fromCenter(
            center: Offset(cx, cy), width: -2 * r * factor, height: 2 * r),
        pi / 2,
        pi,
        false,
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MoonPhasePainter old) =>
      old.tithiNumber != tithiNumber || old.litColor != litColor;
}
