import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/domain/entities/pin.dart';
import 'package:digital_logic_sim_2/domain/entities/pin_layout.dart';
import 'package:digital_logic_sim_2/domain/entities/wire.dart';
import 'package:digital_logic_sim_2/presentation/canvas/hit_test.dart';
import 'package:digital_logic_sim_2/presentation/providers/editor_dependencies.dart';
import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';
import 'circuit/circuit_document_actions.dart';
import 'circuit/circuit_session.dart';
import 'circuit/circuit_view_state.dart';
import 'circuit/custom_component_actions.dart';
import 'circuit/editor_interaction_controller.dart';
import 'circuit/node_movement_controller.dart';
import 'circuit/wire_interaction_controller.dart';
import 'circuit_simulation_service.dart';
import 'create_node_factory.dart';
import 'custom_component_manager.dart';
import 'grid.dart';

final circuitControllerProvider = NotifierProvider.autoDispose
    .family<CircuitController, CircuitViewState, String>(CircuitController.new);

/// Adapts workspace actions to immutable Riverpod UI state. Editing algorithms,
/// gesture state, persistence, and simulation resource ownership are delegated.
class CircuitController extends Notifier<CircuitViewState> {
  final String workspaceId;
  CircuitController(this.workspaceId);

  late CircuitSession _session;
  late CircuitDocumentActions _document;
  late EditorInteractionController _interaction;
  late WireInteractionController _wires;
  late NodeMovementController _movement;
  late CustomComponentActions _components;
  late CustomComponentManager _catalog;
  late VoidCallback _releaseWorkspace;

  @override
  CircuitViewState build() {
    _catalog = ref.watch(customComponentManagerProvider);
    _session = CircuitSession(
      nodeFactory: CreateNodeFactory(),
      grid: Grid(),
      simulation: CircuitSimulationService(
        simulator: ref.watch(circuitSimulatorProvider),
      ),
    );
    _document = CircuitDocumentActions(_session);
    _interaction = EditorInteractionController(_session);
    _wires = WireInteractionController(_session);
    _movement = NodeMovementController(_session);
    _components = CustomComponentActions(_session, _catalog);
    // A workspace is a document, so it survives temporarily having no widgets.
    final lifetime = ref.keepAlive();
    _releaseWorkspace = lifetime.close;
    _session.onUiChanged = () {
      if (ref.mounted && !_session.isClosed) {
        state = CircuitViewState.fromSession(_session);
      }
    };
    ref.onDispose(_session.dispose);
    return CircuitViewState.fromSession(_session);
  }

  /// Stop input/timers immediately; Riverpod releases the provider after its
  /// remaining widgets detach. Late pointer and dialog callbacks become no-ops.
  void close() {
    _session.dispose();
    _releaseWorkspace();
  }

  void _run(VoidCallback action) {
    if (!_session.isClosed && ref.mounted) action();
  }

  // Runtime access for hit testing and painting. Edits go through actions;
  // application UI observes the immutable provider state.
  Circuit get circuit => _session.circuit;
  Grid get grid => _session.grid;
  EditorTool get selectedTool => _session.editor.selectedTool;
  SubCircuitDefinition? get selectedCustomComponent =>
      _session.editor.selectedCustomComponent;
  Set<String> get selectedNodeIds =>
      Set.unmodifiable(_session.editor.selectedNodeIds);
  String? get selectedWireId => _session.editor.selectedWireId;
  Rect? get selectionRect => _session.editor.selectionRect;
  PinSelection? get wireStart => _session.editor.wireStart;
  PinHit? get hoveredPin => _session.editor.hoveredPin;
  String? get hoveredNodeId => _session.editor.hoveredNodeId;
  Offset? get mousePosition => _session.editor.mousePosition;
  Offset? get temporaryWireEnd => _session.editor.temporaryWireEnd;
  WireHit? get draggedWireHit => _session.editor.draggedWireHit;
  bool get snapToGridEnabled => _session.snapToGridEnabled;
  bool get canUndo => _session.history.canUndo;
  bool get canRedo => _session.history.canRedo;
  bool get isClosed => _session.isClosed;
  int get circuitRepaintCounter => _session.circuitRepaint.value;
  int get overlayRepaintCounter => _session.overlayRepaint.value;
  ValueListenable<int> get circuitRepaint => _session.circuitRepaint;
  ValueListenable<int> get overlayRepaint => _session.overlayRepaint;
  double get simulationFps => _session.simulation.simulationFps;
  double get averageSimulationMs => _session.simulation.averageSimulationMs;
  int get lastSimulationSteps => _session.simulation.lastSimulationSteps;
  bool get lastSimulationStabilized =>
      _session.simulation.lastSimulationStabilized;
  List<SubCircuitDefinition> get customDefinitions =>
      _catalog.customDefinitions;

