import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tindascan/core/theme/app_tokens.dart';

/// Calm animated success mark: a circle draws in, then the check strokes
/// in. Static when animations are disabled.
class SuccessCheck extends StatelessWidget {
  const SuccessCheck({this.size = 88, this.semanticLabel, super.key});

  final double size;
  final String? semanticLabel;

  static const Duration _duration = Duration(milliseconds: 700);

  @override
  Widget build(BuildContext context) {
    final color = context.tokens.success;
    final animate = context.motion.enabled;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: animate ? 0 : 1, end: 1),
        duration: animate ? _duration : Duration.zero,
        curve: AppMotion.enter,
        builder: (context, t, _) => CustomPaint(
          size: Size.square(size),
          painter: _CheckPainter(progress: t, color: color),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.08;
    final rect = Offset.zero & size;
    final circleT = (progress / 0.6).clamp(0.0, 1.0);
    final checkT = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);

    canvas
      ..drawCircle(
        rect.center,
        size.width / 2,
        Paint()..color = color.withValues(alpha: 0.12 * circleT),
      )
      ..drawArc(
        rect.deflate(stroke / 2),
        -math.pi / 2,
        2 * math.pi * circleT,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );

    if (checkT <= 0) return;
    final p1 = Offset(size.width * 0.28, size.height * 0.53);
    final p2 = Offset(size.width * 0.44, size.height * 0.68);
    final p3 = Offset(size.width * 0.73, size.height * 0.38);
    final first = (checkT / 0.4).clamp(0.0, 1.0);
    final second = ((checkT - 0.4) / 0.6).clamp(0.0, 1.0);
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(
        p1.dx + (p2.dx - p1.dx) * first,
        p1.dy + (p2.dy - p1.dy) * first,
      );
    if (second > 0) {
      path.lineTo(
        p2.dx + (p3.dx - p2.dx) * second,
        p2.dy + (p3.dy - p2.dy) * second,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}
