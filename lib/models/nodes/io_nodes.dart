import 'package:flutter/material.dart';
import '../circuit_node.dart';
import '../pin.dart';

class InputNode extends CircuitNode {
  bool value;

  InputNode({
    required super.id,
    required super.position,
    required super.inputPins,
    required super.outputPins,
    this.value = false,
  });

  @override
  void evaluate(List<bool> inputs) {
    if (outputPins.isNotEmpty) {
      outputPins.first.value = value;
    }
  }

  @override
  bool onAction(Offset localPosition) {
    // Toggle value when clicked
    value = !value;
    return true;
  }

  @override
  void paint(Canvas canvas, bool isSelected) {
    final rect = RRect.fromRectAndRadius(
      this.rect,
      const Radius.circular(16),
    );

    final fillPaint = Paint()
      ..color = value ? const Color(0xff14532d) : const Color(0xff111827);
    
    final borderPaint = Paint()
      ..color = isSelected ? const Color(0xfffacc15) : const Color(0xff475569)
      ..strokeWidth = isSelected ? 3 : 2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, borderPaint);

    _drawLabel(canvas, "INPUT");
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
    textPainter.layout();
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

class OutputNode extends CircuitNode {
  bool value = false;

  OutputNode({
    required super.id,
    required super.position,
    required super.inputPins,
    required super.outputPins,
  });

  @override
  void evaluate(List<bool> inputs) {
    value = inputs.isNotEmpty ? inputs.first : false;
    if (outputPins.isNotEmpty) {
      outputPins.first.value = value;
    }
  }

  @override
  void paint(Canvas canvas, bool isSelected) {
    final rect = RRect.fromRectAndRadius(
      this.rect,
      const Radius.circular(16),
    );

    final fillPaint = Paint()
      ..color = value ? const Color(0xff1d4ed8) : const Color(0xff111827);
    
    final borderPaint = Paint()
      ..color = isSelected ? const Color(0xfffacc15) : const Color(0xff475569)
      ..strokeWidth = isSelected ? 3 : 2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, borderPaint);

    _drawLabel(canvas, "OUTPUT");
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
    textPainter.layout();
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
