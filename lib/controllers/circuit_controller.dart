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
import '../models/nodes/waveform_node.dart';
import '../models/nodes/rgb_led_node.dart';
import '../models/nodes/logic_probe_node.dart';
import '../utils/pathfinder.dart';
import 'dart:async';
import 'dart:convert';

class CircuitController extends ChangeNotifier {
  String exportIC(SubCircuitDefinition definition) {
    return jsonEncode(definition.toMap());
  }

  void importIC(String json) {
    try {
      final map = jsonDecode(json);
      final definition = SubCircuitDefinition.fromMap(map);
      customDefinitions.add(definition);
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing IC: $e');
    }
  }

  void removeCustomDefinition(SubCircuitDefinition definition) {
    customDefinitions.remove(definition);
    notifyListeners();
  }

  Circuit circuit = Circuit(nodes: [], wires: []);

  List<SubCircuitDefinition> customDefinitions = [];

  Timer? _clockTimer;

  EditorTool selectedTool = EditorTool.select;
  SubCircuitDefinition? selectedCustomComponent;

  Set<String> selectedNodeIds = {};
  String? selectedWireId;

  Rect? selectionRect;
  Offset? _selectionStart;

  PinSelection? wireStart;
  PinHit? hoveredPin;
  String? hoveredNodeId;

  Offset? mousePosition;
  Offset? temporaryWireEnd;

  List<CircuitAction> undoStack = [];
  List<CircuitAction> redoStack = [];

  int repaintCounter = 0;

  Offset _dragAccumulator = Offset.zero;
  bool snapToGridEnabled = true;

  bool _pathsDirty = true;

  // Wire dragging state
  WireHit? draggedWireHit;
  Offset? _wireDragStartMousePos;
  List<Offset>? _initialWaypoints;

  void toggleGridSnapping() {
    snapToGridEnabled = !snapToGridEnabled;
    notifyListeners();
  }

  Offset _snapToGrid(Offset point) {
    if (!snapToGridEnabled) return point;
    const double gridSize = 16.0;
    return Offset(
      (point.dx / gridSize).roundToDouble() * gridSize,
      (point.dy / gridSize).roundToDouble() * gridSize,
    );
  }

  void resetDragAccumulator() {
    _dragAccumulator = Offset.zero;
  }

  void selectTool(EditorTool tool) {
    selectedTool = tool;
    if (tool != EditorTool.custom) {
      selectedCustomComponent = null;
    }
    selectedNodeIds.clear();
    selectedWireId = null;
    selectionRect = null;
    wireStart = null;
    hoveredPin = null;
    temporaryWireEnd = null;
    notifyListeners();
  }

