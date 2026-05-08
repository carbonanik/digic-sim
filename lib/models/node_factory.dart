import 'package:flutter/material.dart';
import 'circuit_node.dart';
import 'pin.dart';
import 'gate_type.dart';
import 'nodes/gate_node.dart';
import 'nodes/io_nodes.dart';
import 'nodes/display_nodes.dart';
import 'nodes/clock_node.dart';
import 'nodes/composed_node.dart';
import 'wire.dart';

class NodeFactory {
  static CircuitNode fromMap(Map<String, dynamic> map) {
    final String id = map['id'];
    final Offset position = Offset(
      (map['position']['dx'] as num).toDouble(),
      (map['position']['dy'] as num).toDouble(),
    );
    final List<Pin> inputPins = (map['inputPins'] as List)
        .map((p) => Pin.fromMap(p as Map<String, dynamic>))
        .toList();
    final List<Pin> outputPins = (map['outputPins'] as List)
        .map((p) => Pin.fromMap(p as Map<String, dynamic>))
        .toList();

    final String type = map['type'];

    switch (type) {
      case 'gate':
        return GateNode(
          id: id,
          position: position,
          inputPins: inputPins,
          outputPins: outputPins,
          type: GateType.values.firstWhere((e) => e.name == map['gateType']),
        );
      case 'input':
        return InputNode(
          id: id,
          position: position,
          inputPins: inputPins,
          outputPins: outputPins,
          value: map['value'] ?? false,
        );
      case 'output':
        return OutputNode(
          id: id,
          position: position,
          inputPins: inputPins,
          outputPins: outputPins,
        );
      case 'segment_display':
        return SegmentDisplayNode(
          id: id,
          position: position,
          inputPins: inputPins,
          outputPins: outputPins,
        );
      case 'clock':
        return ClockNode(
          id: id,
          position: position,
          inputPins: inputPins,
          outputPins: outputPins,
          value: map['value'] ?? false,
        )..frequency = (map['frequency'] as num?)?.toDouble() ?? 1.0;
      case 'composed':
        return ComposedNode(
          id: id,
          position: position,
          inputPins: inputPins,
          outputPins: outputPins,
          definition: SubCircuitDefinition.fromMap(map['definition']),
        );
      default:
        throw Exception('Unknown node type: $type');
    }
  }
}
