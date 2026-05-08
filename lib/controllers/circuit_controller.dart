import 'package:digital_logic_sim_2/controllers/circuit_action.dart';
import 'package:digital_logic_sim_2/simulator/logic_simulator.dart';
import 'package:flutter/material.dart';

import '../editor/editor_tools.dart';
import '../editor/hit_test.dart';
import '../models/circuit.dart';
import '../models/circuit_node.dart';
import '../models/gate_type.dart';
import '../models/pin.dart';
import '../models/wire.dart';
import '../models/nodes/gate_node.dart';
import '../models/nodes/io_nodes.dart';
import '../models/nodes/display_nodes.dart';
import '../models/nodes/clock_node.dart';
import '../models/nodes/composed_node.dart';
import 'dart:async';

class CircuitController extends ChangeNotifier {
  Circuit circuit = Circuit(nodes: [], wires: []);

  List<SubCircuitDefinition> customDefinitions = [];

  Timer? _clockTimer;

  EditorTool selectedTool = EditorTool.select;

  String? selectedNodeId;
  String? selectedWireId;

  PinSelection? wireStart;
  PinHit? hoveredPin;

  Offset? temporaryWireEnd;

  List<CircuitAction> undoStack = [];
  List<CircuitAction> redoStack = [];

  void selectTool(EditorTool tool) {
    selectedTool = tool;
    selectedNodeId = null;
    selectedWireId = null;
    wireStart = null;
    hoveredPin = null;
    temporaryWireEnd = null;
    notifyListeners();
  }

  void setHoveredPin(PinHit? pinHit) {
    if (hoveredPin != pinHit) {
      hoveredPin = pinHit;
      notifyListeners();
    }
  }

  void clear() {
    circuit.nodes.clear();
    circuit.wires.clear();
    selectedNodeId = null;
    selectedWireId = null;
    wireStart = null;
    temporaryWireEnd = null;
    undoStack.clear();
    redoStack.clear();
    _updateClockTimer();
    notifyListeners();
  }