  void selectCustomComponent(SubCircuitDefinition definition) {
    selectedTool = EditorTool.custom;
    selectedCustomComponent = definition;
    selectedNodeIds.clear();
    selectedWireId = null;
    selectionRect = null;
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

  void setHoveredNode(String? nodeId) {
    if (hoveredNodeId != nodeId) {
      hoveredNodeId = nodeId;
      notifyListeners();
    }
  }

  void setMousePosition(Offset? pos) {
    final snapped = pos != null ? _snapToGrid(pos) : null;
    if (mousePosition != snapped) {
      mousePosition = snapped;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    repaintCounter++;
    super.notifyListeners();
  }

  void clear() {
    circuit.nodes.clear();
    circuit.wires.clear();
    selectedNodeIds.clear();
    temporaryWireEnd = null;
    draggedWireHit = null;
    _pathsDirty = true;
    notifyListeners();
  }

  void startWireDrag(WireHit hit, Offset mousePos) {
    draggedWireHit = hit;
    _wireDragStartMousePos = mousePos;

    // Bake waypoints if empty
    final wire = hit.wire;
    if (wire.waypoints.isEmpty) {
      final fromNode = circuit.nodes.firstWhere((n) => n.id == wire.fromNodeId);
      final toNode = circuit.nodes.firstWhere((n) => n.id == wire.toNodeId);
      final fromPin = fromNode.outputPins.firstWhere(
        (p) => p.id == wire.fromPinId,
      );
      final toPin = toNode.inputPins.firstWhere((p) => p.id == wire.toPinId);
      final start = fromNode.position + fromPin.localPosition;
      final end = toNode.position + toPin.localPosition;

      final points = PathFinder.findPath(
        start: start,
        end: end,
        obstacles: circuit.nodes.map((n) => n.rect).toList(),
      );
      // Waypoints are everything except start and end
      _initialWaypoints = points.length <= 2
          ? []
          : points.sublist(1, points.length - 1);
    } else {
      _initialWaypoints = List.from(wire.waypoints);
    }
    notifyListeners();
  }

  void updateWireDrag(Offset mousePos) {
    if (draggedWireHit == null || _initialWaypoints == null) return;

    final snappedMouse = _snapToGrid(mousePos);
    final wire = draggedWireHit!.wire;
    final segmentIndex = draggedWireHit!.segmentIndex;

    final fromNode = circuit.nodes.firstWhere((n) => n.id == wire.fromNodeId);
    final toNode = circuit.nodes.firstWhere((n) => n.id == wire.toNodeId);

    final fromPin = fromNode.outputPins.firstWhere(
      (p) => p.id == wire.fromPinId,
    );
    final toPin = toNode.inputPins.firstWhere((p) => p.id == wire.toPinId);

    final start = fromNode.position + fromPin.localPosition;
    final end = toNode.position + toPin.localPosition;

    final points = [start, ..._initialWaypoints!, end];

    if (segmentIndex < 0 || segmentIndex >= points.length - 1) return;

    final p1 = points[segmentIndex];
    final p2 = points[segmentIndex + 1];

    final isHorizontal = (p1.dy - p2.dy).abs() < 0.1;
    final isVertical = (p1.dx - p2.dx).abs() < 0.1;

    if (!isHorizontal && !isVertical) return;

    final List<Offset> newPoints;

    if (isHorizontal) {
      // Drag horizontal segment vertically.
      final newY = snappedMouse.dy;

      newPoints = [
        ...points.take(segmentIndex + 1),
        Offset(p1.dx, newY),
        Offset(p2.dx, newY),
        ...points.skip(segmentIndex + 1),
      ];
    } else {
      // Drag vertical segment horizontally.
      final newX = snappedMouse.dx;

      newPoints = [
        ...points.take(segmentIndex + 1),
        Offset(newX, p1.dy),
        Offset(newX, p2.dy),
        ...points.skip(segmentIndex + 1),
      ];
    }

    final simplifiedPoints = _simplifyOrthogonalPoints(newPoints);

    final newWaypoints = simplifiedPoints.length <= 2
        ? <Offset>[]
        : simplifiedPoints.sublist(1, simplifiedPoints.length - 1);

    final wireIndex = circuit.wires.indexWhere((w) => w.id == wire.id);

    if (wireIndex != -1) {
      circuit.wires[wireIndex] = wire.copyWith(waypoints: newWaypoints);
      _pathsDirty = true;
      _recalculatePaths();
      notifyListeners();
    }
  }

  List<Offset> _simplifyOrthogonalPoints(List<Offset> points) {
    if (points.length <= 2) return points;

    final result = <Offset>[];

    for (final point in points) {
      if (result.isNotEmpty && (result.last - point).distance < 0.1) {
        continue;
      }

      result.add(point);
    }

    bool changed = true;

    while (changed) {
      changed = false;

      for (int i = 1; i < result.length - 1; i++) {
        final a = result[i - 1];
        final b = result[i];
        final c = result[i + 1];

        final sameVertical =
            (a.dx - b.dx).abs() < 0.1 && (b.dx - c.dx).abs() < 0.1;

        final sameHorizontal =
            (a.dy - b.dy).abs() < 0.1 && (b.dy - c.dy).abs() < 0.1;

        if (sameVertical || sameHorizontal) {
          result.removeAt(i);
          changed = true;
          break;
        }
      }
    }

    return result;
  }

  void endWireDrag() {
    if (draggedWireHit != null) {
      undoStack.add(
        CircuitAction(
          // For now, undoing wire moves is tricky because we mutate the wire.
          // In a real app, CircuitAction should store the old state.
        ),
      );
      draggedWireHit = null;
      _initialWaypoints = null;
      _pathsDirty = true;
      _recalculatePaths();
      notifyListeners();
    }
  }

  void endNodeMove() {
    if (selectedNodeIds.isNotEmpty) {
      _pathsDirty = true;
      _recalculatePaths();
      notifyListeners();
    }
  }

  void _updateClockTimer() {
    final hasClocks = circuit.nodes.any((n) => n is ClockNode);
    final hasWaveforms = circuit.nodes.any((n) => n is WaveformNode);

    if ((hasClocks || hasWaveforms) && _clockTimer == null) {
      _clockTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
        bool changed = false;
        final now = DateTime.now();
        for (final node in circuit.nodes) {
          if (node is ClockNode) {
            final periodMs = 1000 / (2 * node.frequency);
            if (now.difference(node.lastToggleTime).inMilliseconds >=
                periodMs) {
              node.value = !node.value;
              node.lastToggleTime = now;
              changed = true;
            }
          }
        }

        // Always simulate if we have waveforms to keep them scrolling,
        // or if a clock toggled.
        if (changed || hasWaveforms) {
          LogicSimulator.simulate(circuit);
          notifyListeners();
        }
      });
    } else if (!hasClocks && !hasWaveforms && _clockTimer != null) {
      _clockTimer?.cancel();
      _clockTimer = null;
    }
  }

