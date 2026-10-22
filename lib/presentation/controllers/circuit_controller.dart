import 'package:digital_logic_sim_2/core/utils/extensions.dart';
import 'package:digital_logic_sim_2/core/utils/pathfinder.dart';
import 'package:digital_logic_sim_2/domain/entities/pin_layout.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/io_nodes.dart';
import 'package:digital_logic_sim_2/domain/entities/pin.dart';
import 'package:digital_logic_sim_2/domain/entities/wire.dart';
import 'package:digital_logic_sim_2/presentation/canvas/hit_test.dart';
import 'package:digital_logic_sim_2/presentation/controllers/commands/circuit_command.dart';
import 'package:digital_logic_sim_2/presentation/controllers/commands/command_history.dart';
import 'package:digital_logic_sim_2/presentation/controllers/create_node_factory.dart';
import 'package:digital_logic_sim_2/presentation/controllers/custom_component_manager.dart';
import 'package:digital_logic_sim_2/presentation/controllers/grid.dart';
import 'package:digital_logic_sim_2/presentation/controllers/circuit_simulation_service.dart';
import 'package:digital_logic_sim_2/presentation/controllers/wire_routing_service.dart';
import 'package:digital_logic_sim_2/presentation/controllers/editor_state.dart';
import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';
import 'package:flutter/material.dart';

class CircuitController extends ChangeNotifier {
  final CreateNodeFactory createNodeFactory;
  final Grid grid;
  final EditorState editor;
  final CircuitSimulationService _simulationService;
  final CustomComponentManager _customComponentManager;
  final WireRoutingService _wireRoutingService;

  CircuitController({
    required this.createNodeFactory,
    required this.grid,
    required CircuitSimulationService simulationService,
    required CustomComponentManager customComponentManager,
    WireRoutingService? wireRoutingService,
    EditorState? editor,
  }) : editor = editor ?? EditorState(),
       _simulationService = simulationService,
       _customComponentManager = customComponentManager,
       _wireRoutingService = wireRoutingService ?? WireRoutingService();

  @override
  void dispose() {
    _simulationService.dispose();
    super.dispose();
  }

  // Simulation Getters
  double get simulationFps => _simulationService.simulationFps;
  double get averageSimulationMs => _simulationService.averageSimulationMs;
  int get lastSimulationSteps => _simulationService.lastSimulationSteps;
  bool get lastSimulationStabilized =>
      _simulationService.lastSimulationStabilized;

  // Custom Definition Delegation
  List<SubCircuitDefinition> get customDefinitions =>
      _customComponentManager.customDefinitions;

  String exportIC(SubCircuitDefinition definition) {
    return _customComponentManager.exportIC(definition);
  }

  void importIC(String json) {
    final definition = _customComponentManager.importIC(json);
    if (definition != null) {
      notifyListeners();
    }
  }

  void removeCustomDefinition(SubCircuitDefinition definition) {
    _customComponentManager.removeCustomDefinition(definition);
    notifyListeners();
  }

  // Circuit State
  Circuit circuit = Circuit(nodes: [], wires: []);

  // EditorState Delegation Getters & Setters
  EditorTool get selectedTool => editor.selectedTool;
  set selectedTool(EditorTool tool) => editor.selectedTool = tool;

  SubCircuitDefinition? get selectedCustomComponent =>
      editor.selectedCustomComponent;
  set selectedCustomComponent(SubCircuitDefinition? component) =>
      editor.selectedCustomComponent = component;

  Set<String> get selectedNodeIds => editor.selectedNodeIds;
  set selectedNodeIds(Set<String> ids) => editor.selectedNodeIds = ids;

  String? get selectedWireId => editor.selectedWireId;
  set selectedWireId(String? id) => editor.selectedWireId = id;

  Rect? get selectionRect => editor.selectionRect;
  set selectionRect(Rect? rect) => editor.selectionRect = rect;

  Offset? get _selectionStart => editor.selectionStart;
  set _selectionStart(Offset? start) => editor.selectionStart = start;

  PinSelection? get wireStart => editor.wireStart;
  set wireStart(PinSelection? selection) => editor.wireStart = selection;

  PinHit? get hoveredPin => editor.hoveredPin;
  set hoveredPin(PinHit? hit) => editor.hoveredPin = hit;

  String? get hoveredNodeId => editor.hoveredNodeId;
  set hoveredNodeId(String? id) => editor.hoveredNodeId = id;

  Offset? get mousePosition => editor.mousePosition;
  set mousePosition(Offset? pos) => editor.mousePosition = pos;

