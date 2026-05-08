import 'package:flutter/material.dart';
import '../../simulator/logic_simulator.dart';
import '../circuit.dart';
import '../circuit_node.dart';
import '../wire.dart';
import 'io_nodes.dart';

class SubCircuitDefinition {
  final String name;
  final List<CircuitNode> nodes;
  final List<Wire> wires;
  final Color color;
  final List<String> inputLabels;
  final List<String> outputLabels;

  SubCircuitDefinition({
    required this.name,
    required this.nodes,
    required this.wires,
    this.color = const Color(0xff334155),
    this.inputLabels = const [],
    this.outputLabels = const [],
  });
}

class ComposedNode extends CircuitNode {
  final SubCircuitDefinition definition;
  late final List<CircuitNode> internalNodes;
  late final List<Wire> internalWires;
  late final Circuit internalCircuit;

  ComposedNode({
    required super.id,
    required super.position,
    required this.definition,
    required super.inputPins,
    required super.outputPins,
  }) {
    _initializeInternalCircuit();
  }

  void _initializeInternalCircuit() {
    final nodeMap = <String, CircuitNode>{};
    internalNodes = [];
    for (final node in definition.nodes) {
      final newNodeId = 'internal_${id}_${node.id}';
      final newNode = node.clone(newNodeId);
      nodeMap[node.id] = newNode;
      internalNodes.add(newNode);
    }

    internalWires = [];
    for (final wire in definition.wires) {
      internalWires.add(
        Wire(
          id: 'wire_${id}_${wire.id}',
          fromNodeId: nodeMap[wire.fromNodeId]!.id,
          fromPinId: wire.fromPinId,
          toNodeId: nodeMap[wire.toNodeId]!.id,
          toPinId: wire.toPinId,
        ),
      );
    }

    internalCircuit = Circuit(nodes: internalNodes, wires: internalWires);
  }

  @override
  Size get size {
    final maxPins = (inputPins.length > outputPins.length)
        ? inputPins.length
        : outputPins.length;
    final height = (maxPins * 24.0 + 40.0).clamp(80.0, 600.0);
    return Size(160, height);
  }

  @override
  void evaluate(List<bool> inputs) {
    final inputNodes = internalNodes.whereType<InputNode>().toList();
    for (int i = 0; i < inputNodes.length; i++) {
      if (i < inputs.length) {
        inputNodes[i].value = inputs[i];
      }
    }

    LogicSimulator.simulate(internalCircuit);

    final outputNodes = internalNodes.whereType<OutputNode>().toList();
    for (int i = 0; i < outputNodes.length; i++) {
      if (i < outputPins.length) {
        outputPins[i].value = outputNodes[i].value;
      }
    }
  }

  @override
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
    _drawPinLabels(canvas);
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

  void _drawPinLabels(Canvas canvas) {
    // Draw Input Labels
    for (int i = 0; i < inputPins.length; i++) {
      final pin = inputPins[i];
      final label = i < definition.inputLabels.length
          ? definition.inputLabels[i]
          : '';
      if (label.isEmpty) continue;

      _drawPinLabel(
        canvas,
        label,
        position + pin.localPosition + const Offset(10, -8),
        true,
      );
    }

    // Draw Output Labels
    for (int i = 0; i < outputPins.length; i++) {
      final pin = outputPins[i];
      final label = i < definition.outputLabels.length
          ? definition.outputLabels[i]
          : '';
      if (label.isEmpty) continue;

      _drawPinLabel(
        canvas,
        label,
        position + pin.localPosition + const Offset(-10, -8),
        false,
      );
    }
  }

  void _drawPinLabel(Canvas canvas, String text, Offset pos, bool isLeft) {
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

    final x = isLeft ? pos.dx : pos.dx - textPainter.width;
    textPainter.paint(canvas, Offset(x, pos.dy));
  }

  @override
  CircuitNode clone(String newId) {
    return ComposedNode(
      id: newId,
      position: position,
      definition: definition,
      inputPins: inputPins.map((p) => p.clone(newId)).toList(),
      outputPins: outputPins.map((p) => p.clone(newId)).toList(),
    );
  }
}
