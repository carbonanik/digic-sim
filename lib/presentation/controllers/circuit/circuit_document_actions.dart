import 'package:digital_logic_sim_2/core/utils/extensions.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/clock_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/io_nodes.dart';
import 'package:digital_logic_sim_2/domain/entities/wire.dart';
import 'package:digital_logic_sim_2/presentation/controllers/commands/circuit_command.dart';
import 'package:flutter/material.dart';

import 'circuit_session.dart';

class CircuitDocumentActions {
  final CircuitSession session;

  CircuitDocumentActions(this.session);

  void clear() {
    session.circuit.nodes.clear();
    session.circuit.wires.clear();
    session.editor.reset();
    session.updateClockTimer();
    session.pathsDirty = true;
    session.history.clear();
    session.documentChanged();
  }

  void addGateFromTool(Offset position) {
    position = session.grid.snap(position);

    final node = session.nodeFactory.create(
      session.editor.selectedTool,
      position,
    );
    session.circuit.nodes.add(node);

    session.updateClockTimer();

    session.history.push(AddNodesCommand([node]));

    session.simulate();
    session.pathsDirty = true;
    session.recalculatePaths();
    session.documentChanged();
  }

  void removeNode(CircuitNode node) {
    final removedWires = session.circuit.wires.where((w) {
      return w.fromNodeId == node.id || w.toNodeId == node.id;
    }).toList();

    for (final wire in removedWires) {
      session.circuit.wires.remove(wire);
      if (session.editor.selectedWireId == wire.id) {
        session.editor.selectedWireId = null;
      }
    }

    session.circuit.nodes.remove(node);
    session.editor.selectedNodeIds.remove(node.id);

    session.updateClockTimer();

    session.history.push(
      RemoveNodesAndWiresCommand(nodes: [node], wires: removedWires),
    );

    session.simulate();
    session.pathsDirty = true;
    session.recalculatePaths();
    session.documentChanged();
  }

  void removeWire(Wire wire) {
    session.circuit.wires.remove(wire);

    if (session.editor.selectedWireId == wire.id) {
      session.editor.selectedWireId = null;
    }

    session.history.push(RemoveWireCommand(wire));

    session.simulate();
    session.pathsDirty = true;
    session.recalculatePaths();
    session.documentChanged();
  }

  void deleteSelected() {
    if (session.editor.selectedNodeIds.isNotEmpty) {
      final nodesToRemove = session.circuit.nodes
          .where((n) => session.editor.selectedNodeIds.contains(n.id))
          .toList();

      final removedWires = <Wire>[];
      final removedNodes = <CircuitNode>[];

      for (final node in nodesToRemove) {
        final nodeWires = session.circuit.wires.where((w) {
          return w.fromNodeId == node.id || w.toNodeId == node.id;
        }).toList();

        for (final wire in nodeWires) {
          session.circuit.wires.remove(wire);
          if (session.editor.selectedWireId == wire.id) {
            session.editor.selectedWireId = null;
          }
          if (!removedWires.contains(wire)) {
            removedWires.add(wire);
          }
        }

        session.circuit.nodes.remove(node);
        removedNodes.add(node);
      }

      session.editor.selectedNodeIds.clear();

      session.updateClockTimer();

      session.history.push(
        RemoveNodesAndWiresCommand(nodes: removedNodes, wires: removedWires),
      );

      session.simulate();
      session.pathsDirty = true;
      session.recalculatePaths();
      session.documentChanged();
    } else if (session.editor.selectedWireId != null) {
      final wire = session.circuit.wires
          .where((w) => w.id == session.editor.selectedWireId)
          .firstOrNull;
      if (wire != null) {
        removeWire(wire);
      }
    }
  }

  void undo() {
    if (session.history.undo(session.circuit)) {
      session.updateClockTimer();
      session.simulate();
      session.pathsDirty = true;
      session.recalculatePaths();
      session.documentChanged();
    }
  }

  void redo() {
    if (session.history.redo(session.circuit)) {
      session.updateClockTimer();
      session.simulate();
      session.pathsDirty = true;
      session.recalculatePaths();
      session.documentChanged();
    }
  }

  void handleNodeAction(String nodeId, Offset localPosition) {
    final node = session.circuit.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return;

    if (node.onAction(localPosition)) {
      session.simulate();
      session.documentChanged();
    }
  }

  void updateNodeLabel(String nodeId, String label) {
    final node = session.circuit.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return;

    if (node is InputNode) {
      node.label = label;
    } else if (node is OutputNode) {
      node.label = label;
    }

    session.documentChanged();
  }

  void updateNodeLabels(Map<String, String> labels) {
    bool changed = false;
    for (final node in session.circuit.nodes) {
      final label = labels[node.id];
      if (label == null) continue;
      if (node is InputNode) {
        node.label = label;
        changed = true;
      } else if (node is OutputNode) {
        node.label = label;
        changed = true;
      }
    }
    if (changed) session.documentChanged();
  }

  void duplicateSelected() {
    if (session.editor.selectedNodeIds.isEmpty) return;

    final nodesToDuplicate = session.circuit.nodes
        .where((n) => session.editor.selectedNodeIds.contains(n.id))
        .toList();

    final newNodes = <CircuitNode>[];
    for (final node in nodesToDuplicate) {
      final newNode = node.clone(UniqueKey().toString());
      newNode.position = node.position + const Offset(32, 32);
      session.circuit.nodes.add(newNode);
      newNodes.add(newNode);
    }

    session.editor.selectedNodeIds = newNodes.map((n) => n.id).toSet();
    session.editor.selectedWireId = null;

    session.history.push(AddNodesCommand(newNodes));

    session.pathsDirty = true;
    session.recalculatePaths();
    session.documentChanged();
  }

  void loadDefinition(SubCircuitDefinition definition) {
    clear();

    int inputIdx = 0;
    int outputIdx = 0;

    for (final node in definition.nodes) {
      final newNode = node.clone(node.id);
      if (newNode is InputNode) {
        if (inputIdx < definition.inputLabels.length) {
          newNode.label = definition.inputLabels[inputIdx];
        }
        inputIdx++;
      } else if (newNode is OutputNode) {
        if (outputIdx < definition.outputLabels.length) {
          newNode.label = definition.outputLabels[outputIdx];
        }
        outputIdx++;
      }
      session.circuit.nodes.add(newNode);
    }

    for (final wire in definition.wires) {
      session.circuit.wires.add(
        Wire(
          id: wire.id,
          fromNodeId: wire.fromNodeId,
          fromPinId: wire.fromPinId,
          toNodeId: wire.toNodeId,
          toPinId: wire.toPinId,
          waypoints: List.from(wire.waypoints),
        ),
      );
    }

    session.updateClockTimer();
    session.simulate();
    session.pathsDirty = true;
    session.recalculatePaths();
    session.documentChanged();
  }

  void duplicateNode(CircuitNode node) {
    final clone = node.clone(UniqueKey().toString());
    clone.position = node.position + const Offset(32, 32);
    session.circuit.nodes.add(clone);
    session.editor.selectedNodeIds = {clone.id};
    session.editor.selectedWireId = null;
    session.history.push(AddNodesCommand([clone]));
    session.updateClockTimer();
    session.simulate();
    session.pathsDirty = true;
    session.recalculatePaths();
    session.documentChanged();
  }

  void setClockFrequency(String nodeId, double frequency) {
    if (!frequency.isFinite || frequency <= 0) return;
    final node = session.circuit.nodes
        .where((node) => node.id == nodeId)
        .firstOrNull;
    if (node is! ClockNode) return;
    node.frequency = frequency;
    session.documentChanged();
  }
}
