import 'package:flutter/foundation.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';
import 'circuit_session.dart';

/// Immutable application state. Pin signals and pointer positions stay in the
/// runtime so simulation ticks do not rebuild toolbars or the workspace tree.
@immutable
class CircuitViewState {
  final EditorTool selectedTool;
  final SubCircuitDefinition? selectedCustomComponent;
  final Set<String> selectedNodeIds;
  final String? selectedWireId;
  final bool snapToGridEnabled;
  final bool canUndo;
  final bool canRedo;
  final int nodeCount;
  final int wireCount;

  CircuitViewState.fromSession(CircuitSession session)
    : selectedTool = session.editor.selectedTool,
      selectedCustomComponent = session.editor.selectedCustomComponent,
      selectedNodeIds = Set.unmodifiable(session.editor.selectedNodeIds),
      selectedWireId = session.editor.selectedWireId,
      snapToGridEnabled = session.snapToGridEnabled,
      canUndo = session.history.canUndo,
      canRedo = session.history.canRedo,
      nodeCount = session.circuit.nodes.length,
      wireCount = session.circuit.wires.length;
}