  Offset? get temporaryWireEnd => editor.temporaryWireEnd;
  set temporaryWireEnd(Offset? end) => editor.temporaryWireEnd = end;

  WireHit? get draggedWireHit => editor.draggedWireHit;
  set draggedWireHit(WireHit? hit) => editor.draggedWireHit = hit;

  List<Offset>? get _initialWaypoints => editor.initialWaypoints;
  set _initialWaypoints(List<Offset>? waypoints) =>
      editor.initialWaypoints = waypoints;

  final CommandHistory commandHistory = CommandHistory();
  bool get canUndo => commandHistory.canUndo;
  bool get canRedo => commandHistory.canRedo;

  int circuitRepaintCounter = 0;
  int overlayRepaintCounter = 0;

  Offset _dragAccumulator = Offset.zero;
  bool snapToGridEnabled = true;

  bool _pathsDirty = true;

  void toggleGridSnapping() {
    snapToGridEnabled = !snapToGridEnabled;
    notifyListeners();
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

  void updateHoverState({
    required Offset? position,
    required PinHit? pinHit,
    required String? nodeId,
  }) {
    final snapped = position != null ? grid.snap(position) : null;

    final changed =
        mousePosition != snapped ||
        hoveredPin?.node.id != pinHit?.node.id ||
        hoveredPin?.pin.id != pinHit?.pin.id ||
        hoveredNodeId != nodeId;

    if (!changed) return;

    mousePosition = snapped;
    hoveredPin = pinHit;
    hoveredNodeId = nodeId;

    notifyOverlayChanged();
  }

  void notifyCircuitChanged() {
    circuitRepaintCounter++;
    overlayRepaintCounter++;
    super.notifyListeners();
  }

  void notifyOverlayChanged() {
    overlayRepaintCounter++;
    super.notifyListeners();
  }

  void _simulateCircuit() {
    _simulationService.simulate(circuit);
  }

  void _updateClockTimer() {
    _simulationService.updateClockTimer(
      circuit: circuit,
      onTick: notifyCircuitChanged,
    );
  }

  void clear() {
    circuit.nodes.clear();
    circuit.wires.clear();
    editor.reset();
    _updateClockTimer();
    _pathsDirty = true;
    commandHistory.clear();
    notifyCircuitChanged();
  }

  void startWireDrag(WireHit hit, Offset mousePos) {
    draggedWireHit = hit;

    final wire = hit.wire;
    if (wire.waypoints.isEmpty) {
      final start = _wireRoutingService.getWireStart(circuit, wire);
      final end = _wireRoutingService.getWireEnd(circuit, wire);
      if (start != null && end != null) {
        final points = PathFinder.findPath(
          start: start,
          end: end,
          obstacles: circuit.nodes.toObstacles(),
        );
        _initialWaypoints = points.length <= 2
            ? []
            : points.sublist(1, points.length - 1);
      } else {
        _initialWaypoints = [];
      }
    } else {
      _initialWaypoints = List.from(wire.waypoints);
    }
    notifyListeners();
  }

  void updateWireDrag(Offset mousePos) {
    if (draggedWireHit == null || _initialWaypoints == null) return;

    final snappedMouse = grid.snap(mousePos);
    final wire = draggedWireHit!.wire;
    final segmentIndex = draggedWireHit!.segmentIndex;

    final start = _wireRoutingService.getWireStart(circuit, wire);
    final end = _wireRoutingService.getWireEnd(circuit, wire);

    if (start == null || end == null) return;

    final points = [start, ..._initialWaypoints!, end];

    if (segmentIndex < 0 || segmentIndex >= points.length - 1) return;

    final p1 = points[segmentIndex];
    final p2 = points[segmentIndex + 1];

    final isHorizontal = (p1.dy - p2.dy).abs() < 0.1;
    final isVertical = (p1.dx - p2.dx).abs() < 0.1;

    if (!isHorizontal && !isVertical) return;

    final List<Offset> newPoints;

    if (isHorizontal) {
      final newY = snappedMouse.dy;
      newPoints = [
        ...points.take(segmentIndex + 1),
        Offset(p1.dx, newY),
        Offset(p2.dx, newY),
        ...points.skip(segmentIndex + 1),
      ];
    } else {
      final newX = snappedMouse.dx;
      newPoints = [
        ...points.take(segmentIndex + 1),
        Offset(newX, p1.dy),
        Offset(newX, p2.dy),
        ...points.skip(segmentIndex + 1),
      ];
    }

    final simplifiedPoints = _wireRoutingService.simplifyOrthogonalPoints(
      newPoints,
    );

    final newWaypoints = simplifiedPoints.length <= 2
        ? <Offset>[]
        : simplifiedPoints.sublist(1, simplifiedPoints.length - 1);

    final wireIndex = circuit.wires.indexWhere((w) => w.id == wire.id);

    if (wireIndex != -1) {
      circuit.wires[wireIndex] = wire.copyWith(waypoints: newWaypoints);
      _pathsDirty = true;
      _recalculatePaths();
      notifyCircuitChanged();
    }
  }

  void endWireDrag() {
    if (draggedWireHit != null) {
      if (_initialWaypoints != null) {
        final currentWaypoints = draggedWireHit!.wire.waypoints;
        commandHistory.push(
          UpdateWireWaypointsCommand(
            wireId: draggedWireHit!.wire.id,
            oldWaypoints: _initialWaypoints!,
            newWaypoints: List.from(currentWaypoints),
          ),
        );
      }
      draggedWireHit = null;
      _initialWaypoints = null;
      _pathsDirty = true;
      _recalculatePaths();
      notifyCircuitChanged();
    }
  }

  void endNodeMove() {
    _wireRoutingService.clearDragWaypoints();
    if (selectedNodeIds.isNotEmpty) {
      _pathsDirty = true;
      _recalculatePaths();
      notifyCircuitChanged();
    }
  }

  void addGateFromTool(Offset position) {
    position = grid.snap(position);

    if (selectedTool == EditorTool.custom && selectedCustomComponent != null) {
      addCustomComponent(selectedCustomComponent!, position);
      return;
    }

    final node = createNodeFactory.create(selectedTool, position);
    circuit.nodes.add(node);

    _updateClockTimer();

    commandHistory.push(AddNodesCommand([node]));

    _simulateCircuit();
    _pathsDirty = true;
    _recalculatePaths();
    notifyCircuitChanged();
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

    commandHistory.push(
      RemoveNodesAndWiresCommand(nodes: [node], wires: removedWires),
    );

    _simulateCircuit();
    _pathsDirty = true;
    _recalculatePaths();
    notifyCircuitChanged();
  }

  void removeWire(Wire wire) {
    circuit.wires.remove(wire);

    if (selectedWireId == wire.id) {
      selectedWireId = null;
    }

    commandHistory.push(RemoveWireCommand(wire));

    _simulateCircuit();
    _pathsDirty = true;
    _recalculatePaths();
    notifyCircuitChanged();
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

      commandHistory.push(
        RemoveNodesAndWiresCommand(nodes: removedNodes, wires: removedWires),
      );

      _simulateCircuit();
      _pathsDirty = true;
      _recalculatePaths();
      notifyCircuitChanged();
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
    if (commandHistory.undo(circuit)) {
      _updateClockTimer();
      _simulateCircuit();
      _pathsDirty = true;
      _recalculatePaths();
      notifyCircuitChanged();
    }
  }

  void redo() {
    if (commandHistory.redo(circuit)) {
      _updateClockTimer();
      _simulateCircuit();
      _pathsDirty = true;
      _recalculatePaths();
      notifyCircuitChanged();
    }
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
    notifyCircuitChanged();
  }

  void selectWire(String? wireId) {
    selectedWireId = wireId;
    selectedNodeIds.clear();
    notifyCircuitChanged();
  }

  void moveSelectedNodes(Offset delta) {
    if (selectedNodeIds.isEmpty) return;

    if (!snapToGridEnabled) {
      for (final node in circuit.nodes) {
        if (selectedNodeIds.contains(node.id)) {
          node.position += delta;
        }
      }
      final affectedWireIds = circuit.wires
          .where(
            (w) =>
                selectedNodeIds.contains(w.fromNodeId) ||
                selectedNodeIds.contains(w.toNodeId),
          )
          .map((w) => w.id)
          .toList();

      _pathsDirty = true;
      _recalculatePaths(onlyWireIds: affectedWireIds, translationDelta: delta);
      notifyCircuitChanged();
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
          node.position = grid.snap(node.position) + snappedDelta;
        }
      }
      _dragAccumulator -= snappedDelta;

      final affectedWireIds = circuit.wires
          .where(
            (w) =>
                selectedNodeIds.contains(w.fromNodeId) ||
                selectedNodeIds.contains(w.toNodeId),
          )
          .map((w) => w.id)
          .toList();

      _recalculatePaths(
        onlyWireIds: affectedWireIds,
        translationDelta: snappedDelta,
      );
      notifyCircuitChanged();
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
      _simulateCircuit();
      notifyCircuitChanged();
    }
  }

  void updateNodeLabel(String nodeId, String label) {
    final node = circuit.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return;

    if (node is InputNode) {
      node.label = label;
    } else if (node is OutputNode) {
      node.label = label;
    }

    notifyCircuitChanged();
  }

  void updateNodeLabels(Map<String, String> labels) {
    bool changed = false;
    for (final node in circuit.nodes) {
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
    if (changed) notifyCircuitChanged();
  }

  void duplicateSelected() {
    if (selectedNodeIds.isEmpty) return;

    final nodesToDuplicate = circuit.nodes
        .where((n) => selectedNodeIds.contains(n.id))
        .toList();

    final newNodes = <CircuitNode>[];
    for (final node in nodesToDuplicate) {
      final newNode = node.clone(UniqueKey().toString());
      newNode.position = node.position + const Offset(32, 32);
      circuit.nodes.add(newNode);
      newNodes.add(newNode);
    }

    selectedNodeIds = newNodes.map((n) => n.id).toSet();
    selectedWireId = null;

    commandHistory.push(AddNodesCommand(newNodes));

    _pathsDirty = true;
    _recalculatePaths();
    notifyCircuitChanged();
  }

  void startWire(CircuitNode node, Pin pin) {
    if (pin.isInput) return;

    wireStart = PinSelection(node: node, pin: pin);
    temporaryWireEnd = node.position + pin.localPosition;
    notifyOverlayChanged();
  }

  void updateTemporaryWire(Offset point) {
    temporaryWireEnd = grid.snap(point);
    notifyOverlayChanged();
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

    commandHistory.push(AddWiresCommand([wire]));

    wireStart = null;
    temporaryWireEnd = null;

    _simulateCircuit();
    _pathsDirty = true;
    _recalculatePaths();
    notifyCircuitChanged();
  }

  void cancelWire() {
    wireStart = null;
    temporaryWireEnd = null;
    notifyOverlayChanged();
  }

  void saveCurrentAsComponent({
    required String name,
    required Color color,
    required List<String> inputLabels,
    required List<String> outputLabels,
    Map<String, PinPlacement>? pinPlacements,
  }) {
    if (circuit.nodes.isEmpty) return;

    int inIdx = 0;
    int outIdx = 0;
    final clonedNodes = circuit.nodes.map((n) {
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
    notifyListeners();
  }

  void addCustomComponent(SubCircuitDefinition definition, Offset position) {
    position = grid.snap(position);
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

    circuit.nodes.add(node);
    commandHistory.push(AddNodesCommand([node]));

    _simulateCircuit();
    _pathsDirty = true;
    _recalculatePaths();
    notifyCircuitChanged();
  }

  void applyPinLayout(
    SubCircuitDefinition definition,
    Map<String, PinPlacement> newPlacements,
  ) {
    _customComponentManager.updatePinLayout(definition, newPlacements);

    for (final node in circuit.nodes.whereType<ComposedNode>()) {
      if (node.definition == definition) {
        node.refreshLayout();
      }
    }

    _pathsDirty = true;
    _recalculatePaths();
    notifyCircuitChanged();
  }

  void startMarqueeSelection(Offset position) {
    _selectionStart = position;
    selectionRect = Rect.fromPoints(position, position);
    notifyOverlayChanged();
  }

  void updateMarqueeSelection(Offset position) {
    if (_selectionStart == null) return;
    selectionRect = Rect.fromPoints(_selectionStart!, position);

    selectedNodeIds.clear();
    final nodes = HitTesting.findNodesInRect(circuit, selectionRect!);
    for (final node in nodes) {
      selectedNodeIds.add(node.id);
    }

    notifyOverlayChanged();
    notifyCircuitChanged();
  }

  void endMarqueeSelection() {
    selectionRect = null;
    _selectionStart = null;
    notifyOverlayChanged();
    notifyCircuitChanged();
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
      circuit.nodes.add(newNode);
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
    _simulateCircuit();
    _pathsDirty = true;
    _recalculatePaths();
    notifyCircuitChanged();
  }

  void _recalculatePaths({
    List<String>? onlyWireIds,
    Offset? translationDelta,
  }) {
    _wireRoutingService.recalculatePaths(
      circuit: circuit,
      selectedNodeIds: selectedNodeIds,
      pathsDirty: _pathsDirty,
      setPathsDirty: (dirty) => _pathsDirty = dirty,
      onlyWireIds: onlyWireIds,
      translationDelta: translationDelta,
    );
  }
}
