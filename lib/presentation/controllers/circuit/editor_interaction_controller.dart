import 'package:digital_logic_sim_2/domain/entities/circuit_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/presentation/canvas/hit_test.dart';
import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';
import 'package:flutter/material.dart';

import 'circuit_session.dart';

class EditorInteractionController {
  final CircuitSession session;

  EditorInteractionController(this.session);

  void toggleGridSnapping() {
    session.snapToGridEnabled = !session.snapToGridEnabled;
    session.uiChanged();
  }

  void selectTool(EditorTool tool) {
    session.editor.selectedTool = tool;
    if (tool != EditorTool.custom) {
      session.editor.selectedCustomComponent = null;
    }
    session.editor.selectedNodeIds.clear();
    session.editor.selectedWireId = null;
    session.editor.selectionRect = null;
    session.editor.wireStart = null;
    session.editor.hoveredPin = null;
    session.editor.temporaryWireEnd = null;
    session.uiChanged();
  }

  void selectCustomComponent(SubCircuitDefinition definition) {
    session.editor.selectedTool = EditorTool.custom;
    session.editor.selectedCustomComponent = definition;
    session.editor.selectedNodeIds.clear();
    session.editor.selectedWireId = null;
    session.editor.selectionRect = null;
    session.editor.wireStart = null;
    session.editor.hoveredPin = null;
    session.editor.temporaryWireEnd = null;
    session.uiChanged();
  }

  void updateHoverState({
    required Offset? position,
    required PinHit? pinHit,
    required String? nodeId,
  }) {
    // Flutter can dispatch a final hover or exit event before the closed
    // workspace's canvas is removed in the next frame.
    if (session.isClosed) return;

    final snapped = position != null ? session.grid.snap(position) : null;

    final changed =
        session.editor.mousePosition != snapped ||
        session.editor.hoveredPin?.node.id != pinHit?.node.id ||
        session.editor.hoveredPin?.pin.id != pinHit?.pin.id ||
        session.editor.hoveredNodeId != nodeId;

    if (!changed) return;

    session.editor.mousePosition = snapped;
    session.editor.hoveredPin = pinHit;
    session.editor.hoveredNodeId = nodeId;

    session.repaintOverlay();
  }

  void selectNode(String? nodeId, {bool multi = false}) {
    if (nodeId == null) {
      session.editor.selectedNodeIds.clear();
    } else {
      if (multi) {
        if (session.editor.selectedNodeIds.contains(nodeId)) {
          session.editor.selectedNodeIds.remove(nodeId);
        } else {
          session.editor.selectedNodeIds.add(nodeId);
        }
      } else {
        if (!session.editor.selectedNodeIds.contains(nodeId)) {
          session.editor.selectedNodeIds = {nodeId};
        }
      }
    }
    session.editor.selectedWireId = null;
    session.uiChanged();
  }

  void selectWire(String? wireId) {
    session.editor.selectedWireId = wireId;
    session.editor.selectedNodeIds.clear();
    session.uiChanged();
  }

  List<CircuitNode> getSelectedNodes() {
    return session.circuit.nodes
        .where((n) => session.editor.selectedNodeIds.contains(n.id))
        .toList();
  }

  bool isNodeSelected(String nodeId) =>
      session.editor.selectedNodeIds.contains(nodeId);

  void startMarqueeSelection(Offset position) {
    session.editor.selectionStart = position;
    session.editor.selectionRect = Rect.fromPoints(position, position);
    session.repaintOverlay();
  }

  void updateMarqueeSelection(Offset position) {
    if (session.editor.selectionStart == null) return;
    session.editor.selectionRect = Rect.fromPoints(
      session.editor.selectionStart!,
      position,
    );

    session.editor.selectedNodeIds.clear();
    final nodes = HitTesting.findNodesInRect(
      session.circuit,
      session.editor.selectionRect!,
    );
    for (final node in nodes) {
      session.editor.selectedNodeIds.add(node.id);
    }

    session.uiChanged();
  }

  void endMarqueeSelection() {
    session.editor.selectionRect = null;
    session.editor.selectionStart = null;
    session.uiChanged();
  }
}
