import 'package:digital_logic_sim_2/models/pin.dart';
import 'package:flutter/material.dart';
import '../circuit_node.dart';

enum Gate { and, or, not, nand, nor, xor }

class GateNode extends CircuitNode {
  final Gate type;

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
      case Gate.and:
        result = inputs.length >= 2 && inputs.every((v) => v);
        break;
      case Gate.or:
        result = inputs.any((v) => v);
        break;
      case Gate.not:
        result = inputs.isNotEmpty ? !inputs.first : true;
        break;
      case Gate.nand:
        result = !(inputs.length >= 2 && inputs.every((v) => v));
        break;
      case Gate.nor:
        result = !inputs.any((v) => v);
        break;
      case Gate.xor:
        result = inputs.where((v) => v).length.isOdd;
        break;
    }

    if (outputPins.isNotEmpty) {
      outputPins.first.value = result;
    }
  }

  static void paintGate({
    required Canvas canvas,
    required Rect rect,
    required Offset position,
    required Gate type,
    required Iterable<Pin> inputPins,
    required Iterable<Pin> outputPins,
    required Paint fillPaint,
    required Paint borderPaint,
    required Paint extraPaint,
    Paint? hoverGlow,
  }) {
    final double left = rect.left + 24;
    final double top = rect.top + 8;
    final double right = rect.right - 24;
    final double bottom = rect.bottom - 8;
    final double h = bottom - top;
    final double w = right - left;

    final path = Path();
    final extraPaths = Path();

    // Leads for inputs
    for (final pin in inputPins) {
      final pinPos = position + pin.localPosition;
      extraPaths.moveTo(pinPos.dx, pinPos.dy);
      extraPaths.lineTo(position.dx + rect.width * 0.5, pinPos.dy);
    }

    // Leads for outputs
    for (final pin in outputPins) {
      final pinPos = position + pin.localPosition;
      extraPaths.moveTo(position.dx + rect.width * 0.5, pinPos.dy);
      extraPaths.lineTo(pinPos.dx, pinPos.dy);
    }

    bool hasBubble = type == Gate.not || type == Gate.nand || type == Gate.nor;
    double shapeRight = right;
    if (hasBubble) {
      shapeRight -= 10;
    }

    switch (type) {
      case Gate.and:
      case Gate.nand:
        final flatRight = shapeRight - h / 2;
        path.moveTo(left, top);
        path.lineTo(flatRight, top);
        path.arcToPoint(
          Offset(flatRight, bottom),
          radius: Radius.circular(h / 2),
          clockwise: true,
        );
        path.lineTo(left, bottom);
        path.close();
        break;

      case Gate.or:
      case Gate.nor:
      case Gate.xor:
        final backCurveCtrlX = left + w * 0.3;
        path.moveTo(left, top);
        path.quadraticBezierTo(left + w * 0.6, top, shapeRight, top + h / 2);
        path.quadraticBezierTo(left + w * 0.6, bottom, left, bottom);
        path.quadraticBezierTo(backCurveCtrlX, top + h / 2, left, top);
        path.close();

        if (type == Gate.xor) {
          extraPaths.moveTo(left - 8, top);
          extraPaths.quadraticBezierTo(
            backCurveCtrlX - 8,
            top + h / 2,
            left - 8,
            bottom,
          );
        }
        break;

      case Gate.not:
        path.moveTo(left, top + 6);
        path.lineTo(shapeRight, top + h / 2);
        path.lineTo(left, bottom - 6);
        path.close();
        break;
    }

    if (hasBubble) {
      path.addOval(
        Rect.fromCircle(center: Offset(shapeRight + 5, top + h / 2), radius: 5),
      );
    }

    // Draw leads (underneath body)
    canvas.drawPath(extraPaths, extraPaint);

    // Draw filled body
    canvas.drawPath(path, fillPaint);

    if (hoverGlow != null) {
      canvas.drawPath(path, hoverGlow);
    }

    // Draw body outline
    canvas.drawPath(path, borderPaint);
  }

  @override
  void paint(Canvas canvas, bool isSelected, {bool isHovered = false}) {
    final fillPaint = Paint()..color = const Color(0xff111827);
    final borderPaint = Paint()
      ..color = isSelected
          ? const Color(0xfffacc15)
          : (isHovered ? const Color(0xff64748b) : const Color(0xff475569))
      ..strokeWidth = isSelected ? 3 : (isHovered ? 2.5 : 2)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final extraPaint = Paint()
      ..color = borderPaint.color
      ..strokeWidth = borderPaint.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Paint? hoverGlow;
    if (isHovered && !isSelected) {
      hoverGlow = Paint()
        ..color = const Color(0xff64748b).withOpacity(0.3)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    }

    paintGate(
      canvas: canvas,
      rect: rect,
      position: position,
      type: type,
      inputPins: inputPins,
      outputPins: outputPins,
      fillPaint: fillPaint,
      borderPaint: borderPaint,
      extraPaint: extraPaint,
      hoverGlow: hoverGlow,
    );
  }

  @override
  CircuitNode clone(String newId) {
    return GateNode(
      id: newId,
      position: position,
      type: type,
      inputPins: inputPins.map((p) => p.clone(newId)).toList(),
      outputPins: outputPins.map((p) => p.clone(newId)).toList(),
    );
  }

  @override
  Map<String, dynamic> toMap({bool isNested = false}) {
    return {
      ...super.toMap(isNested: isNested),
      'type': 'gate',
      'gateType': type.name,
    };
  }
}