  void addGateFromTool(Offset position) {
    position = _snapToGrid(position);

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
      EditorTool.waveform => null,
      EditorTool.rgbLed => null,
      EditorTool.logicProbe => null,
      _ => null,
    };

    if (type == null &&
        selectedTool != EditorTool.segmentDisplay &&
        selectedTool != EditorTool.clock &&
        selectedTool != EditorTool.waveform &&
        selectedTool != EditorTool.rgbLed &&
        selectedTool != EditorTool.logicProbe &&
        selectedTool != EditorTool.custom) {
      return;
    }

    if (selectedTool == EditorTool.custom && selectedCustomComponent != null) {
      addCustomComponent(selectedCustomComponent!, position);
      return;
    }

    final node = switch (selectedTool) {
      EditorTool.segmentDisplay => _createSegmentDisplay(position),
      EditorTool.clock => _createClock(position),
      EditorTool.waveform => _createWaveform(position),
      EditorTool.rgbLed => _createRGBLED(position),
      EditorTool.logicProbe => _createLogicProbe(position),
      _ => _createNode(type!, position),
    };
    circuit.nodes.add(node);

    _updateClockTimer();

    undoStack.add(CircuitAction(addedNodes: [node]));
    redoStack.clear(); // Clear redo stack after new action

    LogicSimulator.simulate(circuit);
    _pathsDirty = true;
    _recalculatePaths();
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

    selectedNodeIds.remove(node.id);

    _updateClockTimer();

    undoStack.add(
      CircuitAction(removedNodes: [node], removedWires: removedWires),
    );
    redoStack.clear();

