import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Draws a dashed circular border around [child].
///
/// Signature element of the Atelier skin: category bubbles,
/// look thumbnails and bag counters sit inside dashed circles.
class DashedCircle extends StatelessWidget {
  final Widget child;
  final double size;
  final Color color;
  final double strokeWidth;
  final bool filled;

  const DashedCircle({
    super.key,
    required this.child,
    this.size = 72,
    this.color = AppTheme.dash,
    this.strokeWidth = 1.2,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _DashedCirclePainter(
        color: color,
        strokeWidth: strokeWidth,
        filled: filled,
      ),
      child: SizedBox.square(dimension: size, child: child),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool filled;

  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.filled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;

    if (filled) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = AppTheme.surface,
      );
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    const dashCount = 28;
    const gapRatio = 0.45;
    final sweep = (2 * math.pi / dashCount) * (1 - gapRatio);

    for (var i = 0; i < dashCount; i++) {
      final start = (2 * math.pi / dashCount) * i;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      filled != oldDelegate.filled;
}
