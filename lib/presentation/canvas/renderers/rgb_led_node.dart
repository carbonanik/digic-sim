import 'package:flutter/material.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/rgb_led_node.dart';

extension RGBLEDNodeRendering on RGBLEDNode {
  void paint(Canvas canvas, bool isSelected, {bool isHovered = false}) {
    final rect = RRect.fromRectAndRadius(this.rect, const Radius.circular(16));

    final fillPaint = Paint()..color = const Color(0xff0f172a);
    final borderPaint = Paint()
      ..color = isSelected
          ? const Color(0xfffacc15)
          : (isHovered ? const Color(0xff475569) : const Color(0xff334155))
      ..strokeWidth = isSelected ? 3 : 2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, borderPaint);

    // Draw LED
    final ledCenter = position + Offset(size.width / 2 + 10, 48);
    final ledRadius = 24.0;

    final ledColor = Color.fromARGB(
      255,
      r ? 255 : 30,
      g ? 255 : 30,
      b ? 255 : 30,
    );

    // Glow effect
    if (r || g || b) {
      final glowPaint = Paint()
        ..color = ledColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(ledCenter, ledRadius + 4, glowPaint);
    }

    final ledPaint = Paint()
      ..color = ledColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(ledCenter, ledRadius, ledPaint);

    // Reflection/Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ledCenter - const Offset(8, 8), 6, highlightPaint);

    // Labels
    _drawPinLabel(
      canvas,
      'R',
      position + inputPins[0].localPosition + const Offset(12, -6),
    );
    _drawPinLabel(
      canvas,
      'G',
      position + inputPins[1].localPosition + const Offset(12, -6),
    );
    _drawPinLabel(
      canvas,
      'B',
      position + inputPins[2].localPosition + const Offset(12, -6),
    );
  }

  void _drawPinLabel(Canvas canvas, String text, Offset pos) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xff94a3b8),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }
}