  void toggleGridSnapping() => _run(_interaction.toggleGridSnapping);
  void selectTool(EditorTool tool) => _run(() => _interaction.selectTool(tool));
  void selectCustomComponent(SubCircuitDefinition definition) =>
      _run(() => _interaction.selectCustomComponent(definition));
  void selectNode(String? nodeId, {bool multi = false}) =>
      _run(() => _interaction.selectNode(nodeId, multi: multi));
  void selectWire(String? wireId) =>
      _run(() => _interaction.selectWire(wireId));
  List<CircuitNode> getSelectedNodes() => _interaction.getSelectedNodes();
  bool isNodeSelected(String nodeId) => _interaction.isNodeSelected(nodeId);
  void updateHoverState({
    required Offset? position,
    required PinHit? pinHit,
    required String? nodeId,
  }) => _run(
    () => _interaction.updateHoverState(
      position: position,
      pinHit: pinHit,
      nodeId: nodeId,
    ),
  );
  void startMarqueeSelection(Offset position) =>
      _run(() => _interaction.startMarqueeSelection(position));
  void updateMarqueeSelection(Offset position) =>
      _run(() => _interaction.updateMarqueeSelection(position));
  void endMarqueeSelection() => _run(_interaction.endMarqueeSelection);

  void clear() => _run(_document.clear);
  void addGateFromTool(Offset position) => _run(() {
    final definition = selectedCustomComponent;
    if (selectedTool == EditorTool.custom && definition != null) {
      _components.addCustomComponent(definition, position);
    } else {
      _document.addGateFromTool(position);
    }
  });
  void removeNode(CircuitNode node) => _run(() => _document.removeNode(node));
  void removeWire(Wire wire) => _run(() => _document.removeWire(wire));
  void deleteSelected() => _run(_document.deleteSelected);
  void undo() => _run(_document.undo);
  void redo() => _run(_document.redo);
  void handleNodeAction(String nodeId, Offset localPosition) =>
      _run(() => _document.handleNodeAction(nodeId, localPosition));
  void updateNodeLabel(String nodeId, String label) =>
      _run(() => _document.updateNodeLabel(nodeId, label));
  void updateNodeLabels(Map<String, String> labels) =>
      _run(() => _document.updateNodeLabels(labels));
  void duplicateSelected() => _run(_document.duplicateSelected);
  void duplicateNode(CircuitNode node) =>
      _run(() => _document.duplicateNode(node));
  void loadDefinition(SubCircuitDefinition definition) =>
      _run(() => _document.loadDefinition(definition));
  void setClockFrequency(String nodeId, double frequency) =>
      _run(() => _document.setClockFrequency(nodeId, frequency));

  void startWire(CircuitNode node, Pin pin) =>
      _run(() => _wires.startWire(node, pin));
  void updateTemporaryWire(Offset point) =>
      _run(() => _wires.updateTemporaryWire(point));
  void finishWire(CircuitNode node, Pin pin) =>
      _run(() => _wires.finishWire(node, pin));
  void cancelWire() => _run(_wires.cancelWire);
  void startWireDrag(WireHit hit, Offset mousePos) =>
      _run(() => _wires.startWireDrag(hit, mousePos));
  void updateWireDrag(Offset mousePos) =>
      _run(() => _wires.updateWireDrag(mousePos));
  void endWireDrag() => _run(_wires.endWireDrag);
  void resetWirePath(String wireId) => _run(() => _wires.resetWirePath(wireId));
  void resetDragAccumulator() => _run(_movement.resetDragAccumulator);
  void moveSelectedNodes(Offset delta) =>
      _run(() => _movement.moveSelectedNodes(delta));
  void endNodeMove() => _run(_movement.endNodeMove);

  String exportIC(SubCircuitDefinition definition) =>
      _components.exportIC(definition);
  void importIC(String json) => _run(() => _components.importIC(json));
  void removeCustomDefinition(SubCircuitDefinition definition) =>
      _run(() => _components.removeCustomDefinition(definition));
  void addCustomComponent(SubCircuitDefinition definition, Offset position) =>
      _run(() => _components.addCustomComponent(definition, position));
  void applyPinLayout(
    SubCircuitDefinition definition,
    Map<String, PinPlacement> placements,
  ) => _run(() => _components.applyPinLayout(definition, placements));
  void saveCurrentAsComponent({
    required String name,
    required Color color,
    required List<String> inputLabels,
    required List<String> outputLabels,
    Map<String, PinPlacement>? pinPlacements,
  }) => _run(
    () => _components.saveCurrentAsComponent(
      name: name,
      color: color,
      inputLabels: inputLabels,
      outputLabels: outputLabels,
      pinPlacements: pinPlacements,
    ),
  );
}
