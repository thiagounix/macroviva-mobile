import 'dart:math' as math;

import 'package:flutter/material.dart';

class ProteinProgressRing extends StatelessWidget {
  const ProteinProgressRing({
    super.key,
    required this.consumed,
    required this.target,
  });

  final double consumed;
  final double target;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : consumed / target;
    final percent = (progress * 100).round();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _ProteinRingPainter(
          progress: progress,
          trackColor: colorScheme.primary.withValues(alpha: 0.10),
          progressColor: colorScheme.primary,
          overflowColor: const Color(0xFFFFB84D),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Proteína',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${consumed.toStringAsFixed(0)}g / ${target.toStringAsFixed(0)}g',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProteinRingPainter extends CustomPainter {
  const _ProteinRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.overflowColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color overflowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.09;
    final rect = Offset.zero & size;
    final ringRect = rect.deflate(strokeWidth / 2);
    const startAngle = -math.pi / 2;
    const fullCircle = math.pi * 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + fullCircle,
        colors: const [Color(0xFF0F7B63), Color(0xFF35D39A)],
      ).createShader(ringRect);

    final overflowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.52
      ..strokeCap = StrokeCap.round
      ..color = overflowColor;

    canvas.drawArc(ringRect, 0, fullCircle, false, trackPaint);
    canvas.drawArc(
      ringRect,
      startAngle,
      fullCircle * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );

    if (progress > 1) {
      final overflow = (progress - 1).clamp(0.0, 1.0);
      canvas.drawArc(
        ringRect.deflate(strokeWidth * 0.72),
        startAngle,
        fullCircle * overflow,
        false,
        overflowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProteinRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.overflowColor != overflowColor;
  }
}
