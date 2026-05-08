import 'package:digital_logic_sim_2/controllers/circuit_action.dart';
import 'package:digital_logic_sim_2/simulator/logic_simulator.dart';
import 'package:flutter/material.dart';

import '../editor/editor_tools.dart';
import '../models/circuit.dart';
import '../models/circuit_node.dart';
import '../models/gate_type.dart';
import '../models/pin.dart';
import '../models/wire.dart';

class CircuitController extends ChangeNotifier {
  Circuit circuit = Circuit(nodes: [], wires: []);

  EditorTool selectedTool = EditorTool.select;

  String? selectedNodeId;

  PinSelection? wireStart;

  Offset? temporaryWireEnd;

  List<CircuitAction> undoStack = [];
  List<CircuitAction> redoStack = [];

  void selectTool(EditorTool tool) {
    selectedTool = tool;
    selectedNodeId = null;
    wireStart = null;
    temporaryWireEnd = null;
    notifyListeners();
  }

  void clear() {
    circuit.nodes.clear();
    circuit.wires.clear();
    selectedNodeId = null;
    wireStart = null;
    temporaryWireEnd = null;
    undoStack.clear();
    redoStack.clear();
    notifyListeners();
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
      _ => null,
    };

    if (type == null) return;

    final node = _createNode(type, position);
    circuit.nodes.add(node);

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
    }

    circuit.nodes.remove(node);

    undoStack.add(CircuitAction(
      removedNodes: [node],
      removedWires: removedWires,
    ));
    redoStack.clear(); // Clear redo stack

    LogicSimulator.simulate(circuit);
    notifyListeners();
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
  }

  void selectNode(String? nodeId) {
    selectedNodeId = nodeId;
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

  void toggleInput(String nodeId) {
    final node = circuit.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return;

    if (node.type == GateType.input) {
      node.value = !node.value;
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
        return CircuitNode(
          id: id,
          type: type,
          position: position,
          value: false,
          inputPins: const [],
          outputPins: [
            Pin(
              id: 'out',
              nodeId: '',
              isInput: false,
              localPosition: Offset(110, 32),
            ),
          ],
        );

      case GateType.output:
        return CircuitNode(
          id: id,
          type: type,
          position: position,
          inputPins: [
            Pin(
              id: 'in',
              nodeId: '',
              isInput: true,
              localPosition: Offset(0, 32),
            ),
          ],
          outputPins: const [],
        );

      case GateType.not:
        return CircuitNode(
          id: id,
          type: type,
          position: position,
          inputPins: [
            Pin(
              id: 'in',
              nodeId: '',
              isInput: true,
              localPosition: Offset(0, 32),
            ),
          ],
          outputPins: [
            Pin(
              id: 'out',
              nodeId: '',
              isInput: false,
              localPosition: Offset(110, 32),
            ),
          ],
        );

      default:
        return CircuitNode(
          id: id,
          type: type,
          position: position,
          inputPins: [
            Pin(
              id: 'a',
              nodeId: '',
              isInput: true,
              localPosition: Offset(0, 22),
            ),
            Pin(
              id: 'b',
              nodeId: '',
              isInput: true,
              localPosition: Offset(0, 42),
            ),
          ],
          outputPins: [
            Pin(
              id: 'out',
              nodeId: '',
              isInput: false,
              localPosition: Offset(110, 32),
            ),
          ],
        );
    }
  }
}

class PinSelection {
  final CircuitNode node;
  final Pin pin;

  PinSelection({required this.node, required this.pin});
}
