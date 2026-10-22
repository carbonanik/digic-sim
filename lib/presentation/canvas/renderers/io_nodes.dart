import 'package:flutter/material.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/io_nodes.dart';

extension InputNodeRendering on InputNode {
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

    _drawLabel(canvas, label.isNotEmpty ? label : "INPUT");
    _drawValue(canvas);
  }

  void _drawLabel(Canvas canvas, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xffe5e7eb),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 96);
    textPainter.paint(canvas, position + const Offset(16, 14));
  }

  void _drawValue(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: value ? '1' : '0',
        style: TextStyle(
          color: value ? const Color(0xff86efac) : const Color(0xff94a3b8),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position + const Offset(16, 38));
  }
}

extension OutputNodeRendering on OutputNode {
  void paint(Canvas canvas, bool isSelected, {bool isHovered = false}) {
    final rect = RRect.fromRectAndRadius(this.rect, const Radius.circular(16));

    final fillPaint = Paint()
      ..color = value ? const Color(0xff1d4ed8) : const Color(0xff111827);

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

    _drawLabel(canvas, label.isNotEmpty ? label : "OUTPUT");
    _drawValue(canvas);
  }

  void _drawLabel(Canvas canvas, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xffe5e7eb),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 96);
    textPainter.paint(canvas, position + const Offset(16, 14));
  }

  void _drawValue(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: value ? '1' : '0',
        style: TextStyle(
          color: value ? const Color(0xff86efac) : const Color(0xff94a3b8),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position + const Offset(16, 38));
  }
}
