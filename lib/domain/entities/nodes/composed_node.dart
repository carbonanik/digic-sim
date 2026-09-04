import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit_node.dart';
import 'package:digital_logic_sim_2/models/node_factory.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/io_nodes.dart';
import 'package:digital_logic_sim_2/models/pin_layout.dart';
import 'package:digital_logic_sim_2/domain/entities/wire.dart';
import 'package:flutter/material.dart';
import '../../../../../../simulator/logic_simulator.dart';

class SubCircuitDefinition {
  final String id;
  final String name;
  final List<CircuitNode> _nodes;
  final List<Wire> _wires;
  final Color color;
  final List<String> inputLabels;
  final List<String> outputLabels;

  /// Explicit pin placements keyed by the underlying InputNode/OutputNode
  /// id. Any pin not present here falls back to the default (left/right,
  /// natural order) via [effectivePinPlacements]. Mutable so the designer
  /// can update it in place and we can persist it.
  Map<String, PinPlacement> pinPlacements;

  List<CircuitNode> get nodes {
    if (_nodes.isEmpty) {
      final resolved = resolveById(id) ?? resolve(name);
      if (resolved != null && resolved != this) {
        return resolved.nodes;
      }
    }
    return _nodes;
  }

  List<Wire> get wires {
    if (_wires.isEmpty) {
      final resolved = resolveById(id) ?? resolve(name);
      if (resolved != null && resolved != this) {
        return resolved.wires;
      }
    }
    return _wires;
  }

  /// The list of pins (in stable definition order) this IC exposes,
  /// independent of how they're currently arranged on the body.
  List<PinInfo> get pinInfos {
    final inputNodes = nodes.whereType<InputNode>().toList();
    final outputNodes = nodes.whereType<OutputNode>().toList();
    return [
      for (int i = 0; i < inputNodes.length; i++)
        PinInfo(
          key: inputNodes[i].id,
          label: i < inputLabels.length && inputLabels[i].isNotEmpty
              ? inputLabels[i]
              : inputNodes[i].label,
          isInput: true,
        ),
      for (int i = 0; i < outputNodes.length; i++)
        PinInfo(
          key: outputNodes[i].id,
          label: i < outputLabels.length && outputLabels[i].isNotEmpty
              ? outputLabels[i]
              : outputNodes[i].label,
          isInput: false,
        ),
    ];
  }

  /// [pinPlacements] with any missing pins filled in via the default
  /// left/right layout, so callers always get a complete map.
  Map<String, PinPlacement> get effectivePinPlacements {
    final infos = pinInfos;
    final defaults = PinLayoutEngine.defaultPlacements(infos);
    return {
      for (final info in infos)
        info.key: pinPlacements[info.key] ?? defaults[info.key]!,
    };
  }

  static final List<SubCircuitDefinition> registry = [];

  static void register(SubCircuitDefinition definition) {
    // Avoid duplicate by id or name (case-insensitive)
    if (!registry.any(
      (d) =>
          d.id == definition.id ||
          d.name.toLowerCase() == definition.name.toLowerCase(),
    )) {
      registry.add(definition);
    }
  }

  static SubCircuitDefinition? resolve(String name) {
    for (final def in registry) {
      if (def.name.toLowerCase() == name.toLowerCase()) {
        return def;
      }
    }
    return null;
  }

  static SubCircuitDefinition? resolveById(String id) {
    for (final def in registry) {
      if (def.id == id) {
        return def;
      }
    }
    return null;
  }

  SubCircuitDefinition({
    required this.id,
    required this.name,
    required List<CircuitNode> nodes,
    required List<Wire> wires,
    this.color = const Color(0xff334155),
    this.inputLabels = const [],
    this.outputLabels = const [],
    Map<String, PinPlacement>? pinPlacements,
  }) : _nodes = nodes,
       _wires = wires,
       pinPlacements = pinPlacements ?? {};

  Map<String, dynamic> toMap({bool includeNodes = true}) {
    return {
      'id': id,
      'name': name,
      if (includeNodes)
        'nodes': nodes.map((n) => n.toMap(isNested: true)).toList(),
      'wires': wires.map((w) => w.toMap()).toList(),
      'color': color.value,
      'inputLabels': inputLabels,
      'outputLabels': outputLabels,
      'pinPlacements': pinPlacements.values.map((p) => p.toMap()).toList(),
    };
  }

