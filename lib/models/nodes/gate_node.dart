import 'package:flutter/material.dart';
import '../circuit_node.dart';
import '../gate_type.dart';
import '../pin.dart';

class GateNode extends CircuitNode {
  final GateType type;

  GateNode({
    required super.id,
    required super.position,
    required super.inputPins,
    required super.outputPins,
    required this.type,
  });

  @override
  void evaluate(List<bool> inputs) {
    bool result = false;
    switch (type) {
      case GateType.and:
        result = inputs.length >= 2 && inputs.every((v) => v);
        break;
      case GateType.or:
        result = inputs.any((v) => v);
        break;
      case GateType.not:
        result = inputs.isNotEmpty ? !inputs.first : true;
        break;
      case GateType.nand:
        result = !(inputs.length >= 2 && inputs.every((v) => v));
        break;
      case GateType.nor:
        result = !inputs.any((v) => v);
        break;
      case GateType.xor:
        result = inputs.where((v) => v).length.isOdd;
        break;
      default:
        break;
    }
    
    if (outputPins.isNotEmpty) {
      outputPins.first.value = result;
    }
  }

  @override
  void paint(Canvas canvas, bool isSelected) {
    final rect = RRect.fromRectAndRadius(
      this.rect,
      const Radius.circular(16),
    );

    final fillPaint = Paint()..color = const Color(0xff111827);
    final borderPaint = Paint()
      ..color = isSelected ? const Color(0xfffacc15) : const Color(0xff475569)
      ..strokeWidth = isSelected ? 3 : 2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, borderPaint);

    _drawLabel(canvas);
  }

  void _drawLabel(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: type.label,
        style: const TextStyle(
          color: Color(0xffe5e7eb),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    canvas.save();
    canvas.translate(position.dx + 16, position.dy + 14);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
