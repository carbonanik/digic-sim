import 'package:digital_logic_sim_2/controllers/circuit_controller.dart';
import 'package:flutter/material.dart';
import '../models/circuit.dart';
import '../models/circuit_node.dart';
import '../models/pin.dart';
import '../models/wire.dart';
import '../models/gate_type.dart';
import '../models/nodes/gate_node.dart';
import '../models/nodes/composed_node.dart';
import '../models/nodes/io_nodes.dart';
import '../utils/pathfinder.dart';
import 'editor_tools.dart';
import 'hit_test.dart';

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xff1e293b)
      ..strokeWidth = 1;

    const gridSize = 16.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => false;
}

class CircuitPainter extends CustomPainter {
  final Circuit circuit;
  final Set<String> selectedNodeIds;
  final String? selectedWireId;
  final int repaintCounter;

  CircuitPainter({
    required this.circuit,
    required this.selectedNodeIds,
    this.selectedWireId,
    required this.repaintCounter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWires(canvas);
    _drawNodes(canvas);
  }

  void _drawWires(Canvas canvas) {
    final obstacles = circuit.nodes.map((n) => n.rect).toList();
    final allSegments = <WireSegment>{};

    for (final wire in circuit.wires) {
      final start = _getWireStart(wire);
      final end = _getWireEnd(wire);

      if (start == null || end == null) continue;

      final isSelected = wire.id == selectedWireId;

      if (isSelected) {
        final glowPaint = Paint()
          ..color = const Color(0xfff43f5e).withOpacity(0.3)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        _drawWire(canvas, wire, start, end, glowPaint, obstacles, allSegments);
      }

      final paint = Paint()
        ..color = isSelected ? const Color(0xfff43f5e) : const Color(0xff38bdf8)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;

      final points = _drawWire(
        canvas,
        wire,
        start,
        end,
        paint,
        obstacles,
        allSegments,
      );

      for (int i = 0; i < points.length - 1; i++) {
        _addSegments(allSegments, points[i], points[i + 1]);
      }

      if (isSelected && wire.waypoints.isNotEmpty) {
        final handlePaint = Paint()
          ..color = const Color(0xfff43f5e)
          ..style = PaintingStyle.fill;
        final handleBorder = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        for (final wp in wire.waypoints) {
          canvas.drawCircle(wp, 5, handlePaint);
          canvas.drawCircle(wp, 5, handleBorder);
        }
      }
    }
  }

  List<Offset> _drawWire(
    Canvas canvas,
    Wire wire,
    Offset start,
    Offset end,
    Paint paint,
    List<Rect> obstacles,
    Set<WireSegment> existingSegments,
  ) {
    final points = wire.getPathPoints(
      start,
      end,
      obstacles: obstacles,
      existingSegments: existingSegments,
    );

    if (points.isEmpty) return [];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
    return points;
  }

  void _addSegments(Set<WireSegment> segments, Offset p1, Offset p2) {
    const gridSize = 16.0;
    final dist = (p1 - p2).distance;
    if (dist < 0.1) return;

    final dir = (p2 - p1) / dist;
    final steps = (dist / gridSize).round();

    for (int i = 0; i < steps; i++) {
      final s1 = p1 + dir * (i * gridSize);
      final s2 = p1 + dir * ((i + 1) * gridSize);
      segments.add(WireSegment(s1, s2));
    }
  }

  void _drawNodes(Canvas canvas) {
    for (final node in circuit.nodes) {
      final isSelected = selectedNodeIds.contains(node.id);
      node.paint(canvas, isSelected);
      _drawPins(canvas, node);
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
    final radius = 7.0;

    final paint = Paint()
      ..color = pin.isInput ? const Color(0xfff97316) : const Color(0xff22c55e)
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = const Color(0xffe5e7eb)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(position, radius, paint);
    canvas.drawCircle(position, radius, border);
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
    return oldDelegate.repaintCounter != repaintCounter;
  }
}

class OverlayPainter extends CustomPainter {
  final Circuit circuit;
  final PinSelection? wireStart;
  final Offset? temporaryWireEnd;
  final Rect? selectionRect;
  final String? hoveredNodeId;
  final PinHit? hoveredPin;
  final Offset? mousePosition;
  final EditorTool selectedTool;
  final SubCircuitDefinition? selectedCustomComponent;
  final int repaintCounter;

  OverlayPainter({
    required this.circuit,
    this.wireStart,
    this.temporaryWireEnd,
    this.selectionRect,
    this.hoveredNodeId,
    this.hoveredPin,
    this.mousePosition,
    required this.selectedTool,
    this.selectedCustomComponent,
    required this.repaintCounter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawHoverEffects(canvas);
    _drawTemporaryWire(canvas);
    _drawSelectionRect(canvas);
    _drawGhost(canvas);
  }

  void _drawHoverEffects(Canvas canvas) {
    if (hoveredNodeId != null) {
      final node = circuit.nodes
          .where((n) => n.id == hoveredNodeId)
          .firstOrNull;
      if (node != null) {
        node.paint(canvas, false, isHovered: true);
      }
    }

    if (hoveredPin != null) {
      final node = hoveredPin!.node;
      final pin = hoveredPin!.pin;
      final position = node.position + pin.localPosition;
      const radius = 9.0;

      final paint = Paint()
        ..color = pin.isInput
            ? const Color(0xfff97316)
            : const Color(0xff22c55e)
        ..style = PaintingStyle.fill;

      final border = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      final glow = Paint()
        ..color =
            (pin.isInput ? const Color(0xfff97316) : const Color(0xff22c55e))
                .withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(position, radius + 2, glow);
      canvas.drawCircle(position, radius, paint);
      canvas.drawCircle(position, radius, border);
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

    final obstacles = circuit.nodes.map((n) => n.rect).toList();
    final points = PathFinder.findPath(
      start: start,
      end: temporaryWireEnd!,
      obstacles: obstacles,
    );
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawSelectionRect(Canvas canvas) {
    if (selectionRect == null) return;
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
      final height = (maxPins * 16.0 + 32.0).clamp(80.0, 640.0);
      size = Size(160, height);
    } else {
      size = isDisplay ? const Size(80, 128) : const Size(112, 64);
    }

    final ghostPaint = Paint()..color = Colors.white.withOpacity(0.35);

    // Avoid saveLayer by using opacity in the child components or drawing with opacity paint
    // For simplicity, we wrap the drawing in a layer-like logic but without saveLayer if possible
    // Here we can just pass the opacity paint to GateNode.paintGate or equivalent

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

    final fillPaint = Paint()
      ..color = const Color(0xff1e293b).withOpacity(0.35);
    final borderPaint = Paint()
      ..color = const Color(0xff94a3b8).withOpacity(0.35)
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
            localPosition: const Offset(0, 16),
          ),
        if (gateType != GateType.not)
          Pin(
            id: 'b',
            nodeId: 'ghost',
            isInput: true,
            localPosition: const Offset(0, 48),
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
          localPosition: const Offset(112, 32),
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
          ? (Paint()..color = selectedCustomComponent!.color.withOpacity(0.35))
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
            color: const Color(0xfff8fafc).withOpacity(0.35),
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
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) {
    return oldDelegate.repaintCounter != repaintCounter;
  }
}
