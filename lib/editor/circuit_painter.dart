import 'package:flutter/material.dart';

import '../controllers/circuit_controller.dart';
import '../models/circuit.dart';
import '../models/circuit_node.dart';
import '../models/pin.dart';
import '../models/wire.dart';

class CircuitPainter extends CustomPainter {
  final Circuit circuit;
  final Set<String> selectedNodeIds;
  final String? selectedWireId;
  final PinSelection? wireStart;
  final Offset? temporaryWireEnd;
  final Rect? selectionRect;

  CircuitPainter({
    required this.circuit,
    required this.selectedNodeIds,
    this.selectedWireId,
    this.wireStart,
    this.temporaryWireEnd,
    this.selectionRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawWires(canvas);
    _drawTemporaryWire(canvas);
    _drawNodes(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xff1e293b)
      ..strokeWidth = 1;

    const gridSize = 32.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawWires(Canvas canvas) {
    for (final wire in circuit.wires) {
      final start = _getWireStart(wire);
      final end = _getWireEnd(wire);

      if (start == null || end == null) continue;

      final isSelected = wire.id == selectedWireId;

      if (isSelected) {
        // Draw glow for selected wire
        final glowPaint = Paint()
          ..color = const Color(0xfff43f5e).withOpacity(0.3)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        _drawSmoothWire(canvas, start, end, glowPaint);
      }

      final paint = Paint()
        ..color = isSelected ? const Color(0xfff43f5e) : const Color(0xff38bdf8)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      _drawSmoothWire(canvas, start, end, paint);
    }
  }

  void _drawTemporaryWire(Canvas canvas) {
    if (wireStart == null || temporaryWireEnd == null) return;

    final start = wireStart!.node.position + wireStart!.pin.localPosition;

    final paint = Paint()
      ..color = const Color(0xfffacc15)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawSmoothWire(canvas, start, temporaryWireEnd!, paint);
  }

  void _drawSmoothWire(Canvas canvas, Offset start, Offset end, Paint paint) {
    final distance = (end.dx - start.dx).abs();
    final controlOffset = distance.clamp(50, 140).toDouble();

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + controlOffset,
        start.dy,
        end.dx - controlOffset,
        end.dy,
        end.dx,
        end.dy,
      );

    canvas.drawPath(path, paint);
  }

  void _drawNodes(Canvas canvas) {
    for (final node in circuit.nodes) {
      final isSelected = selectedNodeIds.contains(node.id);
      node.paint(canvas, isSelected);
      _drawPins(canvas, node);
    }

    if (selectionRect != null) {
      final paint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(selectionRect!, paint);

      final borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(selectionRect!, borderPaint);
    }
  }

  void _drawPins(Canvas canvas, CircuitNode node) {
    for (final pin in node.inputPins) {
      _drawPin(canvas, node, pin);
    }

    for (final pin in node.outputPins) {
      _drawPin(canvas, node, pin);
    }
  }

  void _drawPin(Canvas canvas, CircuitNode node, Pin pin) {
    final position = node.position + pin.localPosition;

    final paint = Paint()
      ..color = pin.isInput ? const Color(0xfff97316) : const Color(0xff22c55e)
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = const Color(0xffe5e7eb)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(position, 7, paint);
    canvas.drawCircle(position, 7, border);
  }

  Offset? _getWireStart(Wire wire) {
    final node = _findNode(wire.fromNodeId);
    if (node == null) return null;

    final pin = node.outputPins
        .where((p) => p.id == wire.fromPinId)
        .firstOrNull;
    if (pin == null) return null;

    return node.position + pin.localPosition;
  }

  Offset? _getWireEnd(Wire wire) {
    final node = _findNode(wire.toNodeId);
    if (node == null) return null;

    final pin = node.inputPins.where((p) => p.id == wire.toPinId).firstOrNull;
    if (pin == null) return null;

    return node.position + pin.localPosition;
  }

  CircuitNode? _findNode(String id) {
    for (final node in circuit.nodes) {
      if (node.id == id) return node;
    }

    return null;
  }

  @override
  bool shouldRepaint(covariant CircuitPainter oldDelegate) {
    return true;
  }
}
