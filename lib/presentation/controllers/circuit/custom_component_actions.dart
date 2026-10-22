import 'package:digital_logic_sim_2/domain/entities/pin_layout.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/io_nodes.dart';
import 'package:digital_logic_sim_2/domain/entities/pin.dart';
import 'package:digital_logic_sim_2/domain/entities/wire.dart';
import 'package:digital_logic_sim_2/presentation/controllers/commands/circuit_command.dart';
import 'package:digital_logic_sim_2/presentation/controllers/custom_component_manager.dart';
import 'package:flutter/material.dart';

import 'circuit_session.dart';

class CustomComponentActions {
  final CircuitSession session;
  final CustomComponentManager _customComponentManager;

  CustomComponentActions(this.session, this._customComponentManager);

  String exportIC(SubCircuitDefinition definition) {
    return _customComponentManager.exportIC(definition);
  }

  void importIC(String json) {
    final definition = _customComponentManager.importIC(json);
    if (definition != null) {
      session.uiChanged();
    }
  }

  void removeCustomDefinition(SubCircuitDefinition definition) {
    _customComponentManager.removeCustomDefinition(definition);
    session.uiChanged();
  }

  void saveCurrentAsComponent({
    required String name,
    required Color color,
    required List<String> inputLabels,
    required List<String> outputLabels,
    Map<String, PinPlacement>? pinPlacements,
  }) {
    if (session.circuit.nodes.isEmpty) return;

    int inIdx = 0;
    int outIdx = 0;
    final clonedNodes = session.circuit.nodes.map((n) {
      final clone = n.clone(n.id);
      if (clone is InputNode) {
        if (inIdx < inputLabels.length) {
          clone.label = inputLabels[inIdx];
        }
        inIdx++;
      } else if (clone is OutputNode) {
        if (outIdx < outputLabels.length) {
          clone.label = outputLabels[outIdx];
        }
        outIdx++;
      }
      return clone;
    }).toList();
    final clonedWires = session.circuit.wires
        .map(
          (w) => Wire(
            id: w.id,
            fromNodeId: w.fromNodeId,
            fromPinId: w.fromPinId,
            toNodeId: w.toNodeId,
            toPinId: w.toPinId,
            waypoints: List.from(w.waypoints),
          ),
        )
        .toList();

    final definition = SubCircuitDefinition(
      id: name.replaceAll(' ', '_').toLowerCase(),
      name: name,
      nodes: clonedNodes,
      wires: clonedWires,
      color: color,
      inputLabels: inputLabels,
      outputLabels: outputLabels,
      pinPlacements: pinPlacements,
    );

    _customComponentManager.saveCustomDefinition(definition);
    session.uiChanged();
  }

  void addCustomComponent(SubCircuitDefinition definition, Offset position) {
    position = session.grid.snap(position);
    final id = UniqueKey().toString();

    final inputNodes = definition.nodes.whereType<InputNode>().toList();
    final outputNodes = definition.nodes.whereType<OutputNode>().toList();

    final inputPins = List.generate(inputNodes.length, (i) {
      return Pin(
        id: 'in_$i',
        nodeId: id,
        isInput: true,
        localPosition: Offset(0, 32.0 + i * 16.0),
      );
    });

    final outputPins = List.generate(outputNodes.length, (i) {
      return Pin(
        id: 'out_$i',
        nodeId: id,
        isInput: false,
        localPosition: Offset(160, 32.0 + i * 16.0),
      );
    });

    final node = ComposedNode(
      id: id,
      position: position,
      definition: definition,
      inputPins: inputPins,
      outputPins: outputPins,
    );
    node.refreshLayout();

    session.circuit.nodes.add(node);
    session.history.push(AddNodesCommand([node]));

    session.simulate();
    session.pathsDirty = true;
    session.recalculatePaths();
    session.documentChanged();
  }

  void applyPinLayout(
    SubCircuitDefinition definition,
    Map<String, PinPlacement> newPlacements,
  ) {
    _customComponentManager.updatePinLayout(definition, newPlacements);

    for (final node in session.circuit.nodes.whereType<ComposedNode>()) {
      if (node.definition == definition) {
        node.refreshLayout();
      }
    }

    session.pathsDirty = true;
    session.recalculatePaths();
    session.documentChanged();
  }
}
