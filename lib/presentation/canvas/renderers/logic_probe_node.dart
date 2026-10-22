import 'package:flutter/material.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/logic_probe_node.dart';

extension LogicProbeNodeRendering on LogicProbeNode {
  void paint(Canvas canvas, bool isSelected, {bool isHovered = false}) {
    final rect = RRect.fromRectAndRadius(this.rect, const Radius.circular(24));

    final fillPaint = Paint()..color = const Color(0xff0f172a);
    final borderPaint = Paint()
      ..color = isSelected
          ? const Color(0xfffacc15)
          : (isHovered ? const Color(0xff475569) : const Color(0xff334155))
      ..strokeWidth = isSelected ? 3 : 2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, borderPaint);

    // Indicator Light
    final indicatorCenter = position + const Offset(60, 32);
    final lightPaint = Paint()
      ..color = value ? const Color(0xff22c55e) : const Color(0xffef4444)
      ..style = PaintingStyle.fill;

    // Light glow
    final glowPaint = Paint()
      ..color = (value ? const Color(0xff22c55e) : const Color(0xffef4444))
          .withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(indicatorCenter, 10, glowPaint);

    canvas.drawCircle(indicatorCenter, 6, lightPaint);

    // Text Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: value ? 'HIGH' : 'LOW',
        style: TextStyle(
          color: value ? const Color(0xff22c55e) : const Color(0xffef4444),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      position + Offset(16, (size.height - textPainter.height) / 2),
    );
  }
}
