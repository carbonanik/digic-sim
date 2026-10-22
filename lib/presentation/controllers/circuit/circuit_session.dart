import 'package:flutter/foundation.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/presentation/controllers/circuit_simulation_service.dart';
import 'package:digital_logic_sim_2/presentation/controllers/commands/command_history.dart';
import 'package:digital_logic_sim_2/presentation/controllers/create_node_factory.dart';
import 'package:digital_logic_sim_2/presentation/controllers/editor_state.dart';
import 'package:digital_logic_sim_2/presentation/controllers/grid.dart';
import 'package:digital_logic_sim_2/presentation/controllers/wire_routing_service.dart';
import 'dart:ui';

/// Owns one workspace's mutable simulation runtime and rendering resources.
/// Application UI snapshots are published separately through Riverpod.
class CircuitSession {
  final Circuit circuit = Circuit(nodes: [], wires: []);
  final EditorState editor = EditorState();
  final CommandHistory history = CommandHistory();
  final CreateNodeFactory nodeFactory;
  final Grid grid;
  final CircuitSimulationService simulation;
  final WireRoutingService routing = WireRoutingService();
  final ValueNotifier<int> circuitRepaint = ValueNotifier(0);
  final ValueNotifier<int> overlayRepaint = ValueNotifier(0);
  VoidCallback? onUiChanged;
  bool isClosed = false;
  bool snapToGridEnabled = true;
  bool pathsDirty = true;

  CircuitSession({
    required this.nodeFactory,
    required this.grid,
    required this.simulation,
  });

  void simulate() => simulation.simulate(circuit);

  void updateClockTimer() =>
      simulation.updateClockTimer(circuit: circuit, onTick: repaintCircuit);

  void recalculatePaths({List<String>? onlyWireIds, Offset? translationDelta}) {
    routing.recalculatePaths(
      circuit: circuit,
      selectedNodeIds: editor.selectedNodeIds,
      pathsDirty: pathsDirty,
      setPathsDirty: (dirty) => pathsDirty = dirty,
      onlyWireIds: onlyWireIds,
      translationDelta: translationDelta,
    );
  }

  void repaintCircuit() {
    if (isClosed) return;
    circuitRepaint.value++;
    overlayRepaint.value++;
  }

  void repaintOverlay() {
    if (!isClosed) overlayRepaint.value++;
  }

  void documentChanged() {
    repaintCircuit();
    publishUi();
  }

  void publishUi() {
    if (!isClosed) onUiChanged?.call();
  }

  void uiChanged() {
    repaintCircuit();
    publishUi();
  }

  void dispose() {
    if (isClosed) return;
    isClosed = true;
    onUiChanged = null;
    simulation.dispose();
    circuitRepaint.dispose();
    overlayRepaint.dispose();
  }
}
