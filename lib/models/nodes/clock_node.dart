import 'package:flutter/material.dart';
import '../circuit_node.dart';
import '../pin.dart';

class ClockNode extends CircuitNode {
  bool value = false;
  double frequency = 1.0; // Hz

  ClockNode({
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

    _drawLabel(canvas);
    _drawPulseIcon(canvas);
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

  @override
  CircuitNode clone(String newId) {
    return ClockNode(
      id: newId,
      position: position,
      value: value,
      inputPins: inputPins.map((p) => p.clone(newId)).toList(),
      outputPins: outputPins.map((p) => p.clone(newId)).toList(),
    )..frequency = frequency;
  }
}