    LogicSimulator.simulate(circuit);
    _pathsDirty = true;
    _recalculatePaths();
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
    _pathsDirty = true;
    _recalculatePaths();
    notifyListeners();
  }

  void deleteSelected() {
    if (selectedNodeIds.isNotEmpty) {
      final nodesToRemove = circuit.nodes
          .where((n) => selectedNodeIds.contains(n.id))
          .toList();

      final removedWires = <Wire>[];
      final removedNodes = <CircuitNode>[];

      for (final node in nodesToRemove) {
        final nodeWires = circuit.wires.where((w) {
          return w.fromNodeId == node.id || w.toNodeId == node.id;
        }).toList();

        for (final wire in nodeWires) {
          circuit.wires.remove(wire);
          if (selectedWireId == wire.id) {
            selectedWireId = null;
          }
          if (!removedWires.contains(wire)) {
            removedWires.add(wire);
          }
        }

        circuit.nodes.remove(node);
        removedNodes.add(node);
      }

      selectedNodeIds.clear();

      _updateClockTimer();

      undoStack.add(
        CircuitAction(removedNodes: removedNodes, removedWires: removedWires),
      );
      redoStack.clear();

      LogicSimulator.simulate(circuit);
      _pathsDirty = true;
      _recalculatePaths();
      notifyListeners();
    } else if (selectedWireId != null) {
      final wire = circuit.wires
          .where((w) => w.id == selectedWireId)
          .firstOrNull;
      if (wire != null) {
        removeWire(wire);
      }
    }
  }

  void resetWirePath(String wireId) {
    final wireIndex = circuit.wires.indexWhere((w) => w.id == wireId);
    if (wireIndex != -1) {
      final oldWire = circuit.wires[wireIndex];
      circuit.wires[wireIndex] = oldWire.copyWith(waypoints: []);
      _pathsDirty = true;
      _recalculatePaths();
      notifyListeners();
    }
  }

  void undo() {
    if (undoStack.isEmpty) return;

    final action = undoStack.removeLast();
    _applyAction(action, undo: true);
    redoStack.add(action);

    LogicSimulator.simulate(circuit);
    _pathsDirty = true;
    _recalculatePaths();
    notifyListeners();
  }

  void redo() {
    if (redoStack.isEmpty) return;

    final action = redoStack.removeLast();
    _applyAction(action, undo: false);
    undoStack.add(action);

    LogicSimulator.simulate(circuit);
    _pathsDirty = true;
    _recalculatePaths();
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

  void selectNode(String? nodeId, {bool multi = false}) {
    if (nodeId == null) {
      selectedNodeIds.clear();
    } else {
      if (multi) {
        if (selectedNodeIds.contains(nodeId)) {
          selectedNodeIds.remove(nodeId);
        } else {
          selectedNodeIds.add(nodeId);
        }
      } else {
        if (!selectedNodeIds.contains(nodeId)) {
          selectedNodeIds = {nodeId};
        }
      }
    }
    selectedWireId = null;
    notifyListeners();
  }

  void selectWire(String? wireId) {
    selectedWireId = wireId;
    selectedNodeIds.clear();
    notifyListeners();
  }

  void moveSelectedNodes(Offset delta) {
    if (selectedNodeIds.isEmpty) return;

    if (!snapToGridEnabled) {
      for (final node in circuit.nodes) {
        if (selectedNodeIds.contains(node.id)) {
          node.position += delta;
        }
      }
      _pathsDirty = true;
      _recalculatePaths();
      notifyListeners();
      return;
    }

    _dragAccumulator += delta;
    const double gridSize = 16.0;
    final int stepsX = (_dragAccumulator.dx / gridSize).round();
    final int stepsY = (_dragAccumulator.dy / gridSize).round();

    if (stepsX != 0 || stepsY != 0) {
      final snappedDelta = Offset(stepsX * gridSize, gridSize * stepsY);
      for (final node in circuit.nodes) {
        if (selectedNodeIds.contains(node.id)) {
          node.position = _snapToGrid(node.position) + snappedDelta;
        }
      }
      _dragAccumulator -= snappedDelta;

      // Only recalculate wires connected to selected nodes during drag
      final affectedWireIds = circuit.wires
          .where(
            (w) =>
                selectedNodeIds.contains(w.fromNodeId) ||
                selectedNodeIds.contains(w.toNodeId),
          )
          .map((w) => w.id)
          .toList();

      _recalculatePaths(onlyWireIds: affectedWireIds);
      notifyListeners();
    }
  }

  List<CircuitNode> getSelectedNodes() {
    return circuit.nodes.where((n) => selectedNodeIds.contains(n.id)).toList();
  }

  bool isNodeSelected(String nodeId) => selectedNodeIds.contains(nodeId);

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
    temporaryWireEnd = _snapToGrid(point);
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
    _pathsDirty = true;
    _recalculatePaths();
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
              localPosition: const Offset(112, 32),
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
              localPosition: const Offset(112, 32),
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
              localPosition: const Offset(0, 16),
            ),
            Pin(
              id: 'b',
              nodeId: id,
              isInput: true,
              localPosition: const Offset(0, 48),
            ),
          ],
          outputPins: [
            Pin(
              id: 'out',
              nodeId: id,
              isInput: false,
              localPosition: const Offset(112, 32),
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
        localPosition: Offset(0, 16.0 + i * 16.0),
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
          localPosition: const Offset(112, 32),
        ),
      ],
    );
  }

  CircuitNode _createWaveform(Offset position) {
    final id = UniqueKey().toString();
    final inputPins = List.generate(4, (i) {
      return Pin(
        id: 'in_$i',
        nodeId: id,
        isInput: true,
        localPosition: Offset(0, 48.0 + i * 32.0),
      );
    });

    return WaveformNode(
      id: id,
      position: position,
      inputPins: inputPins,
      outputPins: const [],
    );
  }

  CircuitNode _createRGBLED(Offset position) {
    final id = UniqueKey().toString();
    final inputPins = [
      Pin(id: 'r', nodeId: id, isInput: true, localPosition: const Offset(0, 16)),
      Pin(id: 'g', nodeId: id, isInput: true, localPosition: const Offset(0, 48)),
      Pin(id: 'b', nodeId: id, isInput: true, localPosition: const Offset(0, 80)),
    ];
    return RGBLEDNode(
      id: id,
      position: position,
      inputPins: inputPins,
      outputPins: const [],
    );
  }

  CircuitNode _createLogicProbe(Offset position) {
    final id = UniqueKey().toString();
    return LogicProbeNode(
      id: id,
      position: position,
      inputPins: [
        Pin(id: 'in', nodeId: id, isInput: true, localPosition: const Offset(0, 32)),
      ],
      outputPins: const [],
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
            waypoints: List.from(w.waypoints),
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
    position = _snapToGrid(position);
    final id = UniqueKey().toString();

    // Create external pins based on internal Input/Output nodes
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

    circuit.nodes.add(node);
    undoStack.add(CircuitAction(addedNodes: [node]));
    redoStack.clear();

    LogicSimulator.simulate(circuit);
    _pathsDirty = true;
    _recalculatePaths();
    notifyListeners();
  }

  void startMarqueeSelection(Offset position) {
    _selectionStart = position;
    selectionRect = Rect.fromPoints(position, position);
    notifyListeners();
  }

  void updateMarqueeSelection(Offset position) {
    if (_selectionStart == null) return;
    selectionRect = Rect.fromPoints(_selectionStart!, position);

    // Dynamic selection while dragging
    selectedNodeIds.clear();
    final nodes = HitTesting.findNodesInRect(circuit, selectionRect!);
    for (final node in nodes) {
      selectedNodeIds.add(node.id);
    }

    notifyListeners();
  }

  void endMarqueeSelection() {
    selectionRect = null;
    _selectionStart = null;
    notifyListeners();
  }

  void loadDefinition(SubCircuitDefinition definition) {
    clear();
    // Use a map to track original IDs to new IDs if we were re-generating IDs,
    // but here we can just use the same IDs or clone them properly.
    // Since we are loading it as the MAIN circuit, we can use the original IDs.

    for (final node in definition.nodes) {
      circuit.nodes.add(node.clone(node.id));
    }

    for (final wire in definition.wires) {
      circuit.wires.add(
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

    _updateClockTimer();
    LogicSimulator.simulate(circuit);
    _pathsDirty = true;
    _recalculatePaths();
    notifyListeners();
  }

  void _recalculatePaths({List<String>? onlyWireIds}) {
    if (!_pathsDirty && onlyWireIds == null) return;

    final obstacles = circuit.nodes.map((n) => n.rect).toList();
    final allSegments = <WireSegment>{};

    for (int i = 0; i < circuit.wires.length; i++) {
      final wire = circuit.wires[i];
      final start = _getWireStart(wire);
      final end = _getWireEnd(wire);

      if (start == null || end == null) continue;

      if (wire.waypoints.isNotEmpty) {
        final points = [start, ...wire.waypoints, end];
        for (int j = 0; j < points.length - 1; j++) {
          _addSegments(allSegments, points[j], points[j + 1]);
        }
        continue;
      }

      final shouldRecalculate = onlyWireIds == null ||
          onlyWireIds.contains(wire.id) ||
          wire.cachedPath == null;

      if (shouldRecalculate) {
        final points = PathFinder.findPath(
          start: start,
          end: end,
          obstacles: obstacles,
          existingSegments: allSegments,
        );
        circuit.wires[i] = wire.copyWith(cachedPath: points);
      }

      final points = circuit.wires[i].cachedPath ?? [];
      for (int j = 0; j < points.length - 1; j++) {
        _addSegments(allSegments, points[j], points[j + 1]);
      }
    }
    if (onlyWireIds == null) {
      _pathsDirty = false;
    }
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

  Offset? _getWireStart(Wire wire) {
    final node = _findNode(wire.fromNodeId);
    if (node == null) return null;

    final pin =
        node.outputPins.where((p) => p.id == wire.fromPinId).firstOrNull;
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
}

class PinSelection {
  final CircuitNode node;
  final Pin pin;

  PinSelection({required this.node, required this.pin});
}
