import 'package:flutter/material.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';

extension ComposedNodeRendering on ComposedNode {
  void paint(Canvas canvas, bool isSelected, {bool isHovered = false}) {
    final rect = RRect.fromRectAndRadius(this.rect, const Radius.circular(12));

    final fillPaint = Paint()..color = definition.color;
    final borderPaint = Paint()
      ..color = isSelected
          ? const Color(0xfffacc15)
          : (isHovered ? const Color(0xff94a3b8) : const Color(0xff475569))
      ..strokeWidth = isSelected ? 3 : (isHovered ? 2.5 : 2)
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rect, fillPaint);

    if (isHovered && !isSelected) {
      final hoverGlow = Paint()
        ..color = const Color(0xff94a3b8).withOpacity(0.3)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawRRect(rect, hoverGlow);
    }

    canvas.drawRRect(rect, borderPaint);

    _drawLabel(canvas);
  }

  void _drawLabel(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: definition.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width - 20);
    textPainter.paint(
      canvas,
      position + Offset((size.width - textPainter.width) / 2, 10),
    );
  }
}