  static SubCircuitDefinition fromMap(Map<String, dynamic> map) {
    final String id =
        map['id'] ?? (map['name'] ?? 'unknown').replaceAll(' ', '_');
    final String name = map['name'] ?? 'Unknown IC';
    final resolved = resolve(name);
    if (resolved != null &&
        (map['nodes'] == null || (map['nodes'] as List).isEmpty)) {
      return resolved;
    }

    final placementsList = (map['pinPlacements'] as List? ?? [])
        .map((p) => PinPlacement.fromMap(p as Map<String, dynamic>))
        .toList();

    return SubCircuitDefinition(
      id: id,
      name: name,
      nodes: (map['nodes'] as List? ?? [])
          .map((n) => NodeFactory.fromMap(n as Map<String, dynamic>))
          .toList(),
      wires: (map['wires'] as List? ?? [])
          .map((w) => Wire.fromMap(w as Map<String, dynamic>))
          .toList(),
      color: Color(map['color'] ?? 0xff334155),
      inputLabels: List<String>.from(map['inputLabels'] ?? []),
      outputLabels: List<String>.from(map['outputLabels'] ?? []),
      pinPlacements: {for (final p in placementsList) p.pinKey: p},
    );
  }
}

class ComposedNode extends CircuitNode {
  final SubCircuitDefinition definition; // TODO: could be removed
  late final List<CircuitNode> internalNodes;
  late final List<Wire> internalWires;
  late final Circuit internalCircuit;

  late IcLayoutResult _layout;
  late List<String> _inputPinKeys;
  late List<String> _outputPinKeys;

  ComposedNode({
    required super.id,
    required super.position,
    required this.definition,
    required super.inputPins,
    required super.outputPins,
  }) {
    _initializeInternalCircuit();
    _applyLayout();
  }

  /// Recomputes pin positions from `definition.effectivePinPlacements`
  /// and writes them onto the runtime [inputPins]/[outputPins]. Call this
  /// again after editing the definition's pin layout so an existing node
  /// on the canvas picks up the change.
  void _applyLayout() {
    final inputNodes = definition.nodes.whereType<InputNode>().toList();
    final outputNodes = definition.nodes.whereType<OutputNode>().toList();
    _inputPinKeys = inputNodes.map((n) => n.id).toList();
    _outputPinKeys = outputNodes.map((n) => n.id).toList();

    _layout = PinLayoutEngine.compute(
      pins: definition.pinInfos,
      placements: definition.effectivePinPlacements,
    );

    for (int i = 0; i < inputPins.length && i < _inputPinKeys.length; i++) {
      final pos = _layout.positionFor(_inputPinKeys[i]);
      if (pos != null) inputPins[i].localPosition = pos;
    }
    for (int i = 0; i < outputPins.length && i < _outputPinKeys.length; i++) {
      final pos = _layout.positionFor(_outputPinKeys[i]);
      if (pos != null) outputPins[i].localPosition = pos;
    }
  }

  /// Public hook the controller can call on every ComposedNode instance
  /// backed by a definition whose pin layout just changed.
  void refreshLayout() => _applyLayout();

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
  Size get size => _layout.size;

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

  /// Label + which side a pin renders its text on now depends on the
  /// pin's side, not just whether it's an input or output, so the painter
  /// asks for this instead of hardcoding "inputs on left".
  PinSide sideOf(String pinKey) {
    return definition.effectivePinPlacements[pinKey]?.side ??
        (_inputPinKeys.contains(pinKey) ? PinSide.left : PinSide.right);
  }

  String inputPinLabelAt(int index) {
    if (index < definition.inputLabels.length &&
        definition.inputLabels[index].isNotEmpty) {
      return definition.inputLabels[index];
    }

    final inputNodes = definition.nodes.whereType<InputNode>().toList();
    if (index < inputNodes.length && inputNodes[index].label.isNotEmpty) {
      return inputNodes[index].label;
    }

    return '';
  }

  String outputPinLabelAt(int index) {
    if (index < definition.outputLabels.length &&
        definition.outputLabels[index].isNotEmpty) {
      return definition.outputLabels[index];
    }

    final outputNodes = definition.nodes.whereType<OutputNode>().toList();
    if (index < outputNodes.length && outputNodes[index].label.isNotEmpty) {
      return outputNodes[index].label;
    }

    return '';
  }

  /// Side that pin `index` (into inputPins) currently renders on - use this
  /// in CircuitPainter instead of assuming left, so labels are anchored
  /// correctly regardless of layout.
  PinSide inputSideAt(int index) => index < _inputPinKeys.length
      ? sideOf(_inputPinKeys[index])
      : PinSide.left;

  PinSide outputSideAt(int index) => index < _outputPinKeys.length
      ? sideOf(_outputPinKeys[index])
      : PinSide.right;

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

  @override
  Map<String, dynamic> toMap({bool isNested = false}) {
    if (isNested) {
      return {
        ...super.toMap(isNested: isNested),
        'type': 'composed',
        'reference': definition.id,
      };
    } else {
      return {
        ...super.toMap(isNested: isNested),
        'type': 'composed',
        'definition': definition.toMap(includeNodes: true),
      };
    }
  }
}
