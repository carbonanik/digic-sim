import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/clock_node.dart';

extension ClockNodeRendering on ClockNode {
  void paint(Canvas canvas, bool isSelected, {bool isHovered = false}) {
    final rect = RRect.fromRectAndRadius(this.rect, const Radius.circular(16));

    final fillPaint = Paint()
      ..color = value ? const Color(0xff14532d) : const Color(0xff111827);

    final borderPaint = Paint()
      ..color = isSelected
          ? const Color(0xfffacc15)
          : (isHovered ? const Color(0xff64748b) : const Color(0xff475569))
      ..strokeWidth = isSelected ? 3 : (isHovered ? 2.5 : 2)
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rect, fillPaint);

    if (isHovered && !isSelected) {
      final hoverGlow = Paint()
        ..color = const Color(0xff64748b).withOpacity(0.3)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawRRect(rect, hoverGlow);
    }

    canvas.drawRRect(rect, borderPaint);

    _drawLabel(canvas);
    _drawPulseIcon(canvas);
    _drawKnob(canvas);
  }

  void _drawLabel(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'CLOCK',
        style: const TextStyle(
          color: Color(0xffe5e7eb),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position + const Offset(16, 14));
  }

  void _drawPulseIcon(Canvas canvas) {
    final paint = Paint()
      ..color = value ? const Color(0xff86efac) : const Color(0xff94a3b8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(position.dx + 16, position.dy + 48)
      ..lineTo(position.dx + 26, position.dy + 48)
      ..lineTo(position.dx + 26, position.dy + 38)
      ..lineTo(position.dx + 36, position.dy + 38)
      ..lineTo(position.dx + 36, position.dy + 48)
      ..lineTo(position.dx + 46, position.dy + 48);

    canvas.drawPath(path, paint);
  }

  void _drawKnob(Canvas canvas) {
    final center = position + const Offset(80, 40);
    final paint = Paint()
      ..color = const Color(0xff334155)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 14, paint);

    final borderPaint = Paint()
      ..color = const Color(0xff94a3b8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 14, borderPaint);

    int index = ClockNode.frequencies.indexOf(frequency);
    if (index == -1) index = 0;
    final total = ClockNode.frequencies.length;
    final double angle =
        -math.pi * 0.75 + (index / (total - 1)) * (math.pi * 1.5);
    final indicatorPaint = Paint()
      ..color = const Color(0xfffacc15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final indicatorStart = center;
    final indicatorEnd = center + Offset(math.cos(angle), math.sin(angle)) * 9;
    canvas.drawLine(indicatorStart, indicatorEnd, indicatorPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${frequency >= 1.0 ? frequency.toInt() : frequency}Hz',
        style: const TextStyle(
          color: Color(0xffe5e7eb),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, center + Offset(-textPainter.width / 2, -28));
  }
}
