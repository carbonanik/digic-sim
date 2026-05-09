import 'package:digital_logic_sim_2/editor/editor_tools.dart';
import 'package:digital_logic_sim_2/editor/hit_test.dart';
import 'package:flutter/material.dart';

import '../controllers/circuit_controller.dart';
import '../models/circuit.dart';
import '../models/circuit_node.dart';
import '../models/pin.dart';
import '../models/wire.dart';
import '../models/gate_type.dart';
import '../models/nodes/gate_node.dart';
import '../models/nodes/composed_node.dart';
import '../models/nodes/io_nodes.dart';

class CircuitPainter extends CustomPainter {
  final Circuit circuit;
  final Set<String> selectedNodeIds;
  final String? selectedWireId;
  final PinSelection? wireStart;
  final Offset? temporaryWireEnd;
  final Rect? selectionRect;
  final String? hoveredNodeId;
  final PinHit? hoveredPin;
  final Offset? mousePosition;
  final EditorTool selectedTool;
  final SubCircuitDefinition? selectedCustomComponent;

  CircuitPainter({
    required this.circuit,
    required this.selectedNodeIds,
    this.selectedWireId,
    this.wireStart,
    this.temporaryWireEnd,
    this.selectionRect,
    this.hoveredNodeId,
    this.hoveredPin,
    this.mousePosition,
    required this.selectedTool,
    this.selectedCustomComponent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawWires(canvas);
    _drawTemporaryWire(canvas);
    _drawNodes(canvas);
    _drawGhost(canvas);
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
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        _drawOrthogonalWire(canvas, start, end, glowPaint);
      }

      final paint = Paint()
        ..color = isSelected ? const Color(0xfff43f5e) : const Color(0xff38bdf8)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;

      _drawOrthogonalWire(canvas, start, end, paint);
    }
  }

  void _drawTemporaryWire(Canvas canvas) {
    if (wireStart == null || temporaryWireEnd == null) return;

    final start = wireStart!.node.position + wireStart!.pin.localPosition;

    final paint = Paint()
      ..color = const Color(0xfffacc15)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    _drawOrthogonalWire(canvas, start, temporaryWireEnd!, paint);
  }

  void _drawOrthogonalWire(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    final path = Path()..moveTo(start.dx, start.dy);

    const minExtension = 16.0;

    if (end.dx > start.dx + 2 * minExtension) {
      final midX = (start.dx + end.dx) / 2;
      path
        ..lineTo(midX, start.dy)
        ..lineTo(midX, end.dy)
        ..lineTo(end.dx, end.dy);
    } else {
      final midY = (start.dy + end.dy) / 2;
      final outX = start.dx + minExtension;
      final inX = end.dx - minExtension;

      path
        ..lineTo(outX, start.dy)
        ..lineTo(outX, midY)
        ..lineTo(inX, midY)
        ..lineTo(inX, end.dy)
        ..lineTo(end.dx, end.dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawNodes(Canvas canvas) {
    for (final node in circuit.nodes) {
      final isSelected = selectedNodeIds.contains(node.id);
      final isHovered = node.id == hoveredNodeId;
      node.paint(canvas, isSelected, isHovered: isHovered);
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
    final isHovered =
        hoveredPin?.pin.id == pin.id && hoveredPin?.node.id == node.id;

    final radius = isHovered ? 9.0 : 7.0;

    final paint = Paint()
      ..color = pin.isInput ? const Color(0xfff97316) : const Color(0xff22c55e)
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = isHovered ? Colors.white : const Color(0xffe5e7eb)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 2.5 : 2;

    if (isHovered) {
      final glow = Paint()
        ..color =
            (pin.isInput ? const Color(0xfff97316) : const Color(0xff22c55e))
                .withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(position, radius + 2, glow);
    }

    canvas.drawCircle(position, radius, paint);
    canvas.drawCircle(position, radius, border);
  }

  void _drawGhost(Canvas canvas) {
    if (mousePosition == null) return;
    if (selectedTool == EditorTool.select || selectedTool == EditorTool.wire)
      return;

    final ghostPos = mousePosition!;
    final isDisplay = selectedTool == EditorTool.segmentDisplay;
    final isCustom =
        selectedTool == EditorTool.custom && selectedCustomComponent != null;

    Size size;
    if (isCustom) {
      final inputCount = selectedCustomComponent!.nodes
          .whereType<InputNode>()
          .length;
      final outputCount = selectedCustomComponent!.nodes
          .whereType<OutputNode>()
          .length;
      final maxPins = (inputCount > outputCount) ? inputCount : outputCount;
      final height = (maxPins * 24.0 + 40.0).clamp(80.0, 600.0);
      size = Size(160, height);
    } else {
      size = isDisplay ? const Size(80, 120) : const Size(110, 64);
    }

    canvas.saveLayer(
      Rect.fromLTWH(
        ghostPos.dx,
        ghostPos.dy,
        size.width + 10,
        size.height + 10,
      ),
      Paint()..color = Colors.white.withOpacity(0.35),
    );

    GateType? gateType;
    switch (selectedTool) {
      case EditorTool.and:
        gateType = GateType.and;
        break;
      case EditorTool.or:
        gateType = GateType.or;
        break;
      case EditorTool.not:
        gateType = GateType.not;
        break;
      case EditorTool.nand:
        gateType = GateType.nand;
        break;
      case EditorTool.nor:
        gateType = GateType.nor;
        break;
      case EditorTool.xor:
        gateType = GateType.xor;
        break;
      default:
        break;
    }

    final fillPaint = Paint()..color = const Color(0xff1e293b);
    final borderPaint = Paint()
      ..color = const Color(0xff94a3b8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    if (gateType != null) {
      final extraPaint = Paint()
        ..color = borderPaint.color
        ..strokeWidth = borderPaint.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final inputPins = <Pin>[
        if (gateType != GateType.not)
          Pin(
            id: 'a',
            nodeId: 'ghost',
            isInput: true,
            localPosition: const Offset(0, 22),
          ),
        if (gateType != GateType.not)
          Pin(
            id: 'b',
            nodeId: 'ghost',
            isInput: true,
            localPosition: const Offset(0, 42),
          ),
        if (gateType == GateType.not)
          Pin(
            id: 'in',
            nodeId: 'ghost',
            isInput: true,
            localPosition: const Offset(0, 32),
          ),
      ];

      final outputPins = <Pin>[
        Pin(
          id: 'out',
          nodeId: 'ghost',
          isInput: false,
          localPosition: const Offset(110, 32),
        ),
      ];

      GateNode.paintGate(
        canvas: canvas,
        rect: Rect.fromLTWH(ghostPos.dx, ghostPos.dy, size.width, size.height),
        position: ghostPos,
        type: gateType,
        inputPins: inputPins,
        outputPins: outputPins,
        fillPaint: fillPaint,
        borderPaint: borderPaint,
        extraPaint: extraPaint,
      );
    } else {
      final ghostRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(ghostPos.dx, ghostPos.dy, size.width, size.height),
        Radius.circular(isDisplay ? 8 : (isCustom ? 12 : 16)),
      );

      final fillP = isCustom
          ? (Paint()..color = selectedCustomComponent!.color)
          : fillPaint;

      canvas.drawRRect(ghostRect, fillP);
      canvas.drawRRect(ghostRect, borderPaint);

      final label = isCustom
          ? selectedCustomComponent!.name
          : (isDisplay ? '7-SEG' : selectedTool.name.toUpperCase());

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: const Color(0xfff8fafc),
            fontSize: isCustom ? 15 : 14,
            fontWeight: isCustom ? FontWeight.w900 : FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: size.width - 20);
      textPainter.paint(
        canvas,
        ghostPos +
            Offset(
              (size.width - textPainter.width) / 2,
              isDisplay || isCustom ? 10 : 22,
            ),
      );
    }

    canvas.restore();
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
