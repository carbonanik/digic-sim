import 'package:flutter/material.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/presentation/canvas/hit_test.dart';
import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';

/// Encapsulates all editor canvas, selection, tool, and hover state.
class EditorState {
  EditorTool selectedTool;
  SubCircuitDefinition? selectedCustomComponent;

  Set<String> selectedNodeIds;
  String? selectedWireId;

  Rect? selectionRect;
  Offset? selectionStart;

  PinSelection? wireStart;
  PinHit? hoveredPin;
  String? hoveredNodeId;

  Offset? mousePosition;
  Offset? temporaryWireEnd;

  WireHit? draggedWireHit;
  List<Offset>? initialWaypoints;

  EditorState({
    this.selectedTool = EditorTool.select,
    this.selectedCustomComponent,
    Set<String>? selectedNodeIds,
    this.selectedWireId,
    this.selectionRect,
    this.selectionStart,
    this.wireStart,
    this.hoveredPin,
    this.hoveredNodeId,
    this.mousePosition,
    this.temporaryWireEnd,
    this.draggedWireHit,
    this.initialWaypoints,
  }) : selectedNodeIds = selectedNodeIds ?? {};

  void clearSelection() {
    selectedNodeIds.clear();
    selectedWireId = null;
    selectionRect = null;
    selectionStart = null;
  }

  void clearHover() {
    hoveredPin = null;
    hoveredNodeId = null;
  }

  void clearWireInteraction() {
    wireStart = null;
    temporaryWireEnd = null;
    draggedWireHit = null;
    initialWaypoints = null;
  }

  void reset() {
    selectedTool = EditorTool.select;
    selectedCustomComponent = null;
    clearSelection();
    clearHover();
    clearWireInteraction();
    mousePosition = null;
  }
}