  void _updateClockTimer() {
    final hasClocks = circuit.nodes.any((n) => n is ClockNode);
    if (hasClocks && _clockTimer == null) {
      _clockTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        bool changed = false;
        for (final node in circuit.nodes) {
          if (node is ClockNode) {
            node.value = !node.value;
            changed = true;
          }
        }
        if (changed) {
          LogicSimulator.simulate(circuit);
          notifyListeners();
        }
      });
    } else if (!hasClocks && _clockTimer != null) {
      _clockTimer?.cancel();
      _clockTimer = null;
    }
  }

  void addGateFromTool(Offset position) {
    final GateType? type = switch (selectedTool) {
      EditorTool.input => GateType.input,
      EditorTool.output => GateType.output,
      EditorTool.and => GateType.and,
      EditorTool.or => GateType.or,
      EditorTool.not => GateType.not,
      EditorTool.nand => GateType.nand,
      EditorTool.nor => GateType.nor,
      EditorTool.xor => GateType.xor,
      EditorTool.segmentDisplay => null,
      EditorTool.clock => null,
      _ => null,
    };

    if (type == null &&
        selectedTool != EditorTool.segmentDisplay &&
        selectedTool != EditorTool.clock)
      return;

    final node = switch (selectedTool) {
      EditorTool.segmentDisplay => _createSegmentDisplay(position),
      EditorTool.clock => _createClock(position),
      _ => _createNode(type!, position),
    };
    circuit.nodes.add(node);

    _updateClockTimer();

    undoStack.add(CircuitAction(addedNodes: [node]));
    redoStack.clear(); // Clear redo stack after new action

    LogicSimulator.simulate(circuit);
    notifyListeners();
  }

  void removeNode(CircuitNode node) {
    final removedWires = circuit.wires.where((w) {
      return w.fromNodeId == node.id || w.toNodeId == node.id;
    }).toList();

    for (final wire in removedWires) {
      circuit.wires.remove(wire);
      if (selectedWireId == wire.id) {
        selectedWireId = null;
      }
    }

    circuit.nodes.remove(node);

    if (selectedNodeId == node.id) {
      selectedNodeId = null;
    }

    _updateClockTimer();

    undoStack.add(
      CircuitAction(removedNodes: [node], removedWires: removedWires),
    );
    redoStack.clear();

    LogicSimulator.simulate(circuit);
    notifyListeners();
  }

  void removeWire(Wire wire) {
    circuit.wires.remove(wire);

    if (selectedWireId == wire.id) {
      selectedWireId = null;
    }

    undoStack.add(CircuitAction(removedWires: [wire]));
    redoStack.clear();

    LogicSimulator.simulate(circuit);
    notifyListeners();
  }

  void deleteSelected() {
    if (selectedNodeId != null) {
      final node = getSelectedNode();
      if (node != null) {
        removeNode(node);
      }
    } else if (selectedWireId != null) {
      final wire = circuit.wires
          .where((w) => w.id == selectedWireId)
          .firstOrNull;
      if (wire != null) {
        removeWire(wire);
      }
    }
  }

  void undo() {
    if (undoStack.isEmpty) return;

    final action = undoStack.removeLast();
    _applyAction(action, undo: true);
    redoStack.add(action);

    LogicSimulator.simulate(circuit);
    notifyListeners();
  }

  void redo() {
    if (redoStack.isEmpty) return;

    final action = redoStack.removeLast();
    _applyAction(action, undo: false);
    undoStack.add(action);

    LogicSimulator.simulate(circuit);
    notifyListeners();
  }

  void _applyAction(CircuitAction action, {required bool undo}) {
    if (undo) {
      for (final node in action.addedNodes) {
        circuit.nodes.remove(node);
      }
      for (final wire in action.addedWires) {
        circuit.wires.remove(wire);
      }
      for (final node in action.removedNodes) {
        circuit.nodes.add(node);
      }
      for (final wire in action.removedWires) {
        circuit.wires.add(wire);
      }
    } else {
      for (final node in action.addedNodes) {
        circuit.nodes.add(node);
      }
      for (final wire in action.addedWires) {
        circuit.wires.add(wire);
      }
      for (final node in action.removedNodes) {
        circuit.nodes.remove(node);
      }
      for (final wire in action.removedWires) {
        circuit.wires.remove(wire);
      }
    }
    _updateClockTimer();
  }

  void selectNode(String? nodeId) {
    selectedNodeId = nodeId;
    selectedWireId = null;
    notifyListeners();
  }

  void selectWire(String? wireId) {
    selectedWireId = wireId;
    selectedNodeId = null;
    notifyListeners();
  }

  void moveSelectedNode(Offset delta) {
    final node = getSelectedNode();
    if (node == null) return;

    node.position += delta;
    notifyListeners();
  }

  CircuitNode? getSelectedNode() {
    if (selectedNodeId == null) return null;

    for (final node in circuit.nodes) {
      if (node.id == selectedNodeId) return node;
    }

    return null;
  }

  void handleNodeAction(String nodeId, Offset localPosition) {
    final node = circuit.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return;

    if (node.onAction(localPosition)) {
      LogicSimulator.simulate(circuit);
      notifyListeners();
    }
  }

  void startWire(CircuitNode node, Pin pin) {
    if (pin.isInput) return;

    wireStart = PinSelection(node: node, pin: pin);
    temporaryWireEnd = node.position + pin.localPosition;
    notifyListeners();
  }

  void updateTemporaryWire(Offset point) {
    temporaryWireEnd = point;
    notifyListeners();
  }

  void finishWire(CircuitNode node, Pin pin) {
    if (wireStart == null) return;
    if (!pin.isInput) return;

    final start = wireStart!;

    if (start.node.id == node.id) {
      cancelWire();
      return;
    }

    final inputAlreadyUsed = circuit.wires.any((wire) {
      return wire.toNodeId == node.id && wire.toPinId == pin.id;
    });

    if (inputAlreadyUsed) {
      cancelWire();
      return;
    }

    final wire = Wire(
      id: UniqueKey().toString(),
      fromNodeId: start.node.id,
      fromPinId: start.pin.id,
      toNodeId: node.id,
      toPinId: pin.id,
    );
    circuit.wires.add(wire);

    undoStack.add(CircuitAction(addedWires: [wire]));
    redoStack.clear();

    wireStart = null;
    temporaryWireEnd = null;

    LogicSimulator.simulate(circuit);
    notifyListeners();
  }

  void cancelWire() {
    wireStart = null;
    temporaryWireEnd = null;
    notifyListeners();
  }

  CircuitNode _createNode(GateType type, Offset position) {
    final id = UniqueKey().toString();

    switch (type) {
      case GateType.input:
        return InputNode(
          id: id,
          position: position,
          inputPins: const [],
          outputPins: [
            Pin(
              id: 'out',
              nodeId: id,
              isInput: false,
              localPosition: const Offset(110, 32),
            ),
          ],
        );

      case GateType.output:
        return OutputNode(
          id: id,
          position: position,
          inputPins: [
            Pin(
              id: 'in',
              nodeId: id,
              isInput: true,
              localPosition: const Offset(0, 32),
            ),
          ],
          outputPins: const [],
        );

      case GateType.not:
        return GateNode(
          id: id,
          type: type,
          position: position,
          inputPins: [
            Pin(
              id: 'in',
              nodeId: id,
              isInput: true,
              localPosition: const Offset(0, 32),
            ),
          ],
          outputPins: [
            Pin(
              id: 'out',
              nodeId: id,
              isInput: false,
              localPosition: const Offset(110, 32),
            ),
          ],
        );

      default:
        return GateNode(
          id: id,
          type: type,
          position: position,
          inputPins: [
            Pin(
              id: 'a',
              nodeId: id,
              isInput: true,
              localPosition: const Offset(0, 22),
            ),
            Pin(
              id: 'b',
              nodeId: id,
              isInput: true,
              localPosition: const Offset(0, 42),
            ),
          ],
          outputPins: [
            Pin(
              id: 'out',
              nodeId: id,
              isInput: false,
              localPosition: const Offset(110, 32),
            ),
          ],
        );
    }
  }

  CircuitNode _createSegmentDisplay(Offset position) {
    final id = UniqueKey().toString();
    final inputPins = List.generate(7, (i) {
      return Pin(
        id: 'seg_$i',
        nodeId: id,
        isInput: true,
        localPosition: Offset(0, 15.0 + i * 15.0),
      );
    });

    return SegmentDisplayNode(
      id: id,
      position: position,
      inputPins: inputPins,
      outputPins: const [],
    );
  }

  CircuitNode _createClock(Offset position) {
    final id = UniqueKey().toString();
    return ClockNode(
      id: id,
      position: position,
      inputPins: const [],
      outputPins: [
        Pin(
          id: 'out',
          nodeId: id,
          isInput: false,
          localPosition: const Offset(110, 32),
        ),
      ],
    );
  }

  void saveCurrentAsComponent({
    required String name,
    required Color color,
    required List<String> inputLabels,
    required List<String> outputLabels,
  }) {
    if (circuit.nodes.isEmpty) return;

    // 1. Identify external inputs and outputs
    final inputNodes = circuit.nodes.whereType<InputNode>().toList();
    final outputNodes = circuit.nodes.whereType<OutputNode>().toList();

    // 2. Clone current nodes and wires
    final clonedNodes = circuit.nodes.map((n) => n.clone(n.id)).toList();
    final clonedWires = circuit.wires
        .map(
          (w) => Wire(
            id: w.id,
            fromNodeId: w.fromNodeId,
            fromPinId: w.fromPinId,
            toNodeId: w.toNodeId,
            toPinId: w.toPinId,
          ),
        )
        .toList();

    // 3. Create definition
    final definition = SubCircuitDefinition(
      name: name,
      nodes: clonedNodes,
      wires: clonedWires,
      color: color,
      inputLabels: inputLabels,
      outputLabels: outputLabels,
    );

    customDefinitions.add(definition);
    notifyListeners();
  }

  void addCustomComponent(SubCircuitDefinition definition, Offset position) {
    final id = UniqueKey().toString();

    // Create external pins based on internal Input/Output nodes
    final inputNodes = definition.nodes.whereType<InputNode>().toList();
    final outputNodes = definition.nodes.whereType<OutputNode>().toList();

    final inputPins = List.generate(inputNodes.length, (i) {
      return Pin(
        id: 'in_$i',
        nodeId: id,
        isInput: true,
        localPosition: Offset(0, 30.0 + i * 20.0),
      );
    });

    final outputPins = List.generate(outputNodes.length, (i) {
      return Pin(
        id: 'out_$i',
        nodeId: id,
        isInput: false,
        localPosition: Offset(140, 30.0 + i * 20.0),
      );
    });

    final node = ComposedNode(
      id: id,
      position: position,
      definition: definition,
      inputPins: inputPins,
      outputPins: outputPins,
    );

    circuit.nodes.add(node);
    undoStack.add(CircuitAction(addedNodes: [node]));
    redoStack.clear();

    LogicSimulator.simulate(circuit);
    notifyListeners();
  }
}

class PinSelection {
  final CircuitNode node;
  final Pin pin;

  PinSelection({required this.node, required this.pin});
}
